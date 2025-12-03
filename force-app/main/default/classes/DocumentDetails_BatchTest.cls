@isTest
public class DocumentDetails_BatchTest {

    @testSetup
    static void setupData() {
        String uniqueUsername = 'testuser' + DateTime.now().getTime() + '@example.com';        
        User u = new User(
            FirstName = 'Test',
            LastName = 'User', // Required field
            Alias = 'testusr',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'testuser' + DateTime.now().getTime() + '@example.com'
        );
        insert u;

        // Create test Account
        Account acc = new Account(
            Name = 'Test Account',
            OwnerId = u.Id
        );
        insert acc;

        // Create Document_Detail__c records with matching Start and End Dates
        Date today = Date.today();
        Document_Detail__c doc1 = new Document_Detail__c(
            Name = 'Doc Start Reminder',
            Start_Date__c = today.addDays(15),
            End_Date__c = today.addDays(40), // Out of range
            Account__c = acc.Id
        );

        Document_Detail__c doc2 = new Document_Detail__c(
            Name = 'Doc End Reminder',
            Start_Date__c = today.addDays(5), // Out of range
            End_Date__c = today.addDays(30),
            Account__c = acc.Id
        );

        insert new List<Document_Detail__c>{doc1, doc2};
    }
    
    @isTest
    static void testBatchExecution() {
        // Get today's date
        Date today = Date.today();
        
        // Query the account and user (created in @testSetup if needed)
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Insert just one record to ensure only 1 execute call
        Document_Detail__c doc = new Document_Detail__c(
            Name = 'Doc Start Reminder',
            Start_Date__c = today.addDays(15), // Match logic
            End_Date__c = today.addDays(40),   // Out of range
            Account__c = acc.Id
        );
        insert doc;
        
        Test.startTest();
        // Set batch size to more than or equal to number of matching records (i.e., 1 here)
        DocumentDetails_Batch batch = new DocumentDetails_Batch();
        Database.executeBatch(batch, 200); // Batch size >= number of records
        Test.stopTest();
        
    }
    
}