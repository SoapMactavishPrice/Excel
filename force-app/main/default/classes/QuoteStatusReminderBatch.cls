global class QuoteStatusReminderBatch implements Database.Batchable<SObject>, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Date today = Date.today();
        Date startCheck = today.addDays(7);
        
        return Database.getQueryLocator([
            SELECT Id, Status, Owner.Email,OwnerId
            FROM Quote
            WHERE 
            Status !='Rejected' AND Status !='Approved' and ExpirationDate=:startCheck
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        // Fetch Custom Notification Type ID once
        Id notifyId = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Expiry_Alert' LIMIT 1].Id;
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        List<Messaging.CustomNotification> notifications = new List<Messaging.CustomNotification>();
        
        for (Quote qu : (List<Quote>)scope) {
            if (String.isNotBlank(qu.Owner.Email)) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { qu.Owner.Email });
                mail.setSubject('Reminder: Quote Expiry Reminder');
                
                
                String recordLink = baseUrl + '/' + qu.Id;
                String htmlBody = 
                    'Hi,<br/><br/>' +
                    'The Quote "<strong><a href="' + recordLink + '">' + qu.Name + '</a></strong>" is nearing its expiration date.<br/><br/>' +
                    'Please review and take necessary action to follow up or renew before it expires.<br/>' ;
                    mail.setHtmlBody(htmlBody);
                emails.add(mail);
            }
            
            // Create a Custom Notification for the quote owner
            
            
        }
        
        // Send emails
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
        
        // Send notifications
        if (!notifications.isEmpty()) {
            //Messaging.send(notifications);
        }
    }
    
    
    global void finish(Database.BatchableContext BC) {
        // Optional: Notify admin or log
    }
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new LeadStatusReminderBatch(), 50);
    }
}