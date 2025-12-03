global class DeleteOldFailedApiLogsBatch implements Database.Batchable<SObject>, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Date fifteenDaysAgo = Date.today().addDays(-15);
        return Database.getQueryLocator([
            SELECT Id,Log_Status__c
            FROM API_Log__c
            WHERE CreatedDate <= :fifteenDaysAgo
            AND (Log_Status__c = 'Failure')
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        try {
            delete scope;
        } catch (DmlException e) {
            System.debug('Error deleting failed logs: ' + e.getMessage());
            // Optional: Add logging or error capture here
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        System.debug('DeleteOldFailedApiLogsBatch completed at ' + System.now());
    }
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new DeleteOldFailedApiLogsBatch(), 200);
    }
}