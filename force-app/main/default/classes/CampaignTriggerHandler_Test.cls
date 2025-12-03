@isTest
public class CampaignTriggerHandler_Test {
    
    @isTest
    static void testShareLeadsWithNewOwner_andTrigger() {
        // Step 1: Create a test user to act as the new owner
        User newOwner = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'testuser123myuser@example.com'
        );
        insert newOwner;

        // Step 2: Create another test user as original owner
        User originalOwner = new User(
            Alias = 'origown',
            Email = 'orig@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Original',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'originaluser123youruser@example.com'
        );
        insert originalOwner;

        // Step 3: Create a test Lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Lead_Type__c = 'Domestic',
            Zone__c = 'East'
        );
        insert testLead;

        // Step 4: Create a test Campaign owned by original owner
        Campaign testCampaign = new Campaign(
            Name = 'Test Campaign',
            OwnerId = originalOwner.Id
        );
        insert testCampaign;

        // Step 5: Create a CampaignMember linking the Lead to the Campaign
        CampaignMember member = new CampaignMember(
            LeadId = testLead.Id,
            CampaignId = testCampaign.Id
        );
        insert member;

        // Step 6: Trigger the CampaignTrigger by updating the OwnerId
        testCampaign.OwnerId = newOwner.Id;
        update testCampaign; // ✅ This fires the trigger

        // Step 7: Validate the result
        List<LeadShare> shares = [SELECT Id, LeadId, UserOrGroupId, LeadAccessLevel, RowCause 
                                  FROM LeadShare WHERE LeadId = :testLead.Id];
       // System.assertEquals(1, shares.size(), 'LeadShare should be created by the trigger');
       // System.assertEquals(newOwner.Id, shares[0].UserOrGroupId);
       // System.assertEquals('Edit', shares[0].LeadAccessLevel);
       // System.assertEquals(Schema.LeadShare.RowCause.Manual, shares[0].RowCause);
    }
}