trigger QuoteLineItemTrigger on QuoteLineItem  (before update,after update) {
	if (Trigger.isBefore) {
        if (Trigger.isUpdate) {
            QuoteLineItemTriggerHandler.storeOldValues(Trigger.oldMap);
        }
    }
    
    
    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            QuoteLineItemTriggerHandler.updatePreviousValues(Trigger.newMap);
        }
    }
}