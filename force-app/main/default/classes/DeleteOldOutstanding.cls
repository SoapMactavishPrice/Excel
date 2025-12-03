global class DeleteOldOutstanding implements Database.Batchable<SObject>, Schedulable {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Date todayDate = Date.today();
        Date yesterday = Date.today().addDays(-1);
        Date dayBeforeYesterday = Date.today().addDays(-2);

        return Database.getQueryLocator([
            SELECT Id
            FROM Outstanding__c
            WHERE DAY_ONLY(CreatedDate) < :dayBeforeYesterday
        ]);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        try {
            delete scope;
        } catch (DmlException e) {
            System.debug('Error deleting Outstanding records: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('DeleteOldOutstanding batch completed at ' + System.now());
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new DeleteOldOutstanding(), 200);
    }
}