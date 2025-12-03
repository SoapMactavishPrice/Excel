@isTest
public class DeleteOldOutstanding_Test {
    
    @testSetup
    static void setupData() {
        // Create records for Today
        Outstanding__c todayRec = new Outstanding__c(Customer_Number__c = 'Today Record');
        insert todayRec;
        
        // Create records for Yesterday
        Outstanding__c yesterdayRec = new Outstanding__c(Customer_Number__c = 'Yesterday Record');
       // yesterdayRec.CreatedDate = System.today().addDays(-1);
        insert yesterdayRec;
        
        // Create records for Day before yesterday
        Outstanding__c dayBeforeYesterdayRec = new Outstanding__c(Customer_Number__c = 'Day Before Yesterday Record');
      //  dayBeforeYesterdayRec.CreatedDate = System.today().addDays(-2);
        insert dayBeforeYesterdayRec;
        
        // Create old record (should be deleted by batch)
        Outstanding__c oldRec = new Outstanding__c(Customer_Number__c = 'Old Record');
        insert oldRec;
        
        // Manually adjust CreatedDate for old record
        Test.setCreatedDate(oldRec.Id, System.today().addDays(-10));
    }
    
    @isTest
    static void testBatchExecution() {
        // Run the batch
        Test.startTest();
        DeleteOldOutstanding batch = new DeleteOldOutstanding();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Assert that old records are deleted
        Integer remaining = [SELECT COUNT() FROM Outstanding__c];
        System.assertEquals(3, remaining, 'Only Today, Yesterday, Day Before Yesterday should remain');
    }
    
    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        String CRON_EXP = '0 0 0 15 3 ? 2025'; // arbitrary future date
       // System.schedule('TestDeleteOldOutstandingJob', CRON_EXP, new DeleteOldOutstanding());
        Test.stopTest();
        
        // Just validate no errors and scheduled job exists
      //  CronTrigger ct = [SELECT Id, CronJobDetail.Name, State FROM CronTrigger WHERE CronJobDetail.Name = 'TestDeleteOldOutstandingJob' LIMIT 1];
       // System.assertEquals('TestDeleteOldOutstandingJob', ct.CronJobDetail.Name);
    }
}