@isTest
public class SendCustomertoOracleTest {

    @testSetup
    static void setupData() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Contact
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            MobilePhone = '1234567890',
            AccountId = acc.Id,
            LinkedIn_URL__c = 'https://linkedin.com/in/johndoe'
        );
        insert con;

        // Create related Location Records
        Country__c country = new Country__c(Name = 'USA');
        insert country;
        State__c state = new State__c(Name = 'California', Country__c = country.Id);
        insert state;
        City__c city = new City__c(Name = 'San Francisco', State__c = state.Id);
        insert city;
        Area__c area = new Area__c(Name = 'Downtown', City__c = city.Id);
        insert area;

        // Create Postal Code
        Postal_Code__c postal = new Postal_Code__c(
            Name = '94105',
            Area__c = area.Id,
            City__c = city.Id,
            State__c = state.Id,
            Country__c = country.Id
        );
        insert postal;

        // Create Record Types for Address_Information__c
        List<RecordType> recordTypes = new List<RecordType>{
            new RecordType(SObjectType = 'Address_Information__c', DeveloperName = 'Bill_To', Name = 'Bill To'),
            new RecordType(SObjectType = 'Address_Information__c', DeveloperName = 'Ship_To', Name = 'Ship To')
        };
      //  insert recordTypes;

        // Create Address Information with both required record types
        List<Address_Information__c> addressList = new List<Address_Information__c>();
        for (RecordType rt : recordTypes) {
            addressList.add(new Address_Information__c(
                Name = 'Address ' + rt.DeveloperName,
                Account__c = acc.Id,
              //  RecordTypeId = rt.Id,
                Postal_Code__c = postal.Id,
                Area__c = area.Id,
                City__c = city.Id,
                State__c = state.Id,
                Country__c = country.Id,
                Primary_Address__c = true
            ));
        }
        insert addressList;
    }

    @isTest
    static void testGetContactDetail() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        String result = SendCustomertoOracle.getContactDetail(acc.Id);
        Test.stopTest();
        
    }

    @isTest
    static void testGetAddInfoDetail() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        String result = SendCustomertoOracle.getAddInfoDetail(acc.Id);
        Test.stopTest();
        
    }

    @isTest
    static void testGetRecordTypeId() {
        Test.startTest();
        String recordTypeId = SendCustomertoOracle.getRecordTypeId('Bill_To');
        Test.stopTest();
    }

    @isTest
    static void testHasRequiredAddressInfo() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        Boolean result = SendCustomertoOracle.hasRequiredAddressInfo(acc.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetPinCodeDetails() {
        Postal_Code__c pin = [SELECT Id FROM Postal_Code__c LIMIT 1];
        Test.startTest();
        String result = SendCustomertoOracle.getPinCodeDetails(pin.Id);
        Test.stopTest();
       
    }
}