@isTest
private class CustomerUpsert_ToOracleTest {

    @TestSetup
    static void setupTestData() {
        Country__c testCountry = new Country__c(
            Name = 'Test Country'
        );
        insert testCountry;

        State__c testState = new State__c(
            Name = 'Test State',
            Country__c = testCountry.Id
        );
        insert testState;

        City__c testCity = new City__c(
            Name = 'Test City',
            State__c = testState.Id
        );
        insert testCity;

        Area__c testArea = new Area__c(
            Name = 'Test Area',
            City__c = testCity.Id
        );
        insert testArea;

        Postal_Code__c testPostalCode = new Postal_Code__c(
            Name = '12345',
            City__c = testCity.Id
        );
        insert testPostalCode;

        Account testAccount = new Account(
            Name = 'Test Account',
            Customer_Code__c = 'TEST123',
            Contact_First_Name__c = 'Test',
            Contact_Last_Name__c = 'User',
            Phone = '1234567890',
            Company_Email_Address__c = 'test@example.com',
            Country_Code__c = 'US',
            Blocked__c = false,
            Gen_Bus_Posting_Group__c = 'DOMESTIC',
            Customer_Posting_Group__c = 'Local',
            Customer_Group__c = 'Pharma',
            Territory__c = 'DOMESTICS',
            GST_Customer_Type__c = 'REGISTERED',
            GSTIN_No__c = 'GST123',
            PAN_Status__c = 'Available',
            PAN_No__c = 'PAN123',
            Sales_Person_Code__c = 'SP01',
            Credit_Limit__c = 100000,
            Payment_Terms__c = '0 Day',
            Telephone_Extension__c = '123',
            Telephone_Type__c = 'MOBILE',
            Telephone_Area_Code__c = '91',
            Gender__c = 'Male'
        );
        insert testAccount;

        Address_Information__c testAddress = new Address_Information__c(
            Name = 'Test Address',
            Account__c = testAccount.Id,
            Postal_Code__c = testPostalCode.Id,
            Address_1__c = '123 Main St',
            Area__c = testArea.Id,
            City__c = testCity.Id,
            State__c = testState.Id,
            Country__c = testCountry.Id,
            Site_Use_Code__c = 'BILL',
            Primary_Address__c = true
        );
        insert testAddress;
    }

    static testMethod void testSendCustomerData() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String result = CustomerUpsert_ToOracle.sendCustomerData(testAccount.Id);
    }

    static testMethod void testCreateJSONrequest() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String jsonRequest = CustomerUpsert_ToOracle.createJSONrequest(testAccount.Id);
    }

    static testMethod void testParseresponseBodyData() {
        String testResponse = '{"OutputParameters":{"P_RESPONSE":{"Row":[{"Column":[{"@name":"STATUS","$":"SUCCESS"},{"@name":"ORACLECUSTOMERNO","$":"CUST123"}]}]}}}';
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String result = CustomerUpsert_ToOracle.parseresponseBodyData(testResponse, testAccount.Id);
    }

    static testMethod void testSaveResponseData() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Map<Object, Object> testMap = new Map<Object, Object>{
            'BILL' => 'SITE123'
        };
        CustomerUpsert_ToOracle.saveResponseData(testMap, 'CUST123', testAccount.Id);
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"OutputParameters":{"P_RESPONSE":{"Row":[{"Column":[{"@name":"STATUS","$":"SUCCESS"},{"@name":"ORACLECUSTOMERNO","$":"CUST123"}]}]}}}');
            res.setStatusCode(200);
            return res;
        }
    }
}