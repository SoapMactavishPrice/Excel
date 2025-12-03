trigger SampleBookingTrigger on Sample_Booking__c (before insert, before update, after insert, after update)  {
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            //SampleBookingTriggerHandler.populateRequestedBy(Trigger.new);
            SampleBookingTriggerHandler.handleBeforeInsertUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            SampleBookingTriggerHandler.handleAfterInsertUpdate(Trigger.new);
            
            if (Trigger.isInsert) {
                SampleBookingTriggerHandler.updateCurrency(Trigger.new);
            }
        }
    }
    
}