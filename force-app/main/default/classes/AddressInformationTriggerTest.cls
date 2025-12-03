@isTest
public class AddressInformationTriggerTest {
    
    @testSetup
    static void setupData() {
        // Insert required Code_Master__c records first
        List<Code_Master__c> codeMasters = new List<Code_Master__c>{
            new Code_Master__c(
                Name = 'BillToCode',
                Code_For__c = 'Bill To',
                Current_Sequence__c = 1,
                Starting_Sequence__c = 1                
            ),
            new Code_Master__c(
                Name = 'ShipToCode',
                Code_For__c = 'Ship To',
                Current_Sequence__c = 1,
                Starting_Sequence__c = 1             
            )
        };
        insert codeMasters;
    }

    // Helper method to get RecordTypeId safely
    private static Id getRecordTypeId(String objectType, String developerName) {
        RecordType rt = [SELECT Id FROM RecordType 
                        WHERE SObjectType = :objectType 
                        AND DeveloperName = :developerName 
                        LIMIT 1];
        return rt.Id;
    }

    @isTest
    static void testBillToInsert() {
        Id billToRecordTypeId;
        try {
            billToRecordTypeId = getRecordTypeId('Address_Information__c', 'Bill_To');
        } catch (Exception e) {
        }

        Test.startTest();
        Address_Information__c billTo = new Address_Information__c(
            Name = 'Test BillTo',
            RecordTypeId = billToRecordTypeId
        );
        insert billTo;
        Test.stopTest();

        Address_Information__c result = [
            SELECT SF_Address_Code__c 
            FROM Address_Information__c 
            WHERE Id = :billTo.Id
        ];
       
    }

    @isTest
    static void testShipToInsert() {
        Id shipToRecordTypeId;
        try {
            shipToRecordTypeId = getRecordTypeId('Address_Information__c', 'Ship_To');
        } catch (Exception e) {
        }

        Test.startTest();
        Address_Information__c shipTo = new Address_Information__c(
            Name = 'Test ShipTo',
            RecordTypeId = shipToRecordTypeId
        );
        insert shipTo;
        Test.stopTest();

        Address_Information__c result = [
            SELECT SF_Address_Code__c 
            FROM Address_Information__c 
            WHERE Id = :shipTo.Id
        ];
        
    }

    @isTest
    static void testUpdateAddress() {
        Id billToRecordTypeId = getRecordTypeId('Address_Information__c', 'Bill_To');
        
        Address_Information__c addr = new Address_Information__c(
            Name = 'Test Address',
            RecordTypeId = billToRecordTypeId
        );
        insert addr;

        Test.startTest();
        addr.Name = 'Updated Address';
        update addr;
        Test.stopTest();

        Address_Information__c updated = [
            SELECT Name, SF_Address_Code__c 
            FROM Address_Information__c 
            WHERE Id = :addr.Id
        ];
        
    }

    @isTest
    static void testBulkInsert() {
        Id billToRecordTypeId = getRecordTypeId('Address_Information__c', 'Bill_To');
        Id shipToRecordTypeId = getRecordTypeId('Address_Information__c', 'Ship_To');
        
        List<Address_Information__c> addresses = new List<Address_Information__c>();
        for(Integer i = 0; i < 10; i++) {
            addresses.add(new Address_Information__c(
                Name = 'BillTo ' + i,
                RecordTypeId = billToRecordTypeId
            ));
            addresses.add(new Address_Information__c(
                Name = 'ShipTo ' + i,
                RecordTypeId = shipToRecordTypeId
            ));
        }

        Test.startTest();
        insert addresses;
        Test.stopTest();

        List<Address_Information__c> results = [
            SELECT SF_Address_Code__c, RecordType.DeveloperName 
            FROM Address_Information__c 
            WHERE Id IN :addresses
        ];
        
        for(Address_Information__c addr : results) {
            if(addr.RecordType.DeveloperName == 'Bill_To') {
            } else {
            }
        }
    }
}