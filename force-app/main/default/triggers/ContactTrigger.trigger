trigger ContactTrigger on Contact (before insert, before update, after insert, after update) {
    
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        ContactTriggerHandler.updateContactAddresses(Trigger.new);
    }
    
}