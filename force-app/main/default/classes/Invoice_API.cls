@RestResource(urlMapping = '/CreateInvoice')
global class Invoice_API {
    @HttpPost
    global static void doPost() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        String jSONRequestBody = request.requestBody.toString().replace('\n', '');
        jSONRequestBody = jSONRequestBody.replace('/', '&sol;');

        // ------------------- API LOG to track the request -------------------
        API_Log__c api_log = new API_Log__c();
        api_log.Log_Name__c = 'CreateInvoiceAPI';
        api_log.Request__c = jSONRequestBody;
        api_log.Request_Time__c = DateTime.now();

        List<JSON2ApexSaveWebToLead> jsonObj = JSON2ApexSaveWebToLead.parse(jSONRequestBody);
        System.debug('======----->jsonObj' + jsonObj);

        List<Invoice__c> invoiceToInsert = new List<Invoice__c>();
        List<Invoice_Line_Item__c> invoiceLIToInsert = new List<Invoice_Line_Item__c>();

        try {

            Set<String> customerNumberSet = new Set<String>();
            Set<String> orderNumberSet = new Set<String>();
            Set<String> itemNumberSet = new Set<String>();

            for (JSON2ApexSaveWebToLead obj : jsonObj) {
                customerNumberSet.add(obj.CUST_NUMBER);
                orderNumberSet.add(obj.ORDER_NUMBER);
                for (InvoiceLineItemWrapper z : obj.InvoiceLineItem) {
                    itemNumberSet.add(z.ORDERED_ITEM);
                }
            }

            // Get Account data
            List<Account> accList = [
                SELECT Id, Name, Oracle_Customer_No__c
                FROM Account
                WHERE Oracle_Customer_No__c != null
                AND Oracle_Customer_No__c IN :customerNumberSet
            ];

            Map<String, Object> custNumAccIdMap = new Map<String, Object>();

            for (Account acc : accList) {
                custNumAccIdMap.put(acc.Oracle_Customer_No__c, acc.Id);
            }

            // Get Order data
            List<Order> ordList = [
                SELECT Id, Name, Oracle_Sales_Order_No__c
                FROM Order
                WHERE Oracle_Sales_Order_No__c != null
                AND Oracle_Sales_Order_No__c IN :orderNumberSet
            ];

            Map<String, Object> orderNumOrdIdMap = new Map<String, Object>();

            for (Order ord : ordList) {
                orderNumOrdIdMap.put(ord.Oracle_Sales_Order_No__c, ord.Id);
            }

            // Get Product data
            List<Product2> productList = [
                SELECT Id, Name, ProductCode
                FROM Product2
                WHERE ProductCode != null
                AND ProductCode IN :itemNumberSet
            ];

            Map<String, Object> prodCodeProdIdMap = new Map<String, Object>();

            for (Product2 p : productList) {
                prodCodeProdIdMap.put(p.ProductCode, p.Id);
            }

            // Insert Invoices
            for (JSON2ApexSaveWebToLead obj : jsonObj) {

                Invoice__c inv = new Invoice__c();
                inv.Name = obj.TAX_INVOICE_NUM;
                inv.Order_Type__c = obj.ORDER_TYPE;
                if (String.isNotBlank(obj.TAX_INVOICE_DATE)) {
                    inv.Tax_Invoice_Date__c = Date.valueOf(obj.TAX_INVOICE_DATE);
                }
                // inv.Tax_Invoice_Date__c = obj.TAX_INVOICE_DATE;
                inv.Tax_Invoice_Number__c = obj.TAX_INVOICE_NUM;
                inv.Trx_Number__c = obj.TRX_NUMBER;
                inv.Customer_PO_Number__c = obj.CUST_PO_NUMBER;
                inv.CUSTOMER_TRX_ID__c = obj.CUSTOMER_TRX_ID;
                if (String.isNotBlank(obj.trx_date)) {
                    inv.trx_date__c = Date.valueOf(obj.trx_date);
                }
                inv.Customer_Number__c = obj.CUST_NUMBER;
                if (custNumAccIdMap.containskey(obj.CUST_NUMBER)) {
                    inv.Customer_Name__c = String.valueOf(custNumAccIdMap.get(obj.CUST_NUMBER));
                }
                inv.GSTIN_Number__c = obj.GSTIN;
                inv.Payment_Terms__c = obj.PAYMENT_TERM;
                inv.Mode_of_Payment__c = obj.PAYMENT_MODE;
                // inv.State_Of_Customer__c = obj.State_Of_Customer;
                if (orderNumOrdIdMap.containskey(obj.ORDER_NUMBER)) {
                    inv.Sale_Order_Number__c = String.valueOf(orderNumOrdIdMap.get(obj.ORDER_NUMBER));
                }
                if (String.isNotBlank(obj.ORDERED_DATE)) {
                    inv.Sale_Order_Date__c = Date.valueOf(obj.ORDERED_DATE);
                }
                inv.Freight_Terms_Code__c = obj.FREIGHT_TERMS_CODE;
                inv.Freight_Carrier_Code__c = obj.FREIGHT_CARRIER_CODE;
                // inv.Transporter__c = obj.Transporter;
                inv.Vehicle_Number__c = obj.VEHICLE_NUM;
                inv.LR_Number__c = obj.LR_NUM;
                inv.Mode_of_Transport__c = obj.MODE_OF_TRANSPORT;
                // inv.INV_ORG__c = obj.INV_ORG;
                inv.BU_Name__c = obj.BU;
                inv.Ship_To_Address_1__c = obj.SHIP_TO_ADDRESS1;
                inv.Ship_To_Address_2__c = obj.SHIP_TO_ADDRESS2;
                inv.Ship_To_Address_3__c = obj.SHIP_TO_ADDRESS3;
                inv.Ship_To_Address_4__c = obj.SHIP_TO_ADDRESS4;
                inv.Header_Id__c = String.valueOf(obj.HEADER_ID);
                inv.Org_Id__c = String.valueOf(obj.ORG_ID);
                inv.Order_Type_Id__c = String.valueOf(obj.ORDER_TYPE_ID);
                inv.Shipping_Method_Code__c = obj.SHIPPING_METHOD_CODE;
                inv.Sold_to_Org_Id__c = String.valueOf(obj.SOLD_TO_ORG_ID);
                inv.Invoice_to_Org_Id__c = String.valueOf(obj.INVOICE_TO_ORG_ID);
                inv.Ship_from_Org_Id__c = String.valueOf(obj.SHIP_FROM_ORG_ID);
                inv.Organization_Code__c = obj.ORGANIZATION_CODE;
                if (String.isNotBlank(obj.SO_CREATION_DATE)) {
                    inv.SO_Creation_Date__c = Date.valueOf(obj.SO_CREATION_DATE);
                }
                inv.Delivery_Id__c = String.valueOf(obj.DELIVERY_ID);
                if (String.isNotBlank(obj.DATE_SHIPPED)) {
                    inv.Date_Shipped__c = Date.valueOf(obj.DATE_SHIPPED);
                }
                inv.Customer_Account_Id__c = String.valueOf(obj.CUST_ACCOUNT_ID);
                inv.Party_Name__c = obj.PARTY_NAME;
                // inv.State__c = obj.STATE; // Lookup
                inv.Ship_to_Location__c = obj.SHIP_TO_LOCATION;
                inv.Attribute_1__c = obj.ATTRIBUTE1;
                inv.Attribute_2__c = obj.ATTRIBUTE2;
                inv.Attribute_3__c = obj.ATTRIBUTE3;
                inv.Attribute_4__c = obj.ATTRIBUTE4;
                inv.SEGMENT1__c = obj.SEGMENT1;
                inv.SEGMENT2__c = obj.SEGMENT2;
                inv.SEGMENT3__c = obj.SEGMENT3;
                inv.SEGMENT4__c = obj.SEGMENT4;
                invoiceToInsert.add(inv);
            }

            if (invoiceToInsert.size() > 0) {
                insert invoiceToInsert;
                for (Integer i = 0; i < jsonObj.size(); i++) {
                    Invoice__c inv = invoiceToInsert[i];
                    JSON2ApexSaveWebToLead req = jsonObj[i];
                    for (InvoiceLineItemWrapper z : req.InvoiceLineItem) {
                        Invoice_Line_Item__c ili = new Invoice_Line_Item__c();
                        ili.Invoice__c = inv.Id;
                        ili.Name = String.valueOf(z.HEADER_ID)+'/'+String.valueOf(z.LINE_ID)+'/'+String.valueOf(z.LINE_NUMBER);
                        if (prodCodeProdIdMap.containskey(z.ORDERED_ITEM)) {
                            ili.Product__c = String.valueOf(prodCodeProdIdMap.get(z.ORDERED_ITEM));
                        }
                        ili.Item_Number__c = z.ORDERED_ITEM;
                        ili.Item_Description__c = z.ITEM_DESC;
                        ili.HSN_SAC_Code__c = z.HSN_SAC_CODE;
                        ili.Shipping_Quantity_UOM__c = z.SHIPPING_QUANTITY_UOM;
                        ili.Shipped_Quantity__c = checkNullDecimal(z.SHIPPED_QUANTITY);
                        if (String.isNotBlank(z.UNIT_SELLING_PRICE)) {
                            ili.Unit_Selling_Price__c = Decimal.valueOf(z.UNIT_SELLING_PRICE);
                        }
                        ili.Exchange_Rate__c = checkNullDecimal(z.EXCHANGE_RATE);
                        ili.Line_Amount__c = checkNullDecimal(z.LINE_AMOUNT);
                        // ili.Discount_Percentage_Desc__c = checkNullDecimal(z.Discount_Percentage_Desc);
                        // ili.Discount_Amount__c = checkNullDecimal(z.Discount_Amount);
                        // ili.Freight_Amount__c = checkNullDecimal(z.Freight_Amount);
                        // ili.P_F_Amount__c = checkNullDecimal(z.P_F_Amount);
                        ili.Taxable_Value__c = checkNullDecimal(z.TAXABLE);
                        ili.SGST_Percent__c = checkNullDecimal(z.SGSTPER);
                        ili.SGST_Amount__c = checkNullDecimal(z.SGST);
                        ili.CGST_Percent__c = checkNullDecimal(z.CGSTPER);
                        ili.CGST_Amount__c = checkNullDecimal(z.CGST);
                        ili.IGST_Percent__c = checkNullDecimal(z.IGSTPER);
                        ili.IGST_Amount__c = checkNullDecimal(z.IGST);
                        ili.Total_GST__c = checkNullDecimal(z.TOTAL_GST);
                        // ili.Sub_Total__c = checkNullDecimal(z.Sub_Total);
                        ili.TCS_Percent__c = checkNullDecimal(z.TCSPER);
                        ili.TCS_Amount__c = checkNullDecimal(z.TCS);
                        ili.INV_Val__c = checkNullDecimal(z.INV_VAL);
                        ili.Transactional_Currency_Code__c = z.TRANSACTIONAL_CURR_CODE;
                        ili.TAX_INVOICE_NUM__c = z.TAX_INVOICE_NUM;
                        ili.CUSTOMER_TRX_ID__c = z.CUSTOMER_TRX_ID;
                        ili.TRX_NUMBER__c = z.TRX_NUMBER;
                        ili.GSTIN__c = z.GSTIN;
                        ili.DELIVERY_ID__c = z.DELIVERY_ID;
                        if (String.isNotBlank(z.DATE_SHIPPED)) {
                            ili.DATE_SHIPPED__c = Date.valueOf(z.DATE_SHIPPED);
                        }
                        ili.VEHICLE_NUM__c = z.VEHICLE_NUM;
                        ili.LR_NUM__c = z.LR_NUM;
                        ili.MODE_OF_TRANSPORT__c = z.MODE_OF_TRANSPORT;

                        ili.Header_Id__c = String.valueOf(z.HEADER_ID);
                        ili.Line_Id__c = String.valueOf(z.LINE_ID);
                        ili.Line_Number__c = checkNullDecimal(z.LINE_NUMBER);
                        ili.Order_Item__c = z.ORDERED_ITEM;
                        ili.HSN__c = z.HSN;
                        ili.Inventory_Item_Id__c = String.valueOf(z.INVENTORY_ITEM_ID);
                        ili.Order_Quantity_UOM__c = z.ORDER_QUANTITY_UOM;
                        ili.Pricing_Quantity__c = String.valueOf(z.PRICING_QUANTITY);
                        ili.Pricing_Quantity_UOM__c = z.PRICING_QUANTITY_UOM;
                        ili.Order_Quantity__c = String.valueOf(z.ORDERED_QUANTITY);
                        ili.PER_DISC__c = checkNullDecimal(z.PER_DISC);
                        ili.DISC__c = checkNullDecimal(z.DISC);
                        ili.Freight__c = String.valueOf(z.FREIGHT);
                        ili.PF_CHARGES__c = checkNullDecimal(z.PF_CHARGES);
                        ili.Attribute_1__c = z.ATTRIBUTE1;
                        ili.Attribute_2__c = z.ATTRIBUTE2;
                        ili.SEGMENT1__c = z.SEGMENT1;
                        ili.SEGMENT2__c = z.SEGMENT2;
                        invoiceLIToInsert.add(ili);
                    }
                }
                if (invoiceLIToInsert.size() > 0) {
                    insert invoiceLIToInsert;
                }
            }

            System.debug('-->Data Saved Successfully');
            // ------------------- Send the Success Response -------------------
            Map < string, object > successResMap = new Map < string, object > ();
            successResMap.put('status', 'true');
            successResMap.put('message', 'Invoice Inserted Successfully');
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
            errorResMap.put('message', e.getMessage());

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
            // return val;
        }
    }

    // If date is in 02-02-2025 format
    public static Date convertToDate(String dateStr) {
        if (String.isBlank(dateStr)) return null;

        List<String> parts = dateStr.split('-');
        if (parts.size() != 3) return null;

        Integer day = Integer.valueOf(parts[0]);
        Integer month = Integer.valueOf(parts[1]);
        Integer year = Integer.valueOf(parts[2]);

        return Date.newInstance(year, month, day);
    }

    public class JSON2ApexSaveWebToLead {
        public List<InvoiceLineItemWrapper> InvoiceLineItem;
        public String HEADER_ID;
        public String ORG_ID;
        public String ORDER_TYPE_ID;
        public String ORDER_TYPE;
        public String ORDER_NUMBER;
        public String ORDERED_DATE;
        public String CUST_PO_NUMBER;
        public String TAX_INVOICE_NUM;
        public String TAX_INVOICE_DATE;
        public String CUSTOMER_TRX_ID; // New
        public String TRX_NUMBER;
        public String trx_date; // New
        public String GSTIN;
        public String DELIVERY_ID;
        public String DATE_SHIPPED;
        public String VEHICLE_NUM;
        public String LR_NUM;
        public String MODE_OF_TRANSPORT;
        public String SHIPPING_METHOD_CODE;
        public String FREIGHT_TERMS_CODE;
        public String FREIGHT_CARRIER_CODE;
        public String SOLD_TO_ORG_ID;
        public String INVOICE_TO_ORG_ID;
        public String SHIP_FROM_ORG_ID;
        public String ORGANIZATION_CODE;
        public String PAYMENT_TERM;
        public String PAYMENT_MODE;
        public String BU;
        public String SO_CREATION_DATE;
        public String CUST_ACCOUNT_ID;
        public String CUST_NUMBER;
        public String PARTY_NAME;
        public String STATE;
        public String SHIP_TO_LOCATION;
        public String SHIP_TO_ADDRESS1;
        public String SHIP_TO_ADDRESS2;
        public String SHIP_TO_ADDRESS3;
        public String SHIP_TO_ADDRESS4;
        public String ATTRIBUTE1;
        public String ATTRIBUTE2;
        public String ATTRIBUTE3;
        public String ATTRIBUTE4;
        public String SEGMENT1;
        public String SEGMENT2;
        public String SEGMENT3;
        public String SEGMENT4;
    }

    
    public class InvoiceLineItemWrapper {
        public String HEADER_ID;
        public String LINE_ID;
        public String LINE_NUMBER;
        public String ORDERED_ITEM;
        public String ITEM_DESC;
        public String HSN;
        public String HSN_SAC_CODE;
        public String INVENTORY_ITEM_ID;
        public String ORDER_QUANTITY_UOM;
        public String PRICING_QUANTITY;
        public String PRICING_QUANTITY_UOM;
        public String ORDERED_QUANTITY;
        public String SHIPPED_QUANTITY;
        public String SHIPPING_QUANTITY_UOM;
        // public String UNIT_SELLING_PRICE;
        public String UNIT_SELLING_PRICE;
        public String EXCHANGE_RATE;
        public String LINE_AMOUNT;
        public String PER_DISC;
        public String DISC;
        public String FREIGHT;
        public String PF_CHARGES;
        public String SGSTPER;
        public String CGSTPER;
        public String IGSTPER;
        public String TCSPER;
        public String TAXABLE;
        public String SGST;
        public String CGST;
        public String IGST;
        public String INV_VAL;
        public String TCS;
        public String TOTAL_GST;
        public String TRANSACTIONAL_CURR_CODE;
        
        public String TAX_INVOICE_NUM;
        public String CUSTOMER_TRX_ID;
        public String TRX_NUMBER;
        public String GSTIN;
        public String DELIVERY_ID;
        public String DATE_SHIPPED;
        public String VEHICLE_NUM;
        public String LR_NUM;
        public String MODE_OF_TRANSPORT;
        

        public String ATTRIBUTE1;
        public String ATTRIBUTE2;
        public String SEGMENT1;
        public String SEGMENT2;
    }

    public static List < JSON2ApexSaveWebToLead > parse(String json) {
        return (List < JSON2ApexSaveWebToLead > ) System.JSON.deserialize(json, List < JSON2ApexSaveWebToLead > .class);
    }

}