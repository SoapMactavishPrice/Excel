trigger LeadOwnerChangeTrigger on Lead (after update) {
    LeadOwnerChangeHandler.sendOwnerChangeEmail(Trigger.new, Trigger.oldMap);
}