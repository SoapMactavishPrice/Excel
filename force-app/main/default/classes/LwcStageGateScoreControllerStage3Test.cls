@isTest
public class LwcStageGateScoreControllerStage3Test {
    
    @TestSetup
    static void setupTestData() {
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
        
        // Create Milestone with all required fields
        Milestone__c milestone = new Milestone__c(
            Name = 'Test Milestone',
            Stage_Gate__c = stageGate.Id,
            Staging__c = 'Stage 3'
           // Opportunity__c = testOpp.Id
            // Add any other required fields based on your validation rules
           // Stage_Start_Date__c = Date.today() // Example of potentially required field
        );
        insert milestone;
        
        // Create test Assessment Master
        Assessment_Master__c assessmentMaster = new Assessment_Master__c(
            Name = 'Test Assessment Master',
            Milestone__c = milestone.Id
        );

        
        
        // Create test Assessment Criteria
        Assessment_Criteria__c assessmentCriteria = new Assessment_Criteria__c(
            Name = 'Test Criteria',
            Assessment_Question__c = 'Test Question',
            Assessment_Master__c = assessmentMaster.Id,
            Milestone__c = milestone.Id,
            Responsibilty_User__c = UserInfo.getUserId(),
            Accessor_User__c = UserInfo.getUserId()
        );
        insert assessmentCriteria;
        
        // Create test Decision Criteria
        Decision_Criteria__c decisionCriteria = new Decision_Criteria__c(
            Name = 'Test Decision Criteria',
            Question__c = 'Test Question',
            Milestone__c = milestone.Id
        );
        insert decisionCriteria;
        
        // Create test content document
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;
        
        
        // Create test Milestone
        Milestone__c milestone1 = new Milestone__c(Name = 'Test Milestone', Staging__c = 'Stage 3');
        insert milestone1;

        // Create test users
        User respUser = [SELECT Id FROM User WHERE Profile.Name != 'Guest' LIMIT 1];
        User accessorUser = [SELECT Id FROM User WHERE Profile.Name != 'Guest' LIMIT 1 OFFSET 1];

        // Create Assessment_Criteria__c record
        Assessment_Criteria__c ac = new Assessment_Criteria__c(
            Name = 'Test Criteria',
            Milestone__c = milestone.Id,
            Assessment_Question__c = 'What is your decision?',
            Responsibilty_User__c = respUser.Id,
            Accessor_User__c = accessorUser.Id
        );
        insert ac;

        // Create ContentVersion (automatically creates ContentDocument)
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test file content')
        );
        insert cv;

        // Get ContentDocumentId
        ContentDocument doc = [SELECT Id FROM ContentDocument /*WHERE Id =: cv.ContentDocumentId*/ LIMIT 1];

