public class Lwc_AddTeamMemberController {
    @AuraEnabled
    public static Map<string, string>  save(Id mileId,string JS ){
        Map<string, string>  result = new Map<string, string>();
        system.debug('mileId'+mileId);
        system.debug('JS'+JS);
        try {
        List<Object> objList = (List<Object>)JSON.deserializeUntyped(JS);
        List<Team_Member__c> tlList = new List<Team_Member__c>();
            
            
        
        for(Object obj :objList ){
            Map<string,object> objMap =(Map<string,object>)obj; 
            Team_Member__c tmc = new Team_Member__c();
            tmc.Milestone__c = mileId;
            tmc.User__c = (Id)objMap.get('name');
            tmc.Team_Member_Role__c = (string)objMap.get('userRole');
            tlList.add(tmc);
        }
        
        if(tlList.size() > 0)
            insert tlList;
            
         result.put('Message','success');
            
            
        }catch(exception e){
            system.debug(e.getLineNumber() + e.getMessage());
            result.put('Message',e.getMessage());  
        }
        
        
        return result;
    
    }
}