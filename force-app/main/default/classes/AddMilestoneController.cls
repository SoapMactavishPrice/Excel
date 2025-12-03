public class AddMilestoneController {
    
    @AuraEnabled(cacheable=true)
    public static List<object>getGlobalPicklistValues(String fieldName) {
        List<object> picklistValues = new List<object>();
        
        // Querying global picklist values
        Schema.DescribeFieldResult fieldResult = Milestone_Master__c.Product_Group__c.getDescribe(); // Replace Account.Industry with your field
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry entry : picklistEntries) {
            map<string,object> pick = new map<string,object>();
            pick.put('label',entry.getLabel());
            pick.put('value',entry.getvalue());
            picklistValues.add(pick);
        }
        
        return picklistValues;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Milestone_Master__c> getMilesStone(string category){
        return [select id ,name,Milestone_Code__c,Milestone_Description__c ,Milestone_Sequence__c, Product_Group__c from Milestone_Master__c where Product_Group__c =:category];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Assessment_Master__c> getAssessmentMaster(string mileStoneId){
        return [select id ,Name,Question_Type__c , Assessment_Question__c,Criteria_Measure__c,Assessment_Remarks__c from Assessment_Master__c 
                where Milestone__c =: mileStoneId order by Name asc];
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<Decision_Criteria_Master__c> getDescisionCriteria(string mileStoneId){
        return [select id ,Name,Question__c, Decision__c from Decision_Criteria_Master__c where Milestone__c =: mileStoneId order by Name asc];
    }
    
    @AuraEnabled
    public static map<string,string> saveMilestone(string optyId, string js){
        map<string,string> result = new map<string,string>();
        try{
            List<Milestone__c> mileList = new List<Milestone__c>();
            List<Object> objList = (List<Object>)JSON.deserializeUntyped(js);
            for(Object obj : objList){
                map<string,object> objMap =(map<string,object>)obj;
                Milestone__c mm = new Milestone__c();
                mm.Opportunity__c = optyId;
                mm.Milestone__c = (Id)objMap.get('Id');
                mm.Name	 = (string)objMap.get('Name');
                mm.Milestone_Code__c	 = (string)objMap.get('Milestone_Code');
                mm.Milestone_Sequence__c	 = (decimal)objMap.get('Milestone_Sequence');
                mm.Product_Group__c	 = (string)objMap.get('Product_Group');
                mm.Milestone_Description__c	 = (string)objMap.get('Milestone_Description');
                mileList.add(mm);
            }
            
            if(mileList.size() > 0){
                insert mileList;    
            }
            
            result.put('message','success');  
        }catch(exception e){
            result.put('message',e.getMessage());
        }
        
        return result;
    }
    
    
    @AuraEnabled
    public static map<string,string> saveAssessment(string optyId, string mId){
        map<string,string> result = new map<string,string>();
        
        try{
            
            List<string> milesId = new List<string>();
            List<object> js =(List<object>)JSON.deserializeUntyped(mId);
            for(object str : js){
                milesId.add(string.valueOf(str));
            }
            
            system.debug('milesId-->'+milesId);
            List<Milestone__c> masterList = [select Id,Milestone__c from Milestone__c where Opportunity__c=: optyId];
            
            map<Id,Id> mileId= new map<Id,Id>(); 
            for(Milestone__c mile : masterList){
                mileId.put(mile.Milestone__c,mile.Id);
            }
            
            List<Assessment_Criteria__c> aslist = new List<Assessment_Criteria__c>();
            List<Assessment_Master__c> amsList = [ select id,Milestone__c ,Name,Question_Type__c , Assessment_Question__c,Criteria_Measure__c,
                                                  Assessment_Remarks__c from Assessment_Master__c 
                                                  where Milestone__c IN : milesId order by Name asc];
            
            map<Id,Assessment_Master__c> asm = new  map<Id,Assessment_Master__c>();
            
            for(Assessment_Master__c ams : amsList){
                if(mileId.containsKey(ams.Milestone__c)){
                    Assessment_Criteria__c acs = new Assessment_Criteria__c();
                    acs.Milestone__c = mileId.get(ams.Milestone__c);
                    acs.Opportunity__c = optyId;
                    acs.Name = ams.Name;
                    acs.Assessment_Question__c = ams.Assessment_Question__c;
                    acs.Criteria_Measure__c = ams.Criteria_Measure__c;
                    acs.Assessment_Remarks__c = ams.Assessment_Remarks__c;
                    acs.Question_Type__c= ams.Question_Type__c;
                    aslist.add(acs);
                }
            }
            
            if(aslist.size() > 0){
                insert aslist;
            }
            
            result.put('message','success');  
        }catch(exception e){
            result.put('message',e.getMessage());
        }
        
        return result;
    }
    
    
    @AuraEnabled
    public static map<string,string> saveDecision(string optyId, string mId){
        map<string,string> result = new map<string,string>();
        try{
            
            List<string> milesId = new List<string>();
            List<object> js =(List<object>)JSON.deserializeUntyped(mId);
            for(object str : js){
                milesId.add(string.valueOf(str));
            }
            
            system.debug('milesId-->'+milesId);
            List<Milestone__c> masterList = [select Id,Milestone__c from Milestone__c where Opportunity__c=: optyId];
            
            map<Id,Id> mileId= new map<Id,Id>(); 
            for(Milestone__c mile : masterList){
                mileId.put(mile.Milestone__c,mile.Id);
            }
            
            List<Decision_Criteria__c> dcsmList = new List<Decision_Criteria__c>();
            
            List<Decision_Criteria_Master__c> dcsList = [select id ,Name,Question__c,Milestone__c, Decision__c from Decision_Criteria_Master__c 
                                                         where Milestone__c IN : milesId order by Name asc];
            for(Decision_Criteria_Master__c dcsm: dcsList){
                if(mileId.containsKey(dcsm.Milestone__c)){
                    Decision_Criteria__c  dcs  =  new Decision_Criteria__c();
                    dcs.Opportunity__c = optyId;
                    dcs.Milestone__c = mileId.get(dcsm.Milestone__c); 
                    //dcs.Milestone__c = dcsm.Milestone__c; 
                    dcs.Name = dcsm.Name;
                    dcs.Question__c = dcsm.Question__c;
                    dcs.Decision__c = dcsm.Decision__c;
                    dcsmList.add(dcs);
                }
            }
            
            if(dcsmList.size() > 0){
                insert dcsmList;
            }
            
            result.put('message','success');  
        }catch(exception e){
            result.put('message',e.getMessage());
        }
        
        return result;
    }
    
}