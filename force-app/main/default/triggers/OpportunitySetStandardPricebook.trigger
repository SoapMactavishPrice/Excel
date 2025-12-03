trigger OpportunitySetStandardPricebook on Opportunity (before insert,before update) {
    
    List<Pricebook2> standardPBList = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
    if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
        if (!standardPBList.isEmpty()) {
            Id standardPBId = standardPBList[0].Id; // Get the Pricebook Id
            
            for (Opportunity opp : Trigger.new) {
                if (opp.Pricebook2Id == null) {
                    opp.Pricebook2Id = standardPBId; // Assign Standard Pricebook
                }
            }
        } else {
            System.debug('No Standard Pricebook found. Skipping assignment.');
        }
    }
}