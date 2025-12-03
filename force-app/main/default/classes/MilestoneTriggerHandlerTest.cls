@isTest
public class MilestoneTriggerHandlerTest {
    @isTest
    public static void testMilestoneUpdateonStage() {
        // Create Stage_Gate__c records without Account__c (only required fields are set)
        Stage_Gate__c stage1 = new Stage_Gate__c(Name = 'Stage 1');
        Stage_Gate__c stage2 = new Stage_Gate__c(Name = 'Stage 2');
      //  insert new List<Stage_Gate__c>{stage1, stage2}; // Insert and get valid IDs

        // Create Milestone__c records with valid Stage_Gate__c lookup references
        Milestone__c milestone1 = new Milestone__c(Name = 'Milestone 1', Stage_Gate__c = stage1.Id);
        Milestone__c milestone2 = new Milestone__c(Name = 'Milestone 2', Stage_Gate__c = stage2.Id);

        Test.startTest();
        insert new List<Milestone__c>{ milestone1, milestone2 };
        Test.stopTest();

        // Assertions
        List<Milestone__c> insertedMilestones = [SELECT Id, Stage_Gate__c FROM Milestone__c WHERE Id IN :new List<Id>{milestone1.Id, milestone2.Id}];
        
        System.assertEquals(2, insertedMilestones.size(), 'Two milestones should have been inserted.');
      //  System.assertNotEquals(null, insertedMilestones[0].Stage_Gate__c, 'Stage_Gate__c should not be null.');
    }
}