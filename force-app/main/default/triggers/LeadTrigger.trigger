trigger LeadTrigger on Lead  (before insert, before update, after insert, after update) {
    
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        LeadTriggerHandler.updateLeadAddresses(Trigger.new);            
    }
    
    if(trigger.isBefore && Trigger.isUpdate){
        LeadTriggerHandler.validateData(Trigger.new, Trigger.oldMap);
    }
    
    if (Trigger.isBefore && Trigger.isUpdate) {
        LeadTriggerHandler.validateActivityForStatusChange(Trigger.new, Trigger.oldMap);
    }
    
    if(Trigger.isAfter && Trigger.isUpdate) {
        LeadTriggerHandler.handleLeadConversion(Trigger.new, Trigger.oldMap);
        LeadTriggerHandler.handleProductIntrestedConversion(Trigger.new, Trigger.oldMap);
        LeadTriggerHandler.handleSampleBookingConversion(Trigger.new, Trigger.oldMap);
        OptyTriggerHandler.convertHandler(trigger.New,Trigger.oldMap);
    }
}