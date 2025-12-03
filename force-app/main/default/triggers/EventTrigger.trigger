trigger EventTrigger on Event (after insert, after update) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        EventTriggerHandler.updateAddresses(Trigger.new, Trigger.isUpdate ? Trigger.oldMap : null);
    }
}