trigger SampleLineItemTrigger on Sample_Line_Item__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        SampleLineItemTriggerHandler.updateCurrency(Trigger.new);
    }
}