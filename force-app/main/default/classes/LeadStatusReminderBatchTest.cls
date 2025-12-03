@isTest
private class LeadStatusReminderBatchTest {

    @testSetup
    static void setupData() {
        // Create a test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create Country
        Country__c country = new Country__c(Name='TestCountry');
        insert country;
        
        // Create State with proper Country reference and ensure all required fields are filled
        State__c state = new State__c(Name='TestState', Country__c=country.Id, Zone__c='East');
        insert state;
        
        // Create City (no postal code since it's removed)
        City__c city = new City__c(Name='TestCity');
        insert city;
        
        // Create Postal Code with proper State reference
        Postal_Code__c postal = new Postal_Code__c(Name='123456', State__c=state.Id);
        insert postal;
        
        // Create a user to assign as Lead Owner (assuming this is the 'leadOwner' from your code)
        User leadOwner = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Owner',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser@example.com.' + System.currentTimeMillis()
        );
        insert leadOwner;
        
        // Lead that hasn't changed status in 15+ days
        Lead inactiveLead = new Lead(
            LastName = 'Inactive Lead',
            Company = 'Test Company',
            Email = 'lead@example.com',
            Status = 'Open - Not Contacted',
            OwnerId = leadOwner.Id,
            City__c = city.Id,          
            State__c = state.Id,       
            Country__c = country.Id,    
            Postal_Code__c = postal.Id,
            Lead_Type__c = 'Domestic',
            Zone__c = 'East'
        );
        insert inactiveLead;
        
        // Lead with recent status change
        Lead recentLead = new Lead(
            LastName = 'Recent Lead',
            Company = 'Test Company',
            Lead_Type__c='Domestic',
            City__c = city.Id,          
            State__c = state.Id,       
            Country__c = country.Id,    
            Postal_Code__c = postal.Id,
            Email = 'lead2@example.com',
            Status = 'Open - Not Contacted',
            OwnerId = leadOwner.Id,
            Zone__c='East'
        );
        insert recentLead;
        
        // Simulate a status change within 15 days for recent lead
       LeadStatus ls = [SELECT MasterLabel FROM LeadStatus LIMIT 1];
       recentLead.Status = ls.MasterLabel;
      // update recentLead; 
    }
    

    @isTest
    static void testScheduledExecution() {
        Test.startTest();
        LeadStatusReminderBatch batch = new LeadStatusReminderBatch();
        // Schedule the batch execution only here
        String jobId = System.schedule('TestLeadStatusReminderBatch', '0 0 12 * * ?', batch);
        Test.stopTest();
    }
}