        // Link ContentDocument to Milestone via ContentDocumentLink
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = doc.Id,
            LinkedEntityId = milestone.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        
    }
    
    // Helper method to get content document link
    private static Id setupContentDocumentLink(Id milestoneId) {
        ContentDocument contentDocument = [SELECT Id FROM ContentDocument LIMIT 1];
        ContentDocumentLink contentLink = new ContentDocumentLink(
            ContentDocumentId = contentDocument.Id,
            LinkedEntityId = milestoneId,
            ShareType = 'V'
        );
        insert contentLink;
        return contentLink.Id;
    }
    
    @isTest
    static void testGetRecordDetail() {
        Milestone__c milestone = [SELECT Id FROM Milestone__c LIMIT 1];
        
        Test.startTest();
        Milestone__c result = LwcStageGateScoreControllerStage3.getRecordDetail(milestone.Id);
        Test.stopTest();
        
        System.assertEquals(milestone.Id, result.Id, 'Should return the correct milestone record');
    }
    
   
    
    @isTest
    static void testGetAssessmentAnswer() {
        Milestone__c milestone = [SELECT Id FROM Milestone__c LIMIT 1];
        
        Test.startTest();
        List<Assessment_Master__c> result = LwcStageGateScoreControllerStage3.getAssessmentAnswer(milestone.Id);
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testGetDescisionCriteria() {
        Milestone__c milestone = [SELECT Id FROM Milestone__c LIMIT 1];
        
        Test.startTest();
        List<Decision_Criteria__c> result = LwcStageGateScoreControllerStage3.getDescisionCriteria(milestone.Id);
        Test.stopTest();
        
        System.assertEquals(1, result.size(), 'Should return decision criteria');
        System.assertEquals('Test Decision Criteria', result[0].Name, 'Should return correct criteria');
    }
    
    
    @isTest
    static void testSaveDataWithScoreAbove15() {
                Milestone_Master__c milestoneMaster = new Milestone_Master__c(
            Name = 'Milestone Master 1',Staging__c ='Stage 1',Timelines_in_Days__c=20
        );
        insert milestoneMaster;
        
         // Step 1: Create Milestone__c record (as before)
        Milestone__c milestone = new Milestone__c(
            Name = 'Test Milestone',
            Staging__c = 'Stage 1'
        );
        insert milestone;
        
        
            
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
             Map<String, String> result = LwcStageGateScoreControllerStage3.saveData(jsonJS, descJS, 16, milestone.Id, 'Go','Reject',true,'ok');
        Map<String, String> result1 = LwcStageGateScoreControllerStage3.saveData(jsonJS, descJS, 16, milestone.Id, 'Go','Pending',false,'ok');
        Map<String, String> result2 = LwcStageGateScoreControllerStage3.saveData(jsonJS, descJS, 16, milestone.Id, 'Go','Approved',false,'ok');
                Map<String, String> result3 = LwcStageGateScoreControllerStage3.saveData(jsonJS, descJS, 16, milestone.Id, 'Go','Approved',true,'ok');

            Test.stopTest();
        
      
        
        // Verify milestone was updated
        Milestone__c updatedMilestone = [SELECT Final_Outcome__c, Overall_Decision_by_CEO__c FROM Milestone__c WHERE Id = :milestone.Id];
       
    }
    
    
    @isTest
    static void testGetRecordDetail1() {
        Milestone__c milestone = [SELECT Id FROM Milestone__c LIMIT 1];
        Milestone__c result = LwcStageGateScoreControllerStage3.getRecordDetail(milestone.Id);
    }
    
    
    @isTest
    static void testGetFiledDisplay() {
        Milestone__c milestone = [SELECT Id FROM Milestone__c LIMIT 1];
        String result = LwcStageGateScoreControllerStage3.getFiledDisplay(milestone.Id);
        
        List<LwcStageGateScoreControllerStage3.dataChildWrapper> fileList = (List<LwcStageGateScoreControllerStage3.dataChildWrapper>) JSON.deserialize(result, List<LwcStageGateScoreControllerStage3.dataChildWrapper>.class);
    }
	
    @isTest
    static void testGetRecordDetail12() {
        Milestone__c ms = [SELECT Id FROM Milestone__c LIMIT 1];
        Test.startTest();
        Milestone__c result = LwcStageGateScoreControllerStage3.getRecordDetail(ms.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetAssessmentMaster() {
        Milestone__c ms = [SELECT Id FROM Milestone__c LIMIT 1];
        Test.startTest();
        List<Assessment_Criteria__c> result = LwcStageGateScoreControllerStage3.getAssessmentMaster(ms.Id);
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
        String result = LwcStageGateScoreControllerStage3.deletefile(cdl.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetDocumentUrl() {
        // Step 1: Create a test Milestone record
        Milestone__c milestone = new Milestone__c(Name = 'Test Milestone', Staging__c = 'Stage 3');
        insert milestone;
        
        // Step 2: Create a ContentVersion (this creates a ContentDocument automatically)
        ContentVersion cv = new ContentVersion(
            Title = 'Test PDF',
            PathOnClient = 'TestPDF.pdf',
            VersionData = Blob.valueOf('Dummy content')
        );
        insert cv;
        
        // Step 3: Query to get the newly created ContentDocumentId
        ContentVersion insertedCV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        Id contentDocId = insertedCV.ContentDocumentId;
        
        // Step 4: Create ContentDocumentLink
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocId,
            LinkedEntityId = milestone.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        Test.startTest();
        String result = LwcStageGateScoreControllerStage3.getDocumentUrl(cdl.Id);
        Test.stopTest();
        
    }
    
}