@IsTest
public class lwcAssessmentAnswerControllerTest {

    @TestSetup
    static void setupTestData() {
        // ✅ Create a Milestone_Master__c record
        Milestone_Master__c milestone = new Milestone_Master__c(
            Name = 'Test Milestone'
        );
        insert milestone;
        
        // ✅ Create an Assessment_Master__c record correctly linked to Milestone_Master__c
        Assessment_Master__c master = new Assessment_Master__c(
            Name = 'Test Master',
            Milestone__c = milestone.Id  // ✅ Correct field reference
        );
        insert master;
        
        // ✅ Create Assessment_Answer__c records linked to the master
        List<Assessment_Answer__c> answers = new List<Assessment_Answer__c>();
        for (Integer i = 0; i < 3; i++) {
            answers.add(new Assessment_Answer__c(
                Name = 'Answer ' + i,
                Assessment_Master__c = master.Id
            ));
        }
        insert answers;
    }


    
    @IsTest
    static void testIsFetchdata() {
        // Get test Assessment_Master__c record
        Assessment_Master__c testMaster = [SELECT Id FROM Assessment_Master__c LIMIT 1];

        // Call isFetchdata method
        Test.startTest();
        List<Assessment_Answer__c> aaList = lwcAssessmentAnswerController.isFetchdata(testMaster.Id);
        Test.stopTest();

     }

    @IsTest
    static void testSaveAnswer() {
        // Get test Assessment_Master__c record
        Assessment_Master__c testMaster = [SELECT Id FROM Assessment_Master__c LIMIT 1];

        // Create JSON string to simulate LWC input
        String jsonInput = '[{"Assessment_Score": "Score 2", "Assessment_Answer": "Answer 2"}]';

        // Call saveAnswer method
        Test.startTest();
        Map<String, String> result = lwcAssessmentAnswerController.saveAnswer(testMaster.Id, jsonInput);
        Test.stopTest();

        // Query inserted records
        List<Assessment_Answer__c> insertedAnswers = [SELECT Name, Assessment_Answer__c FROM Assessment_Answer__c WHERE Assessment_Master__c = :testMaster.Id];

   }
}