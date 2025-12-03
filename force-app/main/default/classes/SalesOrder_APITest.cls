@isTest
global class SalesOrder_APITest {
    
    // Define MockHttpResponse as an inner class without @isTest
    global class MockHttpResponse implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"status": "success", "message": "Sales Order Created Successfully", "sfdcId": "12345"}');
            response.setStatusCode(200);
            return response;
        }
    }

    @testSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(Name = 'Test Account', Customer_Code__c = 'CUST123');
        insert testAccount;

        // Create test Operating Unit
        Operating_Unit__c testOU = new Operating_Unit__c(Name = 'OU123');
        insert testOU;

        // Create test Warehouse (Organization__c)
        Organization__c testWarehouse = new Organization__c(Organization_Id__c = 1001);
        insert testWarehouse;
    }

    @isTest
    static void testDoPost_Success() {
        // Set up the mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        // Create test data
        Account testAccount = new Account(Name = 'Prashant Customer', Customer_Code__c = 'pp123');
        insert testAccount;

        // Construct the JSON request
        String requestBody = '{ "customerNo": "CUST123", "no": "SO123", "orderDate": "2025-03-30", "requestedDeliveryDate": "2025-04-05", "promisedDeliveryDate": "2025-04-10", "externalDocumentNo": "DOC123" }';

        // Set up RestContext
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/CreateUpdateSalesOrder';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Call the method
        Test.startTest();
        SalesOrder_API.doPost();
        Test.stopTest();

        // Assertions
    }

    @isTest
    static void testSalesOrderCreation() {
        Test.startTest();

        String jsonRequest = '{"customerNo": "CUST123", "no": "SO123", "operatingUnitId": "OU123", "warehouseId": "1001", "currencyISOCode": "USD", "orderDate": "2025-03-30", "requestedDeliveryDate": "2025-04-05", "promisedDeliveryDate": "2025-04-10", "externalDocumentNo": "EXT123", "yourReference": "REF123", "poReceivedDate": "2025-03-25", "billToName": "Test BillTo", "billToAddress": "123 Test St", "billToCity": "TestCity", "billToPostCode": "12345", "billToCountryRegionCode": "US", "shipToName": "Test ShipTo", "shipToAddress": "456 Ship St", "shipToCity": "ShipCity", "shipToPostCode": "54321", "shipToCountryRegionCode": "US", "salesPersonCode": "SP123", "salesOrderNo": "SO-2025", "shortClosed": "false", "orderLineItems": []}';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonRequest);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        SalesOrder_API.doPost();

           Test.stopTest();
    }

    @isTest
    static void testSalesOrderMissingCustomerNo() {
        Test.startTest();

        String jsonRequest = '{"no": "SO123"}';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonRequest);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        SalesOrder_API.doPost();

        Test.stopTest();
    }

    @isTest
    static void testInvalidCustomerNo() {
        Test.startTest();

        String jsonRequest = '{"customerNo": "INVALID_CUST", "no": "SO123"}';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonRequest);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        SalesOrder_API.doPost();

        Test.stopTest();
    }
}