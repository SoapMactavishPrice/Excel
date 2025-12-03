@isTest
public class AddMilestoneControllerTest {
    
    @testSetup
    static void setupTestData() {
        Milestone_Master__c milestoneMaster = new Milestone_Master__c(
            Name = 'Test Milestone',
            Product_Group__c = 'Polymer Additives',
            Milestone_Code__c = 'TM001',
            Milestone_Description__c = 'Test Description',
            Milestone_Sequence__c = 1
        );
        insert milestoneMaster;
        
        Assessment_Master__c assessmentMaster = new Assessment_Master__c(
            Name = 'Test Assessment',
            Milestone__c = milestoneMaster.Id,
            Question_Type__c = 'Picklist',
            Assessment_Question__c = 'Test Question',
            Criteria_Measure__c = 'Measure 1',
            Assessment_Remarks__c = 'Remark 1'
        );
        insert assessmentMaster;
        
        Decision_Criteria_Master__c decisionMaster = new Decision_Criteria_Master__c(
            Name = 'Test Decision',
            Milestone__c = milestoneMaster.Id,
            Question__c = 'Decision Question',
            Decision__c = 'Go'
        );
        insert decisionMaster;
        
        Opportunity opty = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert opty;
        
        Milestone__c milestone = new Milestone__c(
            Name = 'Linked Milestone',
            Opportunity__c = opty.Id,
            Milestone__c = milestoneMaster.Id,
            Milestone_Code__c = 'TM001',
            Milestone_Sequence__c = 1,
            Product_Group__c = milestoneMaster.Product_Group__c,
            Milestone_Description__c = 'Test Description'
        );
        insert milestone;
    }
    
    @isTest
    static void testGetGlobalPicklistValues() {
        Test.startTest();
        List<Object> picklistValues = AddMilestoneController.getGlobalPicklistValues('Product_Group__c');
        Test.stopTest();
    }
    
    @isTest
    static void testGetMilesStone() {
        Test.startTest();
        List<Milestone_Master__c> milestones = AddMilestoneController.getMilesStone('Polymer Additives');
        Test.stopTest();
    }
    
    @isTest
    static void testGetAssessmentMaster() {
        Milestone_Master__c milestone = [SELECT Id FROM Milestone_Master__c LIMIT 1];
        Test.startTest();
        List<Assessment_Master__c> assessments = AddMilestoneController.getAssessmentMaster(milestone.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetDescisionCriteria() {
        Milestone_Master__c milestone = [SELECT Id FROM Milestone_Master__c LIMIT 1];
        Test.startTest();
        List<Decision_Criteria_Master__c> decisions = AddMilestoneController.getDescisionCriteria(milestone.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testSaveMilestone() {
        Opportunity opty = [SELECT Id FROM Opportunity LIMIT 1];
        String jsonData = '[{"Id":"1","Name":"Milestone1","Milestone_Code":"M001","Milestone_Sequence":1,"Product_Group":"Test Group","Milestone_Description":"Test Desc"}]';
        Test.startTest();
        Map<String, String> result = AddMilestoneController.saveMilestone(opty.Id, jsonData);
        Test.stopTest();
    }
    
    @isTest
    static void testSaveAssessment() {
        Opportunity opty = [SELECT Id FROM Opportunity LIMIT 1];
        Milestone_Master__c milestone = [SELECT Id FROM Milestone_Master__c LIMIT 1];
        String milestoneIds = '["' + milestone.Id + '"]';
        Test.startTest();
        Map<String, String> result = AddMilestoneController.saveAssessment(opty.Id, milestoneIds);
        Test.stopTest();
    }
    
    @isTest
    static void testSaveDecision() {
        Opportunity opty = [SELECT Id FROM Opportunity LIMIT 1];
        Milestone_Master__c milestone = [SELECT Id FROM Milestone_Master__c LIMIT 1];
        String milestoneIds = '["' + milestone.Id + '"]';
        Test.startTest();
        Map<String, String> result = AddMilestoneController.saveDecision(opty.Id, milestoneIds);
        Test.stopTest();
    }
}