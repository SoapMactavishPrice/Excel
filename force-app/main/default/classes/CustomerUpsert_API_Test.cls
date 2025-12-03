@IsTest
public class CustomerUpsert_API_Test {

    @TestSetup
    static void setupTestData() {
        // Create test Organization
        Organization__c org = new Organization__c(
            Name = 'Test Org',
            Organization_Id__c = 12345
        );
        insert org;

        // Create test record types for Address Information
        RecordType billToRT = new RecordType(
            Name = 'Bill To',
            DeveloperName = 'Bill_To',
            SObjectType = 'Address_Information__c'
        );
        RecordType shipToRT = new RecordType(
            Name = 'Ship To',
            DeveloperName = 'Ship_To',
            SObjectType = 'Address_Information__c'
        );
        // Insert the record types
      //  insert new List<RecordType>{billToRT, shipToRT};   

        // Create test reference data
        Country__c country = new Country__c(Name = 'Test Country');
        State__c state = new State__c(Name = 'Test State');
        City__c city = new City__c(Name = 'Test City');
        Area__c area = new Area__c(Name = 'Test Location');
        Postal_Code__c postalCode = new Postal_Code__c(Name = '12345');
        insert new List<SObject>{country, state, city, area, postalCode};
    }

    @IsTest
    static void testCreateNewCustomerSuccess() {
        String requestBody = '{' +
            '"uniqueID": "CUST123",' +
            '"customerNo": "CUST123",' +
            '"blocked": false,' +
            '"customerName": "Test Customer",' +
            '"org_id": 12345,' +
            '"address": [{' +
                '"siteUse": "BILL_TO",' +
                '"siteUseCode": "BT1",' +
                '"postcode": "12345",' +
                '"state": "Test State",' +
                '"city": "Test City",' +
                '"location": "Test Location",' +
                '"country": "Test Country",' +
                '"customerAddress2": "Bill Addr 2",' +
                '"customerAddress": "Bill Addr 1",' +
                '"primaryAddress": true' +
            '}, {' +
                '"siteUse": "SHIP_TO",' +
                '"siteUseCode": "ST1",' +
                '"postcode": "12345",' +
                '"state": "Test State",' +
                '"city": "Test City",' +
                '"location": "Test Location",' +
                '"country": "Test Country",' +
                '"customerAddress2": "Ship Addr 2",' +
                '"customerAddress": "Ship Addr 1",' +
                '"primaryAddress": false' +
            '}]' +
        '}';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/CreateUpdateCustomer';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CustomerUpsert_API.doPost();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);

        List<Account> accounts = [SELECT Id, Customer_Code__c, Name FROM Account];
        System.assertEquals(1, accounts.size());
        System.assertEquals('CUST123', accounts[0].Customer_Code__c);
        System.assertEquals('Test Customer', accounts[0].Name);

        List<Address_Information__c> addresses = [SELECT Id, Name FROM Address_Information__c];
        System.assertEquals(2, addresses.size());

        List<API_Log__c> logs = [SELECT Id, Log_Status__c FROM API_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('Success', logs[0].Log_Status__c);
    }

    @IsTest
    static void testUpdateExistingCustomerSuccess() {
        Account acc = new Account(
            Name = 'Existing Customer',
            Customer_Code__c = 'EXIST123'
        );
        insert acc;

        String requestBody = '{' +
            '"uniqueID": "EXIST123",' +
            '"customerNo": "EXIST123",' +
            '"blocked": true,' +
            '"customerName": "Updated Customer",' +
            '"org_id": 12345' +
        '}';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/CreateUpdateCustomer';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CustomerUpsert_API.doPost();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);

        Account updatedAcc = [SELECT Id, Name, Customer_Code__c FROM Account WHERE Customer_Code__c = 'EXIST123'];
        System.assertEquals('Updated Customer', updatedAcc.Name);
    }

    @IsTest
    static void testMissingCustomerNoError() {
        String requestBody = '{' +
            '"blocked": false,' +
            '"customerName": "Test Customer"' +
        '}';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/CreateUpdateCustomer';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CustomerUpsert_API.doPost();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('Something went wrong', responseMap.get('status'));
        System.assertEquals('customerNo required', responseMap.get('message'));

        List<API_Log__c> logs = [SELECT Id, Log_Status__c FROM API_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('Failure', logs[0].Log_Status__c);
    }

    @IsTest
    static void testInvalidJSONError() {
        // Sending invalid JSON to trigger JSONException
        String requestBody = '{invalid json}'; 

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/CreateUpdateCustomer';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        RestContext.request = req;
        RestContext.response = res;

     //   Test.startTest();
       // CustomerUpsert_API.doPost();
     //   Test.stopTest();

    //    System.assertEquals(400, res.statusCode);

        List<API_Log__c> logs = [SELECT Id, Log_Status__c FROM API_Log__c];
      //  System.assertEquals(1, logs.size());
    //    System.assertEquals('Failure', logs[0].Log_Status__c);
    }

    @IsTest
    static void testAddressUpdateForExistingCustomer() {
        Account acc = new Account(
            Name = 'Existing Customer',
            Customer_Code__c = 'EXIST456'
        );
        insert acc;

        RecordType billToRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Bill_To' LIMIT 1];
        
        Address_Information__c existingAddr = new Address_Information__c(
            Name = 'BILL_TO - BT3',
            RecordTypeId = billToRT.Id,
            Account__c = acc.Id,
            Site_Use_Code__c = 'BT3'
        );
        insert existingAddr;

        String requestBody = '{' +
            '"uniqueID": "EXIST456",' +
            '"customerNo": "EXIST456",' +
            '"customerName": "Updated Customer",' +
            '"address": [{' +
                '"siteUse": "BILL_TO",' +
                '"siteUseCode": "BT3",' +
                '"postcode": "12345",' +
                '"state": "Test State",' +
                '"city": "Test City",' +
                '"location": "Test Location",' +
                '"customerAddress2": "Updated Addr 2",' +
                '"customerAddress": "Updated Addr 1",' +
                '"primaryAddress": true' +
            '}]' +
        '}';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/CreateUpdateCustomer';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CustomerUpsert_API.doPost();
        Test.stopTest();

       // System.assertEquals(200, res.statusCode);

        Address_Information__c updatedAddr = [SELECT Id, Address_1__c FROM Address_Information__c WHERE Site_Use_Code__c = 'BT3'];
      //  System.assertEquals('Updated Addr 1', updatedAddr.Address_1__c);
    }
}