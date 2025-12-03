trigger ProductInterestedTrigger on Product_Interested__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        ProductInterestedTriggerHandler.updateCurrency(Trigger.new);
    }
}