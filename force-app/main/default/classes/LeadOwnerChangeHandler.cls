public class LeadOwnerChangeHandler {
    public static void sendOwnerChangeEmail(List<Lead> newList, Map<Id, Lead> oldMap) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Set<Id> ownerIds = new Set<Id>();

        for (Lead newLead : newList) {
            Lead oldLead = oldMap.get(newLead.Id);
            if (newLead.OwnerId != oldLead.OwnerId && String.valueOf(newLead.OwnerId).startsWith('005')) {
                ownerIds.add(newLead.OwnerId);
            }
        }

        Map<Id, User> userMap = new Map<Id, User>([
            SELECT Id, Name, Email FROM User WHERE Id IN :ownerIds
        ]);

        for (Lead newLead : newList) {
            Lead oldLead = oldMap.get(newLead.Id);

            if (newLead.OwnerId != oldLead.OwnerId && userMap.containsKey(newLead.OwnerId)) {
                User newOwner = userMap.get(newLead.OwnerId);

                // Build HTML email body
                String emailBody = ''
                    + '<html><body>'
                    + '<p>Dear ' + newOwner.Name + ',</p>'
                    + '<p>You have been assigned a new Lead. Please find the details below:</p>'
                    + '  <table border="1" cellpadding="5" cellspacing="0" style="border-collapse:collapse;">'
                    + '    <tr style="background-color:#f2f2f2;">'
                    + '      <th>Lead No</th>'
                    + '      <th>Lead Name</th>'
                    + '      <th>Email</th>'
                    + '      <th>Company</th>'
                    + '      <th>Department</th>'
                    + '      <th>Lead Type</th>'
                    + '    </tr>'
                    + '    <tr>'
                    + '      <td>' + newLead.Lead_No__c + '</td>'
                    + '      <td>' + newLead.FirstName + ' ' + newLead.LastName + '</td>'
                    + '      <td>' + newLead.Email + '</td>'
                    + '      <td>' + newLead.Company + '</td>'
                    + '      <td>' + (newLead.Department__c != null ? newLead.Department__c : '') + '</td>'
                    + '      <td>' + newLead.Lead_Type__c + '</td>'
                    + '    </tr>'
                    + '  </table>'

                    + '<p>You can <a href="https://ability-nosoftware-4859--devorg.sandbox.lightning.force.com/' + newLead.Id + '">click here</a> to view the Lead in Salesforce.</p>'
                    + '</body></html>';

                // Send HTML email
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { newOwner.Email });
                mail.setSubject('New Lead Assigned: ' + newLead.FirstName);
                mail.setHtmlBody(emailBody);
                emails.add(mail);
            }
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}