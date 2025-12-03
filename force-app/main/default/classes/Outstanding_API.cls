@RestResource(urlMapping = '/CreateOutstanding')
global class Outstanding_API {
    @HttpPost
    global static void doPost() {

        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        String jSONRequestBody = request.requestBody.toString().replace('\n', '');
        jSONRequestBody = jSONRequestBody.replace('/', '&sol;');

        // ------------------- API LOG to track the request -------------------
        API_Log__c api_log = new API_Log__c();
        api_log.Log_Name__c = 'CreateOutstandingAPI';
        // api_log.Request__c = jSONRequestBody;
        api_log.Request_Time__c = DateTime.now();

        List<JSON2ApexSaveWebToLead> jsonObj = JSON2ApexSaveWebToLead.parse(jSONRequestBody);
        System.debug('======----->jsonObj' + jsonObj);

        List<Outstanding__c> outstandingToInsert = new List<Outstanding__c>();
        List<API_Log__c> apilogToInsert = new List<API_Log__c>();

        try {

            Set<String> customerNumberSet = new Set<String>();
            Set<String> itemNumberSet = new Set<String>();
            Set<String> invoiceNumberSet = new Set<String>();

            for (JSON2ApexSaveWebToLead obj : jsonObj) {
                customerNumberSet.add(obj.BILL_TO_CUSTOMER_NUM);
                // itemNumberSet.add(obj.Item_Number);
                invoiceNumberSet.add(obj.TRX_NUMBER);
            }

            // Get Account data
            List<Account> accList = [
                SELECT Id, Name, Oracle_Customer_No__c
                FROM Account
                WHERE Oracle_Customer_No__c != null
                AND Oracle_Customer_No__c IN :customerNumberSet
            ];

            Map<String, String> custNumAccIdMap = new Map<String, String>();

            for (Account acc : accList) {
                custNumAccIdMap.put(acc.Oracle_Customer_No__c, acc.Id);
            }

            // Get Product data
            // List<Product2> productList = [
            //     SELECT Id, Name, ProductCode
            //     FROM Product2
            //     WHERE ProductCode != null
            //     AND ProductCode IN :itemNumberSet
            // ];

            Map<String, String> prodCodeProdIdMap = new Map<String, String>();

            // for (Product2 p : productList) {
            //     prodCodeProdIdMap.put(p.ProductCode, p.Id);
            // }

            // Get Invoice Data
            List<Invoice__c> invoiceList = [
                SELECT Id, Name,Trx_Number__c
                FROM Invoice__c
                WHERE Trx_Number__c IN :invoiceNumberSet
            ];

            Map<String, String> invoiceNoIdMap = new Map<String, String>();

            for (Invoice__c inv : invoiceList) {
                invoiceNoIdMap.put(inv.Trx_Number__c, inv.Id);
            }

            // Insert Outstandings
            for (JSON2ApexSaveWebToLead obj : jsonObj) {

                Outstanding__c out = new Outstanding__c();
                
                out.Cr_Terms__c = checkNullDecimal(obj.Cr_Terms);
                out.TRX_NUMBER__c = obj.TRX_NUMBER;
                if (invoiceNoIdMap.containsKey(obj.TRX_NUMBER)) { // Lookup by using TRX Number
                    out.Invoice_No__c = invoiceNoIdMap.get(obj.TRX_NUMBER);
                }
                out.Location__c = obj.LOCATION;
                // out.Tax_Invoice_Number__c = obj.Tax_Invoice_Number;
                out.CTT_CLASS__c = obj.CTT_CLASS;
                out.CUSTOMER_ID__c = obj.CUSTOMER_ID;
                out.BILL_TO_CUSTOMER_NUM__c = obj.BILL_TO_CUSTOMER_NUM;
                // For Account lookup , use BILL_TO_CUSTOMER_NUM
                if (custNumAccIdMap.containsKey(obj.BILL_TO_CUSTOMER_NUM)) { 
                    out.Customer_Name__c = custNumAccIdMap.get(obj.BILL_TO_CUSTOMER_NUM);
                }
                out.BILL_TO_CUSTOMER_NAME__c = obj.BILL_TO_CUSTOMER_NAME;
                out.LINE_TYPE__c = obj.LINE_TYPE;
                out.ACCOUNT_CLASS__c = obj.ACCOUNT_CLASS;
                out.CUSTOMER_TRX_ID__c = obj.CUSTOMER_TRX_ID;
                out.TRX_DATE__c = Date.valueOf(obj.TRX_DATE);
                out.TERM_DUE_DATE__c = Date.valueOf(obj.TERM_DUE_DATE);
                out.INVOICE_CURRENCY_CODE__c = obj.INVOICE_CURRENCY_CODE;
                out.BS_BATCH_SOURCE_NAME__c = obj.BS_BATCH_SOURCE_NAME;
                out.DESCRIPTION__c = obj.DESCRIPTION;
                out.ACCTD_AMOUNT__c = checkNullDecimal(obj.ACCTD_AMOUNT);
                out.Amount_Due__c = checkNullDecimal(obj.AMOUNT_DUE_REMAINING);
                out.FLEX_VALUE__c = checkNullDecimal(obj.FLEX_VALUE);
                out.SO_EXCISE_NO__c = obj.SO_EXCISE_NO;
                out.ECD_TERM_DUE_DAT__c = checkNullDecimal(obj.ECD_TERM_DUE_DAT);
                out.Org_Id__c = obj.ORG_ID;
                out.Invoice_Number__c = obj.ATTRIBUTE1; // ATTRIBUTE1 contains the Tax Invoice Number
                out.ATTRIBUTE2__c = obj.ATTRIBUTE2;
                out.ATTRIBUTE3__c = obj.ATTRIBUTE3;
                out.ATTRIBUTE4__c = obj.ATTRIBUTE4;
                out.ATTRIBUTE5__c = obj.ATTRIBUTE5;
                String str = obj.ATTRIBUTE6;

                // Split the string into parts
                List<String> parts = str.split('-');

                // Extract day, month, year
                Integer day = Integer.valueOf(parts[0]);
                Integer year = Integer.valueOf(parts[2]);

                // Map month abbreviations to numbers
                Map<String, Integer> monthMap = new Map<String, Integer>{
                    'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4,
                    'May' => 5, 'Jun' => 6, 'Jul' => 7, 'Aug' => 8,
                    'Sep' => 9, 'Oct' => 10, 'Nov' => 11, 'Dec' => 12
                };

                Integer month = monthMap.get(parts[1]);

                // Create the Date
                Date dt = Date.newInstance(year, month, day);

                out.As_on_Date__c = dt;

                API_Log__c apilog = new API_Log__c();
                apilog.Log_Name__c = 'CreateOutstanding_SubAPI';
                apilog.Request__c = JSON.serialize(obj);
                apilog.Request_Time__c = DateTime.now();
                apilog.response_time__c = Datetime.now();

                apilogToInsert.add(apilog);
                outstandingToInsert.add(out);
            }

            // Insert Outstanding
            if (outstandingToInsert.size() > 0) {
                insert apilogToInsert;
                insert outstandingToInsert;
            }

            System.debug('-->Data Saved Successfully');
            // ------------------- Send the Success Response -------------------
            Map < string, object > successResMap = new Map < string, object > ();
            successResMap.put('status', 'true');
            successResMap.put('message', 'Outstanding Inserted Successfully');
            String resp = JSON.serialize(successResMap);
            response.responseBody = Blob.valueOf(resp);
            response.addHeader('Content-Type', 'application/json');
            response.statusCode = 200;

            api_log.Log_Status__c = 'Success';
            api_log.Response_Code__c = '200';
            api_log.Response__c = String.valueOf(resp);
            api_log.response_time__c = Datetime.now();
            
        } catch (Exception e) {
            System.debug('Catch Error' + e.getStackTraceString());
            System.debug('Catch Error' + e.getMessage());
            System.debug('Catch Error' + e.getlineNumber());

            // ------------------- Create Response Map -------------------
            Map < string, string > errorResMap = new Map < string, string > ();
            errorResMap.put('status', 'false');
            errorResMap.put('message', e.getMessage() + ' || ' +e.getLineNumber());

            // ------------------- Send Response Map -------------------
            String resp = JSON.serialize(errorResMap);
            response.responseBody = Blob.valueOf(resp);
            response.addHeader('Content-Type', 'application/json');
            response.statusCode = 400;

            api_log.Log_Status__c = 'Failure';
            api_log.Response_Code__c = '400';
            api_log.Exception_Description__c = 'Line Number : ' + e.getLineNumber() + ' \n\n ' + e.getMessage() + '\n\n' + e.getStackTraceString();
            api_log.Response_Time__c = Datetime.now();

        }

        insert api_log;

    }

    public static Decimal checkNullDecimal (String val){

        if(val == null || val == ''){
            return 0.0;
        } else {
            return Decimal.valueOf(val);
        }
    }

    public class JSON2ApexSaveWebToLead {

        public String Amount_Due;
        // public String Balance_Due;
        public String BU;
        public String Cr_Terms;
        public String Customer_Number;
        public String Customer_Name;
        public String Due_Date;
        public String Invoice_Group;
        public String Invoice_Date;
        public String Invoice_No;
        public String Item_Description;
        public String Item_Number;
        public String LOCATION;
        public String Mode_of_Payment;
        public String Purchase_Order;
        public String Receipt_CN_Diff;
        public String Remarks;
        public String Tax_Invoice_Number;
        public String Trade;
        public String CTT_CLASS;
        public String CUSTOMER_ID;
        public String BILL_TO_CUSTOMER_NUM;
        public String BILL_TO_CUSTOMER_NAME;
        public String LINE_TYPE;
        public String ACCOUNT_CLASS;
        public String CUSTOMER_TRX_ID;
        public String TRX_DATE;
        public String TRX_NUMBER;
        public String TERM_DUE_DATE;
        public String INVOICE_CURRENCY_CODE;
        public String BS_BATCH_SOURCE_NAME;
        public String DESCRIPTION;
        public String ACCTD_AMOUNT;
        public String AMOUNT_DUE_REMAINING;
        public String FLEX_VALUE;
        public String SO_EXCISE_NO;
        public String ECD_TERM_DUE_DAT;
        public String ORG_ID;
        public String ATTRIBUTE1;
        public String ATTRIBUTE2;
        public String ATTRIBUTE3;
        public String ATTRIBUTE4;
        public String ATTRIBUTE5;
        public String ATTRIBUTE6;
    }

    public static List < JSON2ApexSaveWebToLead > parse(String json) {
        return (List < JSON2ApexSaveWebToLead > ) System.JSON.deserialize(json, List < JSON2ApexSaveWebToLead > .class);
    }

}