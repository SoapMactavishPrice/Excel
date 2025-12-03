trigger RestrictClosedLostWithoutFile on Opportunity (before update) {
    Set<Id> oppIdsToCheck = new Set<Id>();
    
    for (Opportunity opp : Trigger.new) {
        Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
        
        // If Stage is being updated to 'Closed Lost'
        if (opp.StageName == 'Closed Lost' && oldOpp.StageName != 'Closed Lost') {
            oppIdsToCheck.add(opp.Id);
        }
    }
    
    if (!oppIdsToCheck.isEmpty()) {
        // Map to hold Opportunity Ids with attachments
        Set<Id> oppsWithFiles = new Set<Id>();
        
        // Query for files attached to the opportunities
        for (ContentDocumentLink cdl : [
            SELECT LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :oppIdsToCheck
        ]) {
            oppsWithFiles.add(cdl.LinkedEntityId);
        }
        
        // Prevent update if no files are found
        for (Opportunity opp : Trigger.new) {
            if (opp.StageName == 'Closed Lost' &&
                !oppsWithFiles.contains(opp.Id)) {
                    opp.addError('You must upload at least one file before setting the Opportunity as Closed Lost.');
                }
        }
    }
}