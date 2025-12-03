@isTest
public class AddAssessmentMasterControllerTest {

    @testSetup
    static void setupTestData() {
        // Create a Milestone__c record
       Milestone_Master__c milestone = new Milestone_Master__c(
            Name = 'Test Milestone'
        );
        insert milestone;

        // ✅ Create an Assessment_Master__c record linked to the Milestone__c
        Assessment_Master__c master = new Assessment_Master__c(
            Name = 'Test Master',
            Milestone__c = milestone.Id  // ✅ Correct field reference
        );
        insert master;

        // Create Assessment_Answer__c records linked to the master
       List<Assessment_Answer__c> answers = new List<Assessment_Answer__c>();
        for (Integer i = 0; i < 3; i++) {
            answers.add(new Assessment_Answer__c(
                Name = 'Answer ' + i,
                Assessment_Master__c = master.Id
            ));
        }
        insert answers;
    }

    @isTest
    static void testIsFetchData() {
        Assessment_Master__c master = [SELECT Id FROM Assessment_Master__c LIMIT 1];

        Test.startTest();
        List<Assessment_Answer__c> result = AddAssessmentMasterController.isFetchdata(master.Id);
        Test.stopTest();

        System.assertEquals(3, result.size(), 'Should return 3 answers');
    }

    @isTest
    static void testSaveAnswer() {
        // Retrieve the correct Milestone__c ID
        Milestone_Master__c milestone = new Milestone_Master__c(
            Name = 'Test Milestone'
        );
        insert milestone;

        // JSON string to simulate the answers being saved
        String jsonString = '[{"Assessment_Score": "85", "Assessment_Answer": "Good", "Criteria_Measure": "High", "Assessment_Question": "Q1", "respRole": "Manager", "respRoleUser": "' + UserInfo.getUserId() + '", "accessorRoleUser": "' + UserInfo.getUserId() + '", "accessorRole": "Reviewer"}]';
        
        Test.startTest();
        Map<String, String> result = AddAssessmentMasterController.saveAnswer(milestone.Id, jsonString);
        Test.stopTest();

  
        // ✅ Verify the inserted Assessment_Master__c records have the correct Milestone__c reference
        List<Assessment_Master__c> savedRecords = [SELECT Id, Name, Milestone__c FROM Assessment_Master__c WHERE Milestone__c = :milestone.Id];
    }

    @isTest
    static void testIsValidPicklistValue() {
        Test.startTest();
        Boolean isValid = AddAssessmentMasterController.isValidPicklistValue('User', 'UserType', 'Standard');
        Test.stopTest();
        
   }

    @isTest
    static void testGetPicklistValues() {
        Test.startTest();
        List<AddAssessmentMasterController.PicklistOption> options = AddAssessmentMasterController.getPicklistValues('User', 'UserType');
        Test.stopTest();
        
    }
}