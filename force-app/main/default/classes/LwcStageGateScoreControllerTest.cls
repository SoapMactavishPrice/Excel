@isTest
public class LwcStageGateScoreControllerTest {
    
    @testSetup
    static void setupTestData() {
        Milestone_Master__c milestoneMaster = new Milestone_Master__c(
            Name = 'Milestone Master 1',Staging__c ='Stage 1',Timelines_in_Days__c=20
        );
        insert milestoneMaster;
        // Create a test Milestone record
        Milestone__c milestone = new Milestone__c(
            // Final_Outcome__c = 'Approved',
            Overall_Decision_by_CEO__c = 'Yes'
        );
        insert milestone;
        
        // Create a test ContentVersion
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Test Content')
        );
        insert cv;
        
        // Query to get ContentDocumentId
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        // Create ContentDocumentLink
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = milestone.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
    }
    
    @isTest
    static void testGetRecordDetail() {
        Milestone__c testMilestone = [SELECT Id FROM Milestone__c LIMIT 1];
        Test.startTest();
        Milestone__c result = LwcStageGateScoreController.getRecordDetail(testMilestone.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetFiledDisplay() {
        Milestone__c testMilestone = [SELECT Id FROM Milestone__c LIMIT 1];
        Test.startTest();
        String jsonResult = LwcStageGateScoreController.getFiledDisplay(testMilestone.Id);
        Test.stopTest();        
    }
    
    
    
    @isTest
    static void testGetFiledDisplayAndGetDocumentUrl() {
        Milestone_Master__c milestoneMaster = new Milestone_Master__c(
            Name = 'Milestone Master 1',Staging__c ='Stage 1',Timelines_in_Days__c=20
        );
        insert milestoneMaster;
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
        String fileDisplayJson = LwcStageGateScoreController.getFiledDisplay(milestone.Id);
        
        
        // Test getDocumentUrl
        String documentId = LwcStageGateScoreController.getDocumentUrl(cdl.Id);
        
        
        Test.stopTest();
    }
    
    
    @isTest
    static void testAssessmentAndDecisionMethods() {
   
        Milestone_Master__c milestoneMaster = new Milestone_Master__c(
            Name = 'Milestone Master 1',Staging__c ='Stage 1',Timelines_in_Days__c=20
        );
        insert milestoneMaster;
        
        Stage_Gate__c stageGate = new Stage_Gate__c(
            Name = 'Test Stage Gate'
        );
        // Use Database.insert with allOrNone=false to identify which fields are missing
        Database.SaveResult sr = Database.insert(stageGate, false);
        if (!sr.isSuccess()) {
            System.debug('Stage Gate insert error: ' + sr.getErrors()[0].getMessage());
        }
        // Step 1: Create Milestone__c record (as before)
        Milestone__c milestone1 = new Milestone__c(
            Name = 'Test Milestone',
            Staging__c = 'Stage 1'
        );
        insert milestone1;
        
        
        
        // Step 3: Create Assessment_Master__c record with correct lookup
        Assessment_Master__c master = new Assessment_Master__c(
            Name = 'Test Master',
            Milestone__c = milestoneMaster.Id, // Correct Milestone Master reference
            Assessment_Remarks__c = 'Master remarks'
        );
        insert master;
        
        
        // Step 3: Create Assessment_Criteria__c record linked to milestone and master
        Assessment_Criteria__c criteria = new Assessment_Criteria__c(
            Name = 'Criteria A',
            Milestone__c = milestone1.Id,
            Assessment_Master__c = master.Id,
            Assessment_Question__c = 'Sample Question',
            Question_Type__c = 'Text',
            Criteria_Measure__c = 'Good',
            Assessment_Remarks__c = 'Criteria remarks'
        );
        insert criteria;
        
        // Step 4: Create Assessment_Answer__c record (child of master)
        Assessment_Answer__c answer = new Assessment_Answer__c(
            Name = 'Answer A',
            Assessment_Master__c = master.Id,
            Assessment_Answer__c = 'Yes'
        );
        insert answer;
        
        // Step 5: Create Decision_Criteria__c record
        Decision_Criteria__c decision = new Decision_Criteria__c(
            Name = 'Decision A',
            Milestone__c = milestone1.Id,
            Question__c = 'Should we proceed?',
            Decision_making_Notes__c = 'Consider budget',
            Decision_Rating__c = 'Go',
            Decision_Role__c = 'CEO',
           Decision__c = 'Go'
        );
        insert decision;
        
        Test.startTest();
        
        // Test getAssessmentMaster
        List<Assessment_Criteria__c> criteriaList = LwcStageGateScoreController.getAssessmentMaster(milestone1.Id);
        
        
        // Test getAssessmentAnswer
        List<Assessment_Master__c> answerList = LwcStageGateScoreController.getAssessmentAnswer(milestone1.Id);
        
        // Test getDescisionCriteria
        List<Decision_Criteria__c> decisionList = LwcStageGateScoreController.getDescisionCriteria(milestone1.Id);
        
        
        Test.stopTest();
    }
    
    
  @isTest
    static void testSaveData() {
      
        // Get a standard profile, e.g., 'Standard User'
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Create the test user
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );

        insert u;
        
        System.runAs(u) {
        // Create Milestone Master
        Milestone_Master__c milestoneMaster = new Milestone_Master__c(Name = 'Test Milestone Master',Timelines_in_Days__c=20,Staging__c ='Stage 1');

        insert milestoneMaster;
        // Create Stage Gate
       // Stage_Gate__c stageGate = new Stage_Gate__c(Name = 'Stage Gate 1');
        //insert stageGate;

        // Create Milestone__c
        Milestone__c milestone = new Milestone__c(Name = 'Milestone 1', Staging__c = 'Stage 1');
        insert milestone;

        // Create Assessment_Master__c
        Assessment_Master__c master = new Assessment_Master__c(Name = 'Assessment Master 1', Milestone__c = milestoneMaster.Id);
        insert master;

        // Create Assessment_Answer__c
        Assessment_Answer__c answer = new Assessment_Answer__c(Name = 'Answer 1', Assessment_Master__c = master.Id);
        insert answer;

        // Create Assessment_Criteria__c
        Assessment_Criteria__c criteria = new Assessment_Criteria__c(
            Name = 'Criteria 1',
            Milestone__c = milestone.Id,
            Assessment_Master__c = master.Id
        );
        insert criteria;

        // Create Decision_Criteria__c
        Decision_Criteria__c decision = new Decision_Criteria__c(
            Name = 'Decision 1',
            Milestone__c = milestone.Id
        );
        insert decision;

        // Build JS string for assessment
        String jsonJS = '[{"Id":"' + criteria.Id + '","Assessment_Master__c":"' + master.Id + '","Assessment_Answer":0}]';
        
        // Build descJS string for decision
        String descJS = '[{"Id":"' + decision.Id + '","decision":"Go","notes":"All good"}]';
		
        /*Stage_Gate__c syg = new Stage_Gate__c();
        syg.Staging__c = 'Stage 1';
        insert syg;
        */
        Test.startTest();
        Map<String, String> result = LwcStageGateScoreController.saveData(jsonJS, descJS, 16, milestone.Id, 'Go','Reject',true,'ok');
        Map<String, String> result1 = LwcStageGateScoreController.saveData(jsonJS, descJS, 16, milestone.Id, 'Go','Pending',false,'ok');
        Map<String, String> result2 = LwcStageGateScoreController.saveData(jsonJS, descJS, 16, milestone.Id, 'Go','Approved',false,'ok');
                Map<String, String> result3 = LwcStageGateScoreController.saveData(jsonJS, descJS, 16, milestone.Id, 'Go','Approved',true,'ok');

        Test.stopTest();
        }

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
        String result = LwcStageGateScoreController.deletefile(cdl.Id);
        Test.stopTest();
        
    }
}