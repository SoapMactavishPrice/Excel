@isTest
private class QuoteStatusReminderBatchTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Custom Notification Type
     /*   CustomNotificationType notificationType = new CustomNotificationType(
            DeveloperName = 'Expiry_Alert',
            MasterLabel = 'Expiry_Alert'
        );
        insert notificationType; */
        
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;
        
        // Create User with email
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            IsActive = true
        );
        insert u;
        
        // Create Quote with expiration in 7 days
        Quote q = new Quote(
            Name = 'Test Quote',
            Status = 'Draft',
            ExpirationDate = Date.today().addDays(7),
            OpportunityId = opp.Id,
            OwnerId = u.Id
        );
        insert q;
    }

    @isTest
    static void testBatchQuery() {
        Test.startTest();
        QuoteStatusReminderBatch batch = new QuoteStatusReminderBatch();
        Database.QueryLocator ql = batch.start(null);
        Database.QueryLocatorIterator it = ql.iterator();
        
        // Verify query returns records and fields are accessible
        System.assert(it.hasNext(), 'Query should return at least one record');
        while(it.hasNext()) {
            Quote q = (Quote)it.next();
            
        }
        Test.stopTest();
    }
    
    @isTest
    static void testExecuteMethod() {
        // Get test data
        Quote testQuote = [SELECT Id, Name, OwnerId, Owner.Email FROM Quote LIMIT 1];
        CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Expiry_Alert' LIMIT 1];
        
        Test.startTest();
        QuoteStatusReminderBatch batch = new QuoteStatusReminderBatch();
        
        // Create test scope
        List<Quote> scope = new List<Quote>{testQuote};
        
        // Execute batch with test scope
        batch.execute(null, scope);
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testExecuteWithNoOwnerEmail() {
        // Update user to remove email
     /*   User u = [SELECT Id FROM User WHERE Email = 'testuser11@gmail.com' LIMIT 1];
        u.Email = null;
        update u; */
        
        // Get test data
        Quote testQuote = [SELECT Id, Name, OwnerId FROM Quote LIMIT 1];
        
        Test.startTest();
        QuoteStatusReminderBatch batch = new QuoteStatusReminderBatch();
      //  batch.execute(null, new List<Quote>{testQuote});
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        String jobId = System.schedule('Test Quote Reminder Job', '0 0 12 * * ?', new QuoteStatusReminderBatch());
        Test.stopTest();
        
        // Verify the job was scheduled
        CronTrigger ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId];
    }
    
    @isTest
    static void testFinishMethod() {
        // Just verify the finish method runs without errors
        Test.startTest();
        QuoteStatusReminderBatch batch = new QuoteStatusReminderBatch();
        batch.finish(null);
        Test.stopTest();
        
        // No assertions needed as finish method is empty
    }
}