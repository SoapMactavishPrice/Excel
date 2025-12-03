global class DocumentDetails_Batch implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Date today = Date.today();
        Date startCheck = today.addDays(15);
        Date endCheck = today.addDays(30);
        
        String query = 'SELECT Id, Name, Start_Date__c, End_Date__c, Account__c,OwnerId, ' +
            'Account__r.Id, Account__r.Name, Account__r.OwnerId,Account__r.Owner.Email ' +
            'FROM Document_Detail__c ' +
            'WHERE Start_Date__c = :startCheck OR End_Date__c = :endCheck';
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='Expiry_Alert'];
        Date today = Date.today();
        Date startTrigger = today.addDays(15);
        Date endTrigger = today.addDays(30);
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        
        for (Document_Detail__c doc : (List<Document_Detail__c>)scope) {
            if (doc.Account__r != null && doc.Account__r.OwnerId != null) {
                String reason = '';
                if (doc.Start_Date__c == startTrigger) {
                    reason = 'Start Date: ' + String.valueOf(doc.Start_Date__c);
                } else if (doc.End_Date__c == endTrigger) {
                    reason = 'End Date: ' + String.valueOf(doc.End_Date__c);
                } 
                
                // Generate record URL
                String recordLink = baseUrl + '/' + doc.Id;
                Set<String> recipientsIds = new Set<String>();
                recipientsIds.add(doc.OwnerId);
                // Create the HTML Body with clickable document name
                String emailBody = '<html><body>' +
                    '<p>Hello,</p>' +
                    '<p>This is a reminder that the document <a href="' + recordLink + '">' + doc.Name + '</a> ' +
                    'linked to the account <strong>' + doc.Account__r.Name + '</strong> is nearing an important date.</p>' +
                    '<p>' + reason + '</p>' +
                    //'<p>You can view the document here: <a href="' + recordLink + '">' + recordLink + '</a></p>' +
                    '<p>Thank you.</p>' +
                    '</body></html>';
                
                // Create Email Message
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTargetObjectId(doc.Account__r.OwnerId);
                mail.setSubject('Reminder: Document "' + doc.Name + '" is Approaching');
                mail.setHtmlBody(emailBody);  // Use HTML body
                mail.setToAddresses(new List<string>{doc.Account__r.Owner.Email});
                //mail.setToAddresses(new List<string>{'Rishikesh.Korade@finessedirect.com','Pushkar@finessedirect.com'});
                
                
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle('Reminder: Lead Status not changed for 15 days');
                notification.setBody('This is a reminder that the document  "' + doc.Name + '" linked to the account  '+ doc.Account__r.Name + ' is nearing an important date. '+reason);
                notification.setTargetId(doc.Id);
                notification.setNotificationTypeId(notificationType.Id);
                notification.send(recipientsIds);
                
                mail.setSaveAsActivity(false);
                
                emailsToSend.add(mail);
            }
        }
        
        // Send all emails
        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
    }
    
    
    
    global void finish(Database.BatchableContext BC) {
        // Optional: Notify admin or log completion
    }
    
    /*private Id getNotificationTypeId(String developerName) {
List<NotificationType> types = [
SELECT Id FROM NotificationType WHERE DeveloperName = :developerName LIMIT 1
];
if (types.isEmpty()) {
throw new CustomException('Custom Notification Type "' + developerName + '" not found.');
}
return types[0].Id;
}*/
    
    public class CustomException extends Exception {}
}