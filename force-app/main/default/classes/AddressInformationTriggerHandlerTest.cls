@isTest
public class AddressInformationTriggerHandlerTest {
    @isTest
    static void testHandleCopyBillToShipTo() {
        // Step 1: Query the existing RecordType for 'Ship_To'
        Id shipToRecordTypeId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Address_Information__c' AND DeveloperName = 'Ship_To'
            LIMIT 1
        ].Id;

        // Step 2: Create a sample 'Bill To' address record
       
           Country__c testCountry = new Country__c(Name = 'India');
        insert testCountry;
        
        State__c testState = new State__c(Name = 'Test State', Country__c = testCountry.Id);
        insert testState;
        
        City__c testCity = new City__c(Name = 'Test City', State__c = testState.Id, Country__c = testCountry.Id);
        insert testCity;
        
        Area__c testArea = new Area__c(Name = 'Test Area', City__c = testCity.Id, State__c = testState.Id, Country__c = testCountry.Id);
        insert testArea;
        
        Postal_Code__c testPostalCode = new Postal_Code__c(Name = '12345', Area__c = testArea.Id, City__c = testCity.Id, State__c = testState.Id, Country__c = testCountry.Id);
        insert testPostalCode;
        
         Account testAccount = new Account(
            Name = 'Finesse'
        );
        insert testAccount;

        Address_Information__c billToAddress = new Address_Information__c(
            Name = 'Test Bill To Address',
            Account__c = testAccount.Id,
            City__c = testCity.Id,
            Postal_Code__c = testPostalCode.Id,
            State__c = testState.Id,
            Address_Code__c = 'BILL123',
            Country__c = testCountry.Id,
            GSTIN_no__c = '1234GSTIN5678',
            Contact_phone_no__c = '1234567890',
            Contact_email_ID__c = 'test@example.com',
            Copy_Bill_To_to_Ship_To__c = true // Indicate this needs to be copied
        );
        insert billToAddress;

              // Step 3: Clear any pre-existing Ship_To records for isolation
        List<Address_Information__c> preExistingShipToRecords = [
            SELECT Id FROM Address_Information__c WHERE RecordTypeId = :shipToRecordTypeId
        ];
        if (!preExistingShipToRecords.isEmpty()) {
            delete preExistingShipToRecords;
        }

        // Step 4: Invoke the handler within the test context
        Test.startTest();
        List<Address_Information__c> addressList = [SELECT Id, Name, Account__c, City__c, Postal_Code__c, State__c, Address_Code__c, 
                                                    Country__c, GSTIN_no__c, Contact_phone_no__c, Contact_email_ID__c, 
                                                    Copy_Bill_To_to_Ship_To__c 
                                                     FROM Address_Information__c
                                                    WHERE Id = :billToAddress.Id];
        AddressInformationTriggerHandler.handleCopyBillToShipTo(addressList);
        Test.stopTest();

        // Step 4: Validate that a 'Ship To' record was created
        List<Address_Information__c> shipToAddresses = [
            SELECT Id, Name, RecordTypeId, Account__c, City__c, Postal_Code__c, State__c, Address_Code__c, Country__c, GSTIN_no__c,
                   Contact_phone_no__c, Contact_email_ID__c
            FROM Address_Information__c
            WHERE RecordTypeId = :shipToRecordTypeId AND Account__c = :testAccount.Id
        ];

       
        Address_Information__c shipTo = shipToAddresses[0];
       
    }
}