public class MilestoneTriggerHandler {
    
    public static void milestoneUpdateonStage(List<Milestone__c> newRecords){
        Map<Id,Id> mileMap = new Map<Id,Id>();
        for(Milestone__c mile : newRecords) {
            mileMap.put(mile.Stage_Gate__c,mile.Milestone__c);
        }
        
        if(mileMap.size() > 0){
            
        }
    }
}