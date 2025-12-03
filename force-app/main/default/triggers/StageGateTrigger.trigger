trigger StageGateTrigger on Stage_Gate__c (after insert,before Insert) {
    if(Trigger.isAfter && trigger.isInsert){
        StageGateTrigger.validateMileStone(Trigger.new,'Stage 1',false,'c__lwcStageGateScoreCaller','Ideation');
    }
    if(Trigger.isBefore && trigger.isInsert){
        StageGateTrigger.beforeMileStone(Trigger.new);
    }

}