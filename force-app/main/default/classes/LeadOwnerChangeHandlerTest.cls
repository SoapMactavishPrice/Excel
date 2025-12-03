@isTest
public class LeadOwnerChangeHandlerTest {
    @testSetup
    static void setupTestData() {
        // Create a test user to assign as new owner
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // Create a Lead with a different initial owner
        Lead lead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'Test Company',
            Email = 'john.doe@example.com',
            //Lead_No__c = 'LD001',
            Department__c = 'Sales',
            Lead_Type__c = 'Domestic',
            Zone__c = 'East',
            OwnerId = UserInfo.getUserId() // Initially assign to current user
        );
        insert lead;
    }

    @isTest
    static void testSendOwnerChangeEmail() {
        // Fetch the test user
        User testUser = [SELECT Id, Name, Email FROM User WHERE Email = 'testuser@example.com' LIMIT 1];

        // Fetch the inserted lead
        Lead lead = [SELECT Id, FirstName, LastName, Company, Email, Lead_No__c, Department__c, Lead_Type__c, OwnerId FROM Lead LIMIT 1];

        // Simulate old map before owner change
        Map<Id, Lead> oldMap = new Map<Id, Lead>();
        oldMap.put(lead.Id, lead);

        // Change the lead owner
        lead.OwnerId = testUser.Id;
        update lead;

        // Simulate new list after update
        List<Lead> updatedLeads = [SELECT Id, FirstName, LastName, Company, Email, Lead_No__c, Department__c, Lead_Type__c, OwnerId FROM Lead WHERE Id = :lead.Id];

        Test.startTest();
        LeadOwnerChangeHandler.sendOwnerChangeEmail(updatedLeads, oldMap);
        Test.stopTest();

        // No exceptions should occur; you can check debug logs or use mock class for email in production
        System.debug('Email should have been sent to: ' + testUser.Email);
    }
}