@isTest
public class LwcStageGateScoreControllerStage2Test {
    
   @testSetup
    static void setupData() {
        // Create related Milestone
        Milestone__c milestone = new Milestone__c(Name = 'Milestone Test', Staging__c = 'Stage 4');
        insert milestone;
        
        // Create users for responsibility and accessor
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User u1 = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u1;
        
        User u2 = new User(
            FirstName = 'Testuser',
            LastName = 'Testusers',
            Email = 'testuser123@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u2;
        
        // Step 2: Create Milestone_Master__c record (new addition)
        Milestone_Master__c milestoneMaster = new Milestone_Master__c(
            Name = 'Milestone Master 1'
        );
        insert milestoneMaster;
        
        // Step 3: Create Assessment_Master__c record with correct lookup
        Assessment_Master__c master = new Assessment_Master__c(
            Name = 'Test Master',
            Milestone__c = milestoneMaster.Id, 
            Assessment_Remarks__c = 'Master remarks'
        );
        insert master;
        
        // Create Assessment_Criteria__c record
        Assessment_Criteria__c criteria = new Assessment_Criteria__c(
            Name = 'Criteria 1',
            Question_Type__c = 'Text',
            Assessment_Question__c = 'Question A',
            Assessment_Master__c = master.Id,
            Milestone__c = milestone.Id,
            Responsibilty_User__c = u1.Id,
            Accessor_User__c = u2.Id,
            Criteria_Measure__c = 'High',
            Assessment_Remarks__c = 'Some remarks'
        );
        insert criteria;
        
        // Create Assessment_Answer__c record (via child relationship)
        Assessment_Answer__c answer = new Assessment_Answer__c(
            Name = 'Answer 1',
            Assessment_Master__c = master.Id,
            Assessment_Answer__c = 'Answer A'
        );
        insert answer;
        
        // Create Decision_Criteria__c record
        Decision_Criteria__c decision = new Decision_Criteria__c(
            Name = 'Decision 1',
            Milestone__c = milestone.Id,
            Question__c = 'Why?',
            Decision_making_Notes__c = 'Some note',
            Decision_User__c = u1.Id,
            Decision_Rating__c = 'Go',
            Decision_Role__c = 'CEO',
            Decision__c = 'Go'
        );
        insert decision;
        
        // Setup Files
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test file content')
            
        );
        insert cv;
        
        ContentVersion insertedCV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE Id = :insertedCV.ContentDocumentId];
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = milestone.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
    }
    
    @isTest
    static void testGetRecordDetail() {
        Milestone__c m = [SELECT Id FROM Milestone__c LIMIT 1];
        Test.startTest();
        Milestone__c result = LwcStageGateScoreControllerStage2.getRecordDetail(m.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testDeleteFile() {
        Milestone__c ms = [SELECT Id FROM Milestone__c LIMIT 1];
        
        ContentDocumentLink cdl = [
            SELECT Id, ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :ms.Id 
            LIMIT 1
        ];
        
        Test.startTest();
        String result = LwcStageGateScoreControllerStage2.deletefile(cdl.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetFiledDisplay() {
        Milestone__c testMilestone = [SELECT Id FROM Milestone__c LIMIT 1];
        Test.startTest();
        String jsonResult = LwcStageGateScoreControllerStage2.getFiledDisplay(testMilestone.Id);
        Test.stopTest();        
    }
    
    
    
    
    @isTest
    static void testGetFiledDisplayAndGetDocumentUrl() {
        // Create a Milestone__c record to attach the file to
        Milestone__c milestone = new Milestone__c(
            Final_Outcome__c = 5,
            Overall_Decision_by_CEO__c = 'Approved'
        );
        insert milestone;
        
        // Step 1: Create a ContentVersion record (creates a ContentDocument behind the scenes)
        ContentVersion cv = new ContentVersion(
            Title = 'TestDocument',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test file content')
            
        );
        insert cv;
        
        // Step 2: Get the ContentDocumentId from inserted ContentVersion
        ContentVersion insertedCV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        Id contentDocId = insertedCV.ContentDocumentId;
        
        // Step 3: Link the document to the milestone
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocId,
            LinkedEntityId = milestone.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        Test.startTest();
        
        // Test getFiledDisplay
        String fileDisplayJson = LwcStageGateScoreControllerStage2.getFiledDisplay(milestone.Id);
        
        
        // Test getDocumentUrl
        String documentId = LwcStageGateScoreControllerStage2.getDocumentUrl(cdl.Id);
        
        
        Test.stopTest();
    }
    
    
    @isTest
    static void testGetAssessmentMaster() {
        Milestone__c milestone = [SELECT Id FROM Milestone__c WHERE Staging__c = 'Stage 4' LIMIT 1];
        
        Test.startTest();
        List<Assessment_Criteria__c> result = LwcStageGateScoreControllerStage2.getAssessmentMaster(milestone.Id);
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testGetAssessmentAnswer() {
        Test.startTest();
        List<Assessment_Master__c> result = LwcStageGateScoreControllerStage2.getAssessmentAnswer(null);
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testGetDescisionCriteria() {
        Milestone__c milestone = [SELECT Id FROM Milestone__c WHERE Staging__c = 'Stage 4' LIMIT 1];
        
        Test.startTest();
        List<Decision_Criteria__c> result = LwcStageGateScoreControllerStage2.getDescisionCriteria(milestone.Id);
        Test.stopTest();
        
    }
    
        
        @isTest
        static void testSaveDataMethod() {
          // Step 1: Create Milestone__c record (as before)
        Milestone__c milestone = new Milestone__c(
            Name = 'Test Milestone',
            Staging__c = 'Stage 1'
        );
        insert milestone;
        
        // Step 2: Create Milestone_Master__c record (new addition)
        Milestone_Master__c milestoneMaster = new Milestone_Master__c(
            Name = 'Milestone Master 1'
        );
        insert milestoneMaster;
            
            // Step 3: Create Assessment_Master__c record with correct lookup
        Assessment_Master__c master = new Assessment_Master__c(
            Name = 'Test Master',
            Milestone__c = milestoneMaster.Id, // Correct Milestone Master reference
            Assessment_Remarks__c = 'Master remarks'
        );
        insert master;
            
             // Step 4: Create Assessment_Answer__c record (child of master)
        Assessment_Answer__c answer = new Assessment_Answer__c(
            Name = 'Answer A',
            Assessment_Master__c = master.Id,
            Assessment_Answer__c = 'Yes'
        );
        insert answer;
            
             // Create Assessment_Criteria__c record linked to milestone and master
        Assessment_Criteria__c criteria = new Assessment_Criteria__c(
            Name = 'Criteria A',
            Milestone__c = milestone.Id,
            Assessment_Master__c = master.Id,
            Assessment_Question__c = 'Sample Question',
            Question_Type__c = 'Text',
            Criteria_Measure__c = 'Good',
            Assessment_Remarks__c = 'Criteria remarks'
        );
        insert criteria;
            
            // Prepare JS input (JSON string for criteria update)
            List<Map<String, Object>> jsList = new List<Map<String, Object>>();
            jsList.add(new Map<String, Object>{
                'Id' => criteria.Id,
                    'Assessment_Master__c' => master.Id,
                    'Assessment_Answer' => 1
                    });
            String jsString = JSON.serialize(jsList);
            
           // Step 5: Create Decision_Criteria__c record
        Decision_Criteria__c decision = new Decision_Criteria__c(
            Name = 'Decision A',
            Milestone__c = milestone.Id,
            Question__c = 'Should we proceed?',
            Decision_making_Notes__c = 'Consider budget',
            Decision_Rating__c = 'Go',
            Decision_Role__c = 'CEO',
           Decision__c = 'Go'
        );
        insert decision;
            
            // Prepare descJs input (JSON string for decision update)
            List<Map<String, Object>> descList = new List<Map<String, Object>>();
            descList.add(new Map<String, Object>{
                'Id' => decision.Id,
                    'decision' => 'Yes',
                    'decision_Rating' => 'High',
                    'notes' => 'Well explained'
                    });
            String descJsString = JSON.serialize(descList);
            
            // Build JS string for assessment
        String jsonJS = '[{"Id":"' + criteria.Id + '","Assessment_Master__c":"' + master.Id + '","Assessment_Answer":0}]';
        
        // Build descJS string for decision
        String descJS = '[{"Id":"' + decision.Id + '","decision":"Go","notes":"All good"}]';
		
            
            Test.startTest();
            // Call the method
            //Map<String, String> result = LwcStageGateScoreControllerStage2.saveData(jsString, descJsString, 16, ms.Id, 'Go');
             Map<String, String> result = LwcStageGateScoreControllerStage2.saveData(jsonJS, descJS, 16, milestone.Id, 'Go','Reject',true,'ok');
        Map<String, String> result1 = LwcStageGateScoreControllerStage2.saveData(jsonJS, descJS, 16, milestone.Id, 'Go','Pending',false,'ok');
        Map<String, String> result2 = LwcStageGateScoreControllerStage2.saveData(jsonJS, descJS, 16, milestone.Id, 'Go','Approved',false,'ok');
                Map<String, String> result3 = LwcStageGateScoreControllerStage2.saveData(jsonJS, descJS, 16, milestone.Id, 'Go','Approved',true,'ok');

            Test.stopTest();
            
            
        }
}