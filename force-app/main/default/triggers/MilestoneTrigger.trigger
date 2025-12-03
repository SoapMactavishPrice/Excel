trigger MilestoneTrigger on Milestone__c (after insert) {
    if(trigger.isAfter && trigger.isInsert){
        MilestoneTriggerHandler.milestoneUpdateonStage(trigger.new);
    }
}