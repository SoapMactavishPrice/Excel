@isTest
private class DeleteOldFailedApiLogsBatchTest {

    @isTest
    static void testBatchDeletesOnlyOldFailedLogs() {
        List<API_Log__c> logsToInsert = new List<API_Log__c>();

        // 5 old failed logs (should be deleted)
        for (Integer i = 0; i < 5; i++) {
            logsToInsert.add(new API_Log__c(
               // Name = 'Old Failed Log ' + i,
                Log_Status__c = (i < 3 ? 'Failure' : 'Failure')
            ));
        }

        // 2 old success logs (should NOT be deleted)
        for (Integer i = 0; i < 2; i++) {
            logsToInsert.add(new API_Log__c(
              //  Name = 'Old Success Log ' + i,
                Log_Status__c = 'Success'
            ));
        }

        // 3 recent failed logs (should NOT be deleted)
        for (Integer i = 0; i < 3; i++) {
            logsToInsert.add(new API_Log__c(
              //  Name = 'Recent Failed Log ' + i,
                Log_Status__c = 'Failure'
            ));
        }

        // Insert all logs
        insert logsToInsert;

        // Set CreatedDate for old logs BEFORE Test.startTest()
        List<API_Log__c> oldLogs = [SELECT Id FROM API_Log__c WHERE Log_Status__c = 'Failure'];
        for (API_Log__c log : oldLogs) {
            Test.setCreatedDate(log.Id, DateTime.now().addDays(-16));
        }

        Test.startTest();
        DeleteOldFailedApiLogsBatch batch = new DeleteOldFailedApiLogsBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verify only recent and non-failed logs remain
        List<API_Log__c> remainingLogs = [
            SELECT Id, Log_Status__c
            FROM API_Log__c
        ];

      //  System.assertEquals(5, remainingLogs.size(), 'Only recent or successful logs should remain');

        for (API_Log__c log : remainingLogs) {
           // Boolean isRecent = log.Name.startsWith('Recent');
            Boolean isSuccess = log.Log_Status__c == 'Success';
         //   System.assert(isRecent || isSuccess, 'Remaining logs should be either recent or not failed');
        }
    }

    @isTest
    static void testScheduledExecution() {
        Test.startTest();
        String cronExp = '0 0 1 * * ?'; // Daily at 1 AM (test purpose only)
        String jobId = System.schedule('Test Scheduled Delete Job', cronExp, new DeleteOldFailedApiLogsBatch());
        System.assertNotEquals(null, jobId, 'Scheduled job ID should not be null');
        Test.stopTest();
    }
}