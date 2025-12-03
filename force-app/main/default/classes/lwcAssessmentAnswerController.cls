public class lwcAssessmentAnswerController {
    
    @auraEnabled(Cacheable = true)
    public static List<Assessment_Answer__c> isFetchdata(Id recordId){
        return [Select Id,Name from Assessment_Answer__c where Assessment_Master__c = :recordId];    
    }
    
    
    @AuraEnabled
    public static Map<string,string> saveAnswer(Id Id, string JS){
        List<Object> objList = (List<Object>)JSON.deserializeUntyped(JS);
        Map<string,string> result = new Map<string,string>();
        try{
        List<Assessment_Answer__c> aaList = new List<Assessment_Answer__c>();
        for(Object obj : objList){
            map<string,object> objMap = (map<string,object>)obj;
            Assessment_Answer__c aa = new Assessment_Answer__c();
            aa.Assessment_Master__c = Id;
            aa.Name = (string)objMap.get('Assessment_Score');
            aa.Assessment_Answer__c = (string)objMap.get('Assessment_Answer');
            aaList.add(aa); 
        }
        
        if(aaList.size() > 0)
            insert aaList;
            result.put('message','success');
        }catch(exception e){
            result.put('message',e.getMessage());
        }
        
        return result;
        
    }
    
    
    
}