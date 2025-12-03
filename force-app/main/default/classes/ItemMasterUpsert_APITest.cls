@isTest
private class ItemMasterUpsert_APITest {
    @isTest
    static void testDoPost_Success() {
        // Setup test data
        Organization__c org = new Organization__c(Name = 'Test Org', Organization_Id__c = 1001);
        insert org;
        
        Operating_Unit__c opUnit = new Operating_Unit__c(Name = 'Test Unit');
        insert opUnit;
        
        // Create JSON request body
       String requestBody = '{"inventoryItemId":"12345","itemCode":"ITEM001","itemDescription":"Test Item",' +
                     '"attribute13":"Attr13","organizationId":"1001","shelfLifeDays":"30",' +
                     '"operatingUnit":"Test Unit","casNumber":"CAS123","enabledFlag":"true",' +
                     '"itemType":"Finished Good","inventoryItemFlag":"true"}';

        
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        ItemMasterUpsert_API.doPost();
        Test.stopTest();
        
        // Assertions
        List<Product2> productList = [SELECT Id FROM Product2 WHERE ProductCode = 'ITEM001'];
    }
    
    
    @isTest
    static void testDoPost_Failure_MissingOrg() {
        String requestBody = '{"inventoryItemId":"12345","itemCode":"ITEM001","organizationId":"9999"}';
        
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        ItemMasterUpsert_API.doPost();
        Test.stopTest();
        
  
    }
}