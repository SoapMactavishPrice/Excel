public class CustomerUpsert_ToOracle {

    // @future(callout=true)
    @AuraEnabled
    public static String sendCustomerData(String accId) {

        String responseBodyData = '';

        // ------------------- API LOG to track the request -------------------
        API_Log__c api_log = new API_Log__c();
        api_log.Log_Name__c = 'CustomerUpsert_ToOracle';
        api_log.Request_Time__c = DateTime.now();
        
        try {
            
            String jsonBody = createJSONrequest(accId);
            api_log.Request__c = jsonBody;

            // Define API URL
            String apiUrl = label.CreateCustomerOracle;

            // Authentication Header
            String username = label.api_username;
            String password = label.api_pass;
            String authHeader = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password));

            // Create HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(apiUrl);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', authHeader);
            req.setBody(jsonBody);
            req.setTimeout(120000);

            // Send HTTP request
            Http http = new Http();
            HttpResponse res = http.send(req);

            // Debug response
            // System.debug('Response: ' + res.getBody());
            String responseBody = res.getBody();
            responseBodyData = parseresponseBodyData(responseBody, accId);

            if(res.getStatusCode() == 200) {
                api_log.Log_Status__c = 'Success';
            } else {
                api_log.Log_Status__c = 'Failure';
            }
            api_log.Response_Code__c = String.valueOf(res.getStatusCode());
            api_log.Response__c = res.getBody();
            api_log.response_time__c = Datetime.now();

        } catch (Exception e) {
            System.debug('Error in API Call: ' + e.getMessage());
            responseBodyData = e.getMessage();
            api_log.Log_Status__c = 'Failure';
            api_log.Response_Code__c = '400';
            api_log.Exception_Description__c = 'Line Number : ' + e.getLineNumber() + ' \n\n ' + e.getMessage() + '\n\n' + e.getStackTraceString();
            api_log.Response_Time__c = Datetime.now();
        }

        insert api_log;

        return responseBodyData;
    }

    public static String createJSONrequest(String Id){
        Account acc = [
            SELECT Id, Blocked__c, Contact_First_Name__c, Contact_Last_Name__c, Credit_Limit__c, Country_Code__c,
            Customer_Code__c, Customer_Posting_Group__c, Customer_Group__c, Phone, Name, Telephone_Area_Code__c,
            Telephone_Extension__c, Telephone_Type__c, Company_Email_Address__c, GST_Customer_Type__c, GSTIN_No__c,
            Gen_Bus_Posting_Group__c, PAN_No__c, PAN_Status__c, Payment_Terms__c, Sales_Person_Code__c, Territory__c,
            Organization__c, Organization__r.Organization_Id__c, Gender__c, Organization__r.OU_Id__c
            FROM Account
            // WHERE Id = '001Hz00000tPgzQIAS'
            WHERE Id =: Id
        ];

        Map<String, Object> outerMap = new Map<String, Object>();
        Map<String, Object> inputParameters = new Map<String, Object>();
        Map<String, Object> primaryInnerInputParameters = new Map<String, Object>();
        Map<String, Object> innerInputParameters = new Map<String, Object>();

        innerInputParameters.put('blocked', acc.Blocked__c);
        innerInputParameters.put('genBusPostingGroup', acc.Gen_Bus_Posting_Group__c);
        innerInputParameters.put('customerPostingGroup', acc.Customer_Posting_Group__c);
        innerInputParameters.put('customerGroup', acc.Customer_Group__c);
        innerInputParameters.put('territoryCode', acc.Territory__c);
        innerInputParameters.put('gstCustomerType', acc.GST_Customer_Type__c);
        innerInputParameters.put('gstRegistrationNo', acc.GSTIN_No__c);
        innerInputParameters.put('panStatus', acc.PAN_Status__c);
        innerInputParameters.put('panNo', acc.PAN_No__c);
        innerInputParameters.put('salesPersonCode', acc.Sales_Person_Code__c);
        // innerInputParameters.put('responsibilityCentre', acc.Sales_Person_Code__c);
        innerInputParameters.put('creditLimitLCY', acc.Credit_Limit__c);
        innerInputParameters.put('paymentTerms', acc.Payment_Terms__c);
        // innerInputParameters.put('currencyCode', acc.Organization__c);
        innerInputParameters.put('customerPhoneNo', acc.Phone);
        innerInputParameters.put('contact', acc.Contact_First_Name__c+' '+acc.Contact_Last_Name__c);
        innerInputParameters.put('eMail', acc.Company_Email_Address__c);
        innerInputParameters.put('countryRegionCode', acc.Country_Code__c);
        innerInputParameters.put('customerName', acc.Name);
        innerInputParameters.put('customerNo', acc.Customer_Code__c);
        innerInputParameters.put('telephoneExtension', acc.Telephone_Extension__c);
        innerInputParameters.put('telephoneType', acc.Telephone_Type__c);
        innerInputParameters.put('telephoneAreaCode', acc.Telephone_Area_Code__c);
        innerInputParameters.put('contactFirstName', acc.Contact_First_Name__c);
        innerInputParameters.put('contactLastName', acc.Contact_Last_Name__c);
        innerInputParameters.put('org_id', acc.Organization__c != null ? acc.Organization__r.OU_Id__c : null);
        // innerInputParameters.put('org_id', 120);
        innerInputParameters.put('gender', acc.Gender__c);

        // innerInputParameters.put('uniqueID', acc.Customer_Code__c);

        List<Address_Information__c> addInfoByAccId = new List<Address_Information__c>();
        addInfoByAccId = [
            SELECT Id, Name, Address_1__c, Address_2__c, Postal_Code__c, Postal_Code__r.Name,
            Area__c, Area__r.Name, City__c, City__r.Name, State__c, State__r.Name, Country__c, Country__r.Name,
            SF_Address_Code__c, Primary_Address__c, Account__c, RecordType.DeveloperName
            FROM Address_Information__c
            // WHERE Account__c = '001Hz00000tPgzQIAS'
            WHERE Account__c =: Id
            AND Is_Sync_to_Oracle__c = false
        ];

        List<Map<String, Object>> addressList = new List<Map<String, Object>>();
        for (Address_Information__c a : addInfoByAccId) {
            Map<String, Object> mapName = new Map<String, Object>{
                'siteUse' => a.RecordType.DeveloperName.toUpperCase(),
                'siteUseCode' => a.SF_Address_Code__c,
                'location' => a.Area__r.Name,
                'postcode' => a.Postal_Code__r.Name,
                'state' => a.State__r.Name,
                'city' => a.City__r.Name,
                'customerAddress' => a.Address_1__c,
                'customerAddress2' => a.Address_2__c,
                'primaryAddress' => a.Primary_Address__c
            };
            addressList.add(mapName);
        }

        // Add address list to innerInputParameters
        innerInputParameters.put('address', addressList);

        // Add innerInputParameters to primaryInnerInputParameters
        primaryInnerInputParameters.put('InputParameters', innerInputParameters);
        
        // Add primaryInnerInputParameters to inputParameters
        inputParameters.put('P_JSON', JSON.serialize(primaryInnerInputParameters));
        inputParameters.put('P_UNIQUE_ID', generateUniqueNumber());

        // Add inputParameters to outerMap
        outerMap.put('InputParameters', inputParameters);

        String jsonString = JSON.serialize(outerMap);
        // System.debug(jsonString);

        // API_Log__c a = new API_Log__c();
        // a.Request__c = jsonString;
        // insert a;

        return jsonString;

    }

    public static String generateUniqueNumber() {
        Datetime now = Datetime.now();
        String formatted = 'SF'+now.format('yyyyMMddHHmmssSSS');
        return formatted;
    }

    public static String parseresponseBodyData(String responseBody, String accId) {
        String status = '';
        String oracleCustomerNo = '';

        try {

            // Parse the JSON into a generic map
            Map<String, Object> fullJson = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
    
            if (fullJson.containsKey('OutputParameters')) {
                Map<String, Object> outputParams = (Map<String, Object>) fullJson.get('OutputParameters');
    
                if (outputParams.containsKey('P_RESPONSE')) {
                    Map<String, Object> pResponse = (Map<String, Object>) outputParams.get('P_RESPONSE');
    
                    if (pResponse.containsKey('Row')) {
                        List<Object> rows = (List<Object>) pResponse.get('Row');
    
                        if (!rows.isEmpty()) {
                            // Get the first row only
                            Map<String, Object> firstRow = (Map<String, Object>) rows[0];
    
                            if (firstRow.containsKey('Column')) {
                                List<Object> columns = (List<Object>) firstRow.get('Column');
    
                                for (Object colObj : columns) {
                                    Map<String, Object> column = (Map<String, Object>) colObj;
                                    String name = (String) column.get('@name');
                                    String value = (String) column.get('$');
    
                                    if (name == 'STATUS') {
                                        status = value;
                                    }
                                    if (name == 'ORACLECUSTOMERNO') {
                                        oracleCustomerNo = value;
                                    }
                                }
    
                                // Check for 'ERROR' in STATUS
                                if (!String.isEmpty(status) && (status.contains('ERROR') || status.contains('Error') || status.contains('error'))) {
                                    System.debug('ERROR in STATUS: ' + status);
                                } else {

                                    Map<Object, Object> sfnOracleSiteIdMap = new Map<Object, Object>();

                                    for (Object rowObj : rows) {

                                        Map<String, Object> rowObjMap = (Map<String, Object>) rowObj;
                                        List<Object> columnsList = (List<Object>) rowObjMap.get('Column');

                                        String sfSiteId = '';
                                        String oracleSiteId = '';
    
                                        for (Object colObj : columnsList) {
                                            Map<String, Object> column = (Map<String, Object>) colObj;
                                            String name = (String) column.get('@name');
                                            String value = (String) column.get('$');
            
                                            if (name == 'SFSITEID') {
                                                sfSiteId = value;
                                            }
                                            if (name == 'ORACLESITEID') {
                                                oracleSiteId = value;
                                            }
                                        }
                                        sfnOracleSiteIdMap.put(sfSiteId, oracleSiteId);
                                    }
                                    saveResponseData(sfnOracleSiteIdMap, oracleCustomerNo, accId);
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            status = e.getMessage();
            System.debug('Error while parsing responseBody: ' + e.getMessage());
        }
        return status;
    }
    
    public static void saveResponseData(Map<Object, Object> sfnOracleSiteIdMap, String oracleCustomerNo, String accId) {
        System.debug(sfnOracleSiteIdMap);
        System.debug(oracleCustomerNo);
        System.debug(accId);
        Account acc = new Account();
        acc.Id = accId;
        acc.Oracle_Customer_No__c = oracleCustomerNo;
        update acc;

        List<Address_Information__c> addInfoList = [
            SELECT Id, Name, Is_Sync_to_Oracle__c, SF_Address_Code__c
            FROM Address_Information__c
            WHERE Account__c =: accId
            // AND Is_Sync_to_Oracle__c = false
        ];

        for (Address_Information__c addInfo : addInfoList) {
            addInfo.Is_Sync_to_Oracle__c = true;
            if (sfnOracleSiteIdMap.containsKey(addInfo.SF_Address_Code__c)) {
                addInfo.Oracle_Site_Code__c = (String) sfnOracleSiteIdMap.get(addInfo.SF_Address_Code__c);
            }
        }
        update addInfoList;

    }

}