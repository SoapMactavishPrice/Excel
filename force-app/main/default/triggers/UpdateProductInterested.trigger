trigger UpdateProductInterested on Product_Interested__c (after insert, after update, after delete) {
    Set<Id> leadIds = new Set<Id>();
    
    // Collect Lead IDs from trigger records
    if (Trigger.isInsert || Trigger.isUpdate) {
        for (Product_Interested__c pi : Trigger.new) {
            if (pi.Lead__c != null) {
                leadIds.add(pi.Lead__c);
            }
        }
    }
    
    if (Trigger.isDelete) {
        for (Product_Interested__c pi : Trigger.old) {
            if (pi.Lead__c != null) {
                leadIds.add(pi.Lead__c);
            }
        }
    }
    
    if (!leadIds.isEmpty()) {
        // Query all related ProductInterest records for affected Leads
        Map<Id, Lead> leadsToUpdate = new Map<Id, Lead>();
        
        // Query both Product_Interested__c records and their related Product__r names
        for (Lead l : [SELECT Id, 
                      (SELECT Product__c, Product__r.Name FROM Product_Interested__r ORDER BY CreatedDate) 
                      FROM Lead WHERE Id IN :leadIds]) {
            String productNames = '';
            Integer counter = 0;
            for (Product_Interested__c pi : l.Product_Interested__r) {
                if (pi.Product__c != null) {
                    counter++;
                    // Add line break and label (a, b, c, etc.)
                    // Use Product__r.Name to get the product name
                    productNames += '\n' + String.fromCharArray(new Integer[]{97 + counter - 1}) + '. ' + pi.Product__r.Name;
                }
            }
            
            // Trim any leading newline character
            if (!String.isEmpty(productNames)) {
                productNames = productNames.substring(1);
            }
            
            // Only update if changed
            if (l.Product_Interested__c != productNames) {
                l.Product_Interested__c = productNames;
                leadsToUpdate.put(l.Id, l);
            }
        }
        
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate.values();
        }
    }
}