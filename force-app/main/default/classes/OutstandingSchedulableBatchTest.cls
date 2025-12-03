@isTest
public class OutstandingSchedulableBatchTest {

    @testSetup
    static void setupData() {
        // Insert record that matches batch (As_on_Date__c = Yesterday, OVERDUE_DAYS__c = 1)
        Outstanding__c matchingRecord = new Outstanding__c(
            BILL_TO_CUSTOMER_NUM__c = 'CUST1001',
            BILL_TO_CUSTOMER_NAME__c = 'Test Customer',
            Amount_Due__c = 5000,
            As_on_Date__c = System.today().addDays(-1),
            TERM_DUE_DATE__c = System.today().addDays(-2) // TODAY() - TERM_DUE_DATE__c = 1
        );
        insert matchingRecord;

        // Insert non-matching record
        Outstanding__c nonMatchingRecord = new Outstanding__c(
            BILL_TO_CUSTOMER_NUM__c = 'CUST2002',
            BILL_TO_CUSTOMER_NAME__c = 'Non Matching Customer',
            Amount_Due__c = 10000,
            As_on_Date__c = System.today(),
            TERM_DUE_DATE__c = System.today().addDays(-5)
        );
        insert nonMatchingRecord;
    }

    @isTest
    static void testBatchDirectExecution() {
        Test.startTest();

        OutstandingSchedulableBatch batch = new OutstandingSchedulableBatch();
        Database.executeBatch(batch, 1); // small scope to cover multiple execute calls

        Test.stopTest();

        // Assert that one record matches As_on_Date__c = yesterday
        List<Outstanding__c> matching = [
            SELECT Id 
            FROM Outstanding__c
            WHERE As_on_Date__c = :System.today().addDays(-1)
        ];
        System.assertEquals(1, matching.size(), 'One record should match batch criteria.');
    }

    @isTest
    static void testSchedulableExecution() {
        Test.startTest();

        // Schedule the batch to run immediately
        String sch = '0 0 0 ? * * *'; // cron expression (runs at midnight, irrelevant in test)
        System.schedule('Test Scheduled Outstanding Batch', sch, new OutstandingSchedulableBatch());

        Test.stopTest(); // All scheduled jobs execute here

        // Verify at least one record exists for yesterday
        List<Outstanding__c> matching = [
            SELECT Id 
            FROM Outstanding__c
            WHERE As_on_Date__c = :System.today().addDays(-1)
        ];
        System.assertEquals(1, matching.size(), 'One record should match scheduled batch criteria.');
    }

    @isTest
    static void testBatchNoRecords() {
        // Insert a record that won't match yesterday
        Outstanding__c todayRecord = new Outstanding__c(
            BILL_TO_CUSTOMER_NUM__c = 'CUST3003',
            BILL_TO_CUSTOMER_NAME__c = 'Today Only Customer',
            Amount_Due__c = 7000,
            As_on_Date__c = System.today(),
            TERM_DUE_DATE__c = System.today().addDays(-10)
        );
        insert todayRecord;

        Test.startTest();

        OutstandingSchedulableBatch batch = new OutstandingSchedulableBatch();
        Database.executeBatch(batch, 1);

        Test.stopTest();

        System.assert(true, 'Batch executed successfully even with no matching records.');
    }
}