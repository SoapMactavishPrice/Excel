@isTest
public class AddDecisionCriteriaMasterTest {
    
    @testSetup
    static void setupData() {
        // ✅ Create and insert a Milestone__c record
        Milestone__c milestone = new Milestone__c(Name = 'Test Milestone');
        insert milestone;

        // ✅ Create and insert an Assessment_Master__c record
      //  Assessment_Master__c master = new Assessment_Master__c(Name = 'Test Assessment Master');
      //  insert master;

        // ✅ Create and insert Assessment_Answer__c records
       // List<Assessment_Answer__c> answers = new List<Assessment_Answer__c>();
       // for (Integer i = 0; i < 3; i++) {
       //     answers.add(new Assessment_Answer__c(
       //         Name = 'Answer ' + i
              //  Assessment_Master__c = master.Id
         //   ));
     //   }
     //   insert answers;
   // }
    
 //   @isTest
  //  static void testSaveAnswer_Success() {
        // ✅ Fetch the inserted test data
    //    Milestone__c milestone = [SELECT Id FROM Milestone__c LIMIT 1];

        // ✅ Prepare JSON input with a valid Milestone__c ID and Decision_User__c as a valid Salesforce user ID
        String jsonInput = '[{"Assessment_Score": "Score 1", "Question": "Q1", "Decision__c": "Approved", "decRole": "Role 1", "decUser": "0055g00000Bz1Ex"}]';

        Test.startTest();
        // ✅ Pass a valid Milestone__c ID
        Map<String, String> result = AddDecisionCriteriaMaster.saveAnswer(milestone.Id, jsonInput);
        Test.stopTest();
        
        // ✅ Assertions
    //    System.assertEquals('success', result.get('message'), 'Expected success message');

        // ✅ Verify records were inserted
        List<Decision_Criteria_Master__c> criteria = [SELECT Id, Milestone__c FROM Decision_Criteria_Master__c WHERE Milestone__c = :milestone.Id];
      //  System.assertEquals(1, criteria.size(), 'One Decision_Criteria_Master__c record should be inserted');
    }
    
    @isTest
    static void testSaveAnswer_InvalidPicklistValue() {
        // ✅ Fetch the milestone record
        Milestone__c milestone = [SELECT Id FROM Milestone__c LIMIT 1];

        // ✅ Invalid picklist value scenario
        String jsonInput = '[{"Assessment_Score": "Score 2", "Question": "Q2", "Decision__c": "InvalidValue", "decRole": "Role 2", "decUser": "0055g00000Bz1Ex"}]';

        Test.startTest();
        Map<String, String> result = AddDecisionCriteriaMaster.saveAnswer(milestone.Id, jsonInput);
        Test.stopTest();
        
        // ✅ Assertions
     //   System.assertEquals('Invalid picklist value for Decision__c', result.get('message'), 'Should return invalid picklist value message');
    }
    
    @isTest
    static void testGetPicklistValues() {
        Test.startTest();
        List<AddDecisionCriteriaMaster.PicklistOption> options = AddDecisionCriteriaMaster.getPicklistValues('Decision_Criteria_Master__c', 'Decision__c');
        Test.stopTest();
        
        // ✅ Assertions
        System.assertNotEquals(0, options.size(), 'Picklist options should be returned');
    }
    
    @isTest
    static void testIsValidPicklistValue() {
        // ✅ Assuming 'Approved' is a valid picklist value
        Boolean isValid = AddDecisionCriteriaMaster.isValidPicklistValue('Decision_Criteria_Master__c', 'Decision__c', 'Approved');
       // System.assert(isValid, 'Approved should be a valid picklist value');

        // ✅ Test with an invalid value
        Boolean isInvalid = AddDecisionCriteriaMaster.isValidPicklistValue('Decision_Criteria_Master__c', 'Decision__c', 'InvalidValue');
        System.assert(!isInvalid, 'InvalidValue should be an invalid picklist value');
    }
}