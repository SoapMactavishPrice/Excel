@RestResource(urlMapping='/CreateUpdateItemMaster')
global class ItemMasterUpsert_API {
    
    @HttpPost
    global static void doPost() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        String jSONRequestBody = request.requestBody.toString().replace('\n', '');
        
        // ------------------- API LOG to track the request -------------------
        API_Log__c api_log = new API_Log__c();
        api_log.Log_Name__c = 'CreateUpdateItemMaster';
        api_log.Request__c = jSONRequestBody;
        api_log.Request_Time__c = DateTime.now();

        JSON2ApexSaveWebToLead jsonObj = JSON2ApexSaveWebToLead.parse(jSONRequestBody);
        System.debug('======----->jsonObj' + jsonObj);

        try {

            if (String.isBlank(jsonObj.itemCode) || String.isBlank(jsonObj.organizationId)) {
                throw new IllegalArgumentException('itemCode and organizationId required');
            } else {
                List<Organization__c> orgList = [
                    SELECT Id, Name, Organization_Id__c
                    FROM Organization__c
                    WHERE Organization_Id__c =: Decimal.valueOf(jsonObj.organizationId)
                ];
                List<Product2> itemList = [SELECT Id, Name FROM Product2 WHERE ProductCode =: jsonObj.itemCode];
                if (orgList.size() > 0) {

                    List<Product2> existingItem = [
                        SELECT Id, Name, ProductCode, Organization_Name__c
                        FROM Product2
                        WHERE ProductCode =: jsonObj.itemCode
                        AND Organization_Name__c =: orgList[0].Id
                    ];

                    Product2 upsertItem = new Product2();

                    if (existingItem.size() > 0) {
                        upsertItem.Id = existingItem[0].Id;
                    } else {
                        upsertItem.Organization_Name__c = orgList[0].Id;
                        upsertItem.Organization_ID__c = String.valueOf(orgList[0].Organization_Id__c);
                        upsertItem.ProductCode = jsonObj.itemCode;
                    }
                    
                    upsertItem.Name = jsonObj.itemDescription;
                    upsertItem.Inventory_Item_Id__c = jsonObj.inventoryItemId;
                    upsertItem.Description = jsonObj.itemDescription;
                    upsertItem.Attribute_13__c = jsonObj.attribute13;
                    upsertItem.Shelf_Life_Days__c = Decimal.valueOf(jsonObj.shelfLifeDays);
                    upsertItem.Cas_Number__c = jsonObj.casNumber;
                    upsertItem.Enabled_Flag__c = Boolean.valueOf(jsonObj.enabledFlag);
                    upsertItem.Item_Type__c = jsonObj.itemType;
                    upsertItem.Inventory_Item_Flag__c = Boolean.valueOf(jsonObj.inventoryItemFlag);
                    if (!String.isBlank(jsonObj.operatingUnit)) {
                        List<Operating_Unit__c> opUnitList = [SELECT Id, Name FROM Operating_Unit__c WHERE Name =: jsonObj.operatingUnit];
                        if (opUnitList.size() > 0) {
                            upsertItem.Operating_Unit__c = opUnitList[0].Id;
                        }
                    }

                    upsert upsertItem;

                    System.debug('-->Data Saved Successfully');
                    // ------------------- Send the Success Response -------------------
                    Map < string, object > successResMap = new Map < string, object > ();
                    successResMap.put('status', 'success');
                    successResMap.put('message', 'Item Master Upsert Successfully');
                    String resp = JSON.serialize(successResMap);
                    response.responseBody = Blob.valueOf(resp);
                    response.addHeader('Content-Type', 'application/json');
                    response.statusCode = 200;

                    api_log.Log_Status__c = 'Success';
                    api_log.Response_Code__c = '200';
                    api_log.Response__c = String.valueOf(resp);
                    api_log.response_time__c = Datetime.now();
                    
                } else {
                    if (orgList.size() == 0) {
                        throw new IllegalArgumentException('organizationId not present');
                    }
                }
            }


        } catch (Exception e) {
            System.debug('Catch Error' + e.getStackTraceString());
            System.debug('Catch Error' + e.getMessage());
            System.debug('Catch Error' + e.getlineNumber());

            // ------------------- Create Response Map -------------------
            Map < string, string > errorResMap = new Map < string, string > ();
            errorResMap.put('status', 'Something went wrong');
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

    public class JSON2ApexSaveWebToLead {
        public String inventoryItemId;
        public String itemCode;
        public String itemDescription;
        public String attribute13;
        public String creationDate;
        public String organizationId;
        public String organizationCode;
        public String shelfLifeDays;
        public String operatingUnit;
        public String casNumber;
        public String enabledFlag;
        public String itemType;
        public String inventoryItemFlag;
    }

    public static JSON2ApexSaveWebToLead parse(String json) {
        return (JSON2ApexSaveWebToLead) System.JSON.deserialize(json, JSON2ApexSaveWebToLead.class);
    }


}