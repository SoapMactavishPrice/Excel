global class LeadStatusReminderBatch implements Database.Batchable<SObject>, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Name, Email, Owner.Email
            FROM Lead
            WHERE Id NOT IN (
                SELECT LeadId FROM LeadHistory
                WHERE Field = 'Status'
                AND CreatedDate >= :System.now().addDays(-15)
            )
            AND Status !='Qualified' AND Status !='Non-Qualified'
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='Expiry_Alert'];
        for (Lead lead : (List<Lead>)scope) {
            
            if (String.isNotBlank(lead.Owner.Email)) {
                
                Set<String> recipientsIds = new Set<String>();
                recipientsIds.add(lead.OwnerId);
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] {lead.Owner.Email});
                mail.setSubject('Reminder: Lead Status not changed for 15 days');
                mail.setPlainTextBody('Hi, the lead "' + lead.Name + '" has had no status change in over 15 days. Please review and follow up if needed.');
                emails.add(mail);
                
                
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle('Reminder: Lead Status not changed for 15 days');
                notification.setBody('Hi, the lead "' + lead.Name + '" has had no status change in over 15 days. Please review and follow up if needed.');
                notification.setTargetId(lead.Id);
                notification.setNotificationTypeId(notificationType.Id);
                notification.send(recipientsIds);
                
            }
        }
        
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        // Optional: Notify admin or log
    }
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new LeadStatusReminderBatch(), 50);
    }
}