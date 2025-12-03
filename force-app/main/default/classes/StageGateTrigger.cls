public class StageGateTrigger{
    public static string validateMileStone(List<Stage_Gate__c>newRecords, string stage,boolean isPerform,string lwcPage,string stage1){
        Milestone_Master__c mil= [select id ,name,Milestone_Code__c,Staging__c,Milestone_Description__c,Timelines_in_Days__c ,Milestone_Sequence__c, Product_Group__c from Milestone_Master__c where 
                                  Staging__c =:stage limit 1];
        
        set<Id> strId = new set<Id>();
        
        Map<Id,Stage_Gate__c> mps = new Map<Id,Stage_Gate__c>();
        for(Stage_Gate__c str : newRecords){
            strId.add(str.Id);
        }
        string recordId ='';
        string mildId ='';
        List<Milestone__c> mileList = new List<Milestone__c>();
        List<Milestone__c> mle = [Select Id, Stage_Gate__c from Milestone__c where Stage_Gate__c IN : strId and Staging__c =:stage limit 1];
        if(mle.size() ==0){
            for(Stage_Gate__c str : newRecords){
                Milestone__c mile = new Milestone__c();
                mile.Stage_Gate__c = str.Id;
                recordId = str.Id;
                mile.Name = mil.Name;
                mile.OwnerId = str.OwnerId;
                mile.Milestone__c = mil.Id;
                mile.Stage_Commenced__c = date.today();
                mile.Milestone_Sequence__c = mil.Milestone_Sequence__c;
                mile.Milestone_Description__c = mil.Milestone_Description__c;
                mile.Product_Group__c = mil.Product_Group__c;
                mile.Milestone_Code__c = mil.Milestone_Code__c;
                mile.Staging__c = mil.Staging__c;
                
                if(isPerform){
                    str.Stage__c = mil.name;
                    str.Start_Date__c = date.today();
                    str.End_Date__c = date.today().addDays(Integer.valueOf(mil.Timelines_in_Days__c));
                    
                    mps.put(str.Id,str);
                }
                mileList.add(mile);
            }
            if(mileList.size() > 0){
                insert mileList;   
                mildId = mileList[0].Id;
                
                map<string,Milestone__c> mileMap= new map<string,Milestone__c> (); 
                for(Milestone__c ml : mileList){
                    mileMap.put(ml.Milestone__c,ml);
                }
                
                List<Assessment_Master__c> amsList = [ select id,Milestone__c ,Name,Question_Type__c , Assessment_Question__c,Criteria_Measure__c,Responsibilty_Role__c,Responsibilty_User__c
                                                      ,Accessor_User__c,Accessor_Role__c,Assessment_Remarks__c from Assessment_Master__c 
                                                      where Milestone__c =: mil.Id order by Name asc];
                
                List<Assessment_Criteria__c> asccList = new List<Assessment_Criteria__c>();
                for(Assessment_Master__c ams : amsList){
                    if(mileMap.containsKey(ams.Milestone__c)){
                        Assessment_Criteria__c acs = new Assessment_Criteria__c();
                        acs.Milestone__c = mileMap.get(ams.Milestone__c).Id;
                        acs.Name = ams.Name;
                        acs.Assessment_Master__c = ams.Id;
                        //acs.Assessment_Answer__c = ams.a
                        acs.Assessment_Question__c = ams.Assessment_Question__c;
                        acs.Criteria_Measure__c = ams.Criteria_Measure__c;
                        acs.Assessment_Remarks__c = ams.Assessment_Remarks__c;
                        acs.Question_Type__c= ams.Question_Type__c;
                        
                        acs.Responsibilty_Role__c = ams.Responsibilty_Role__c;
                        acs.Responsibilty_User__c = ams.Responsibilty_User__c;
                        acs.Accessor_User__c = ams.Accessor_User__c;
                        acs.Accessor_Role__c = ams.Accessor_Role__c;
                        
                        asccList.add(acs);
                    }
                }
                
                if(asccList.size() > 0){
                    insert asccList;
                    sendEmailOnInsert(asccList,recordId,mildId,lwcPage,stage1);
                }
                
                
                List<Decision_Criteria__c> dcsmList = new List<Decision_Criteria__c>();
                List<Decision_Criteria_Master__c> dcsList = [select id ,Name,Question__c,Decision_Role__c,Decision_User__c,Milestone__c, Decision__c,Decision_Rating__c from Decision_Criteria_Master__c 
                                                             where  Milestone__c =: mil.Id order by Name asc];
                
                for(Decision_Criteria_Master__c dcsm: dcsList){
                    if(mileMap.containsKey(dcsm.Milestone__c)){
                        Decision_Criteria__c  dcs  =  new Decision_Criteria__c();
                        dcs.Milestone__c = mileMap.get(dcsm.Milestone__c).Id; 
                        dcs.Name = dcsm.Name;
                        dcs.Question__c = dcsm.Question__c;
                        dcs.Decision__c = dcsm.Decision__c;
                        dcs.Decision_Rating__c = dcsm.Decision_Rating__c;
                        dcs.Decision_Role__c =dcsm.Decision_Role__c;
                        dcs.Decision_User__c = dcsm.Decision_User__c;
                        dcsmList.add(dcs);
                        
                        
                    }
                }
                
                if(dcsmList.size() > 0){
                    insert dcsmList;
                }
            }
            update mps.Values();
        }
        if(mileList.size() > 0){
            
            return mileList[0].Id;
        }else {
            return '';
        }
    }
    
    public static void beforeMileStone(List<Stage_Gate__c>newRecords){
        Milestone_Master__c mil= [select id ,name,Milestone_Code__c,Staging__c,Milestone_Description__c,Timelines_in_Days__c ,Milestone_Sequence__c, Product_Group__c 
                                  from Milestone_Master__c where 
                                  Staging__c =:'Stage 1' limit 1];
        
        for(Stage_Gate__c stg1 : newRecords){
            stg1.Stage__c = mil.name;
            stg1.Start_Date__c = date.today();
            stg1.End_Date__c = date.today().addDays(Integer.valueOf(mil.Timelines_in_Days__c));
            
        }
    }
    
    
    public static void sendEmailOnInsert(List<Assessment_Criteria__c> asccList,string recordId ,string mildId, string lwcPage, string stage){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String recordUrl = system.label.baseUrl + '/lightning/cmp/'+lwcPage+'?c__refRecordId=' + mildId + '#/';
        
        Stage_Gate__c stc = [Select Id,Name,Start_Date__c,Stage__c,BU_Head__c,Owner.Name,Owner.Email,BU_Head__r.Name,BU_Head__r.Email from Stage_gate__c where Id=:recordId];
         List<string> toAddress = new List<string>();
        
        if(test.isRunningTest()){
        toAddress.add('rishikesh.korade@finessedirect.com');
        }
        List<string> cctoAddress = new List<string>();
        if(string.isNotBlank(stc.Owner.Email)){
        cctoAddress.add(stc.Owner.Email);
        }
        string subject ='Update Assessment Criteria for Stage Gate '+stc.Name+' Milestone: '+stage;
        
        for(Assessment_Criteria__c dct :asccList){
            if(string.isNotBlank(dct.Responsibilty_User__r.Email)){
                toAddress.add(dct.Responsibilty_User__r.Email);
            }
        }

        
        mail.setToAddresses(toAddress);
        if(cctoAddress.size()  > 0){
                mail.setCCaddresses(cctoAddress);
        }
                mail.setSubject(subject);
                string body = 'Dear Abhishekh, <br/><br/>';
                body += 'As a criteria owner, please update your assigned assessment criteria for this milestone at your earliest convenience. Your input is essential to ensure a timely and accurate review process.<br/><br/>';
                body +='You can access the assessment criteria update form here:<br/>';
                body +='<b>Link</b>: <a href="' + recordUrl + '">'+stage+'</a><br/>';
                body +='Thank you for your support.<br/><br/>';
                body +='Thanks & Regards,<br/>';
                body +=stc.Owner.Name;
        mail.setHtmlBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
        
}