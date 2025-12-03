trigger SampleDispatchToTrigger on Sample_Dispatch_To__c  (before insert, before update, after insert, after update) {
    
      if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        SampleDispatchToHandler.updateAddressInformation(Trigger.new);
    }
    
}