public class LwcStageGateScoreController {
    
    
    @auraEnabled
    public static Milestone__c getRecordDetail(string recordId){
        Milestone__c us = [select Id , Final_Outcome__c,Overall_Decision_by_CEO__c,BU_Head_User__c,BU_Head_Status__c from Milestone__c where Id=:recordId];
        return us;
    }
    
    
    @AuraEnabled 
    public static string deletefile(string prodId){
        List<ContentDocumentLink> cdlList = [SELECT ContentDocumentId, Id FROM ContentDocumentLink WHERE Id =:prodId];
        
        Set<Id> contentDocumentIds = new Set<Id>();
        for(ContentDocumentLink cdl : cdlList){
            contentDocumentIds.add(cdl.ContentDocumentId);
        }
        
        delete cdlList;
        
        delete [SELECT Id FROM ContentDocument WHERE Id IN :contentDocumentIds];
        return 'Files deleted successfully';
    }
    
    @AuraEnabled 
    public static string getFiledDisplay(string prodId){
        List<ContentDocumentLink> cdList = [SELECT ContentDocument.Id, Id,ContentDocument.Title, ContentDocument.FileExtension, LinkedEntityId
                                            FROM ContentDocumentLink where LinkedEntityId=:prodId];
        List<dataChildWrapper> fileList = new List<dataChildWrapper>();
        for(ContentDocumentLink cdl : cdList){
            dataChildWrapper fl = new dataChildWrapper();
            fl.Id = cdl.Id;
            fl.Name = cdl.ContentDocument.Title;
            fl.selectFile = false;
            fileList.add(fl);
        }
        
        if(fileList.size() > 0)
            return JSON.serialize(fileList);
        else 
            return null;
    }
    
    
    @AuraEnabled 
    public static string getDocumentUrl (string Id){
        
        // List<FileData> files=new List<FileData>();
        system.debug('Id'+Id);
        
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        
        ContentDocumentLink cdl = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE Id = :Id limit 1
        ];
        
        
        ContentVersion  attach = [
            SELECT Id, Title, VersionData,FileExtension, ContentDocumentId, ContentDocument.Title, ContentDocument.CreatedDate
            FROM ContentVersion
            WHERE ContentDocumentId = :cdl.ContentDocumentId
            AND ContentDocument.filetype != 'mp4'
            ORDER BY CreatedDate DESC limit 1];
        
        return attach.ContentDocumentId;
    }
    
    @AuraEnabled
    public static List<Assessment_Criteria__c> getAssessmentMaster(string recordId){
        return [select id ,Name,Question_Type__c , Assessment_Question__c,Assessment_Master__c,Responsibilty_User__c,Responsibilty_User__r.Name,Accessor_User__r.Name,Accessor_User__c,Assessment_Answer__r.Name,Criteria_Measure__c,Assessment_Remarks__c from Assessment_Criteria__c 
                where Milestone__c =: recordId and Milestone__r.Staging__c=:'Stage 1' order by Name asc];
    }
    
    @AuraEnabled
    public static List<Assessment_Master__c> getAssessmentAnswer(string recordId){
        return [select id ,Name,Assessment_Remarks__c,
                (SELECT Id ,Name,Assessment_Answer__c,Assessment_Master__r.Name,Assessment_Master__c,Assessment_Master__r.Assessment_Remarks__c FROM Assessment_Answer__r)
                from Assessment_Master__c 
                where  Milestone__r.Staging__c=:'Stage 1' order by Name asc];
    }
    
    @AuraEnabled
    public static List<Decision_Criteria__c> getDescisionCriteria(string recordId){
        return [select id ,Name,Question__c,Decision_making_Notes__c,Decision_User__c,Decision_Rating__c,Decision_Role__c, Decision__c from Decision_Criteria__c 
                where Milestone__c=:recordId and Milestone__r.Staging__c=:'Stage 1' order by Name asc];
    }
    
    
    @AuraEnabled 
    public static Map<string, string> saveData(string JS , string descJs, Integer score,string recordId, string label,string approverLabel,boolean openDecisionCriteria
                                               ,string reason){
        Map<string, string>  result = new Map<string, string>();
        try{
            
            //system.debug('descJs  ->' + descJs);
            List<Assessment_Answer__c> asmList = [SELECT Id ,Name,Assessment_Answer__c,Assessment_Master__r.Name,Assessment_Master__c,Assessment_Master__r.Assessment_Remarks__c FROM Assessment_Answer__c];
            Map<string,Id> asmMap = new  Map<string,Id>();
            
            for(Assessment_Answer__c am: asmList){
                asmMap.put(am.Assessment_Master__c +'_'+am.Name,am.Id);
            }
            system.debug('asmMap ->'+asmMap);
            List<Assessment_Criteria__c> lsmListUpdate = new List<Assessment_Criteria__c>();
            List<Object> sObjList = (List<Object>)JSON.deserializeUntyped(JS);
            for(Object obj : sObjList){
                Map<string,object> objMap = (Map<string,object>)obj;
                if(string.isNotBlank(string.valueOf(objMap.get('Assessment_Answer')))){
                    
                    Assessment_Criteria__c ascr = new Assessment_Criteria__c();
                    ascr.Id = (Id)objMap.get('Id');
                    string key = (string)objMap.get('Assessment_Master__c')+'_'+string.valueOf((Integer)objMap.get('Assessment_Answer'));
                    system.debug('key ->'+key);
                    if(asmMap.containsKey(key)){
                        ascr.Assessment_Answer__c = (Id)asmMap.get(key);
                        lsmListUpdate.add(ascr);
                    }
                }
            }
            
            if(lsmListUpdate.size() > 0){
                update lsmListUpdate;
            }
            
            string nextMileId = ''; 
            Milestone__c mc = new Milestone__c();
            mc.Id = recordId;
            //mc.Stage_Closed__c = date.today();
            //mc.Overall_Decision_by_CEO__c = label;

            mc.Final_Outcome__c = score;
            
            List<Stage_gate__c> slIst =  [Select Id,Name,Start_Date__c,Stage__c,BU_Head__c,Owner.Email,BU_Head__r.Name,BU_Head__r.Email from Stage_gate__c where Id 
                                          IN (Select Stage_Gate__c from milestone__c where Id=:recordId)];
			
            
            List<string> toAddress = new List<string>();
            List<string> cctoAddress = new List<string>();
            //toAddress.add('rishikesh.korade@finessedirect.com');
            Stage_gate__c stc = new Stage_gate__c();
            if(slIst.size() > 0 ){
                stc = slIst[0];
            }
            
            
            List<Decision_Criteria__c> sdlIst =  [Select Id,Decision_User__r.Email from Decision_Criteria__c where Milestone__c =: recordId];
            List<Assessment_Criteria__c> accessList= [SELECT Id,Responsibilty_User__r.Email FROM Assessment_Criteria__c where  Milestone__c =: recordId];
                        
            
            string subject = ' – Stage Gate '+ stc.Name+', Milestone:Ideation';           
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String recordUrl = system.label.baseUrl + '/lightning/cmp/c__lwcStageGateScoreCaller?c__refRecordId=' + recordId + '#/';
            
 			if (!test.isRunningTest()) {
                toAddress.add('rishikesh.korade@finessedirect.com');
                cctoAddress.add('rishikesh.korade@finessedirect.com');
            }       
            system.debug('score  ->' + score+' approverLabel '+approverLabel);
            
            if(score >= 15 && (approverLabel =='' ||  approverLabel ==null || approverLabel=='Pending')){
                string buHeadName = '';
                mc.BU_Head_Status__c = 'Pending';
                mc.Request_Date_Time__c = system.now();
                
                subject = 'Approval Request '+subject;
                
                if(slIst.size() > 0){
                    toAddress.add(stc.BU_Head__r.Email);
                    cctoAddress.add(stc.Owner.Email);
                    buHeadName = slIst[0].BU_Head__r.Name;
                }
                
                //toAddress.add('balram@finessedirect.com');
					

                mail.setToAddresses(toAddress);
                mail.setCCaddresses(cctoAddress);
                mail.setSubject(subject);
                string body = 'Dear '+ buHeadName +',<br/><br/>';
                body += 'As part of the Stage Gate process for <b>'+stc.Name+'</b>, we have successfully completed the assessment criteria for <b>Milestone: Ideation</b>.<br/><br/>';
                body +='We request your review and approval to proceed to the next phase.<br/>';
                body +='<b>Link</b>: <a href="' + recordUrl + '">Ideation</a><br/>';
                body +='Kindly confirm your approval to move forward to the next stage.<br/>';
                body +='Thank you for your guidance and support. <br/><br/>';
                body +='Thanks & Regards,<br/>';
                body +='Abhishekh Bhavani,<br/>';
                
                mail.setHtmlBody(body);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
            
            else if(score >= 15 && (approverLabel =='' ||  approverLabel =='Reject' || approverLabel=='Approved')){
                string buHeadName = '';
                mc.BU_Head_Status__c = approverLabel;
                
                 if( approverLabel=='Reject'){
                    mc.Rejected_Date_Time__c = system.now();

				    subject = 'Rejection '+subject;
                     
                     for(Assessment_Criteria__c dct :accessList){
                        if(string.isNotBlank(dct.Responsibilty_User__r.Email)){
                            toAddress.add(dct.Responsibilty_User__r.Email);
                        }
                    }

                    cctoAddress.add(stc.Owner.Email);
                    mail.setToAddresses(toAddress);
                    mail.setCCaddresses(cctoAddress);
                    
                     mail.setSubject(subject);
                     string body = 'Dear Team, ' +'<br/><br/>';
                     body += 'I have reviewed the submission for Stage Gate  <b>'+stc.Name+'</b>, <b>Milestone: Ideation</b>. At this stage, I am unable to approve moving forward. <br/><br/>';
                     body +='<b>Link</b>: <a href="' + recordUrl + '">Ideation</a><br/>';
                     if(string.isNotBlank(reason)){
                         body+='Reason : '+reason;
                     }
                    
                    
                    mail.setHtmlBody(body);
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                }
                else
                if(!openDecisionCriteria && approverLabel=='Approved'){
                    
                    
                    subject = 'Approval '+subject;
                    
                    mc.Approval_Date_Time__c = system.now();
                    
                    for(Assessment_Criteria__c dct :accessList){
                        if(string.isNotBlank(dct.Responsibilty_User__r.Email)){
                            toAddress.add(dct.Responsibilty_User__r.Email);
                        }
                    }
                    
                    
                    // Set the recipient
                    mail.setToAddresses(toAddress);
                    cctoAddress.add(stc.Owner.Email);
                    mail.setCCAddresses(cctoAddress);
                    // Set subject and body
                    mail.setSubject(subject);
                    string body = 'Dear Team,' +'<br/><br/>';
                    body += 'I have reviewed the submission for Stage Gate <b>'+stc.Name+'</b>, Milestone: Ideation, and I approve proceeding to the next phase.<br/><br/>';
                    body +='<b>Link</b>: <a href="' + recordUrl + '">Ideation</a><br/><br/>';
					body +='Best Regards,<br/>';
                    body += stc.BU_Head__r.Name;
                    
                    mail.setHtmlBody(body);
                    
                    
                    List<string> toAddress2 = new List<string>();
                    for(Decision_Criteria__c dct :sdlIst){
                        if(string.isNotBlank(dct.Decision_User__r.Email)){
                            toAddress2.add(dct.Decision_User__r.Email);
                        }
                    }
                    
                    //toAddress2.add('rishikesh.korade@finessedirect.com');
                    Messaging.SingleEmailMessage mail2 = new Messaging.SingleEmailMessage();
                    string body2 = 'Dear Pradeep Ghattu,' +'<br/><br/>';
                    body2 += 'I have reviewed the submission for Stage Gate <b>'+stc.Name+'</b>, Milestone: Ideation, and I approve proceeding to the next phase.<br/><br/>';
                    body2 +='Kindly review the submission against the defined Decision Criteria at your convenience.<br/>';
                    body2 +='<b>Link</b>: <a href="' + recordUrl + '">Ideation</a><br/><br/>';
					body2 +='Best Regards,<br/>';
                    body2 += stc.BU_Head__r.Name;
                    
                    mail2.setToAddresses(toAddress2);
                    cctoAddress.add(stc.Owner.Email);
                    mail2.setCCAddresses(cctoAddress);
                    mail2.setSubject(subject+' (For COO Review) ');
                    mail2.setHtmlBody(body2);
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail,mail2 });
                }
                
                else  if(openDecisionCriteria && approverLabel=='Approved'){
                    
                    List<Decision_Criteria__c> descListUpdate = new List<Decision_Criteria__c>();
                    List<Object> descObjList = (List<Object>)JSON.deserializeUntyped(descJs);
                    for(Object obj : descObjList){
                        Map<string,object> objMap = (Map<string,object>)obj;
                        Decision_Criteria__c ascr = new Decision_Criteria__c();
                        ascr.Id = (Id)objMap.get('Id');
                        ascr.Decision__c = (string)objMap.get('decision');
                        ascr.Decision_making_Notes__c = (string)objMap.get('notes');
                        descListUpdate.add(ascr);
                    }
                    
                    if(descListUpdate.size() > 0){
                        update descListUpdate;
                    }
                    mc.Stage_Closed__c = date.today();
                    mc.Overall_Decision_by_CEO__c = label;
                    
                    List<Stage_Gate__c> stgList = [Select Id,Start_Date__c,Stage__c,OwnerId from Stage_gate__c where Id IN (Select Stage_Gate__c from milestone__c where Id=:recordId)];
                    if(label =='Go'){
                        if (!test.isRunningTest()) {
                        nextMileId = StageGateTrigger.validateMileStone(stgList,'Stage 2',true,'c__lwcStageGateScoreStageGate2Caller','Assess Feasibility');
                        }
                    } 
                }
                
                
            }
            
            if(string.isBlank(nextMileId)){
                nextMileId = mc.Id;
            }
            
            update mc;
            result.put('Message','Success_'+nextMileId);
            
            
        }catch(exception e){
            system.debug(e.getLineNumber() + e.getMessage());
            result.put('Message',e.getMessage()+e.getLineNumber());  
        }
        
        return result;
    }
    
    
    public with sharing class dataChildWrapper{
        public string Id;
        public Integer index;
        public string Name;
        public boolean selectFile = false;
    }
}