@isTest
public class StageGateTriggerTest {
    
    @testSetup
    static void setupTestData() {
        // Create a test Milestone Master record
        Milestone_Master__c milestoneMaster = new Milestone_Master__c(
            Name = 'Assess Feasibility',
            Milestone_Code__c = 'M001',
            Staging__c = 'Stage 1',
            Milestone_Description__c = 'Test Milestone Description',
            Timelines_in_Days__c = 10,
            Milestone_Sequence__c = 1,
            Product_Group__c = 'Agrochemicals'
        );
        insert milestoneMaster;
        
        // Fetch a valid profile
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create test users
        User user1 = new User(
            FirstName = 'User',
            LastName = 'A',
            Alias = 'usera',
            Email = 'usera@example.com',
            Username = 'usera' + System.currentTimeMillis() + '@test.com', // Unique username
            ProfileId = userProfile.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert user1;
        
        User user2 = new User(
            FirstName = 'User',
            LastName = 'B',
            Alias = 'userb',
            Email = 'userb@example.com',
            Username = 'userb' + System.currentTimeMillis() + '@test.com', // Unique username
            ProfileId = userProfile.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert user2;

        // Create test Assessment Master record
        Assessment_Master__c assessmentMaster = new Assessment_Master__c(
            Name = 'Test Assessment',
            Milestone__c = milestoneMaster.Id,
            Question_Type__c = 'Number',
            Assessment_Question__c = 'Sample Question?',
            Criteria_Measure__c = 'Test Measure',
            Responsibilty_Role__c = 'CFO',
            Responsibilty_User__c = user1.id,
            Accessor_User__c = user2.id,
            Accessor_Role__c = 'COO',
            Assessment_Remarks__c = 'Sample Remarks'
        );
        insert assessmentMaster;

        // Create test Decision Criteria Master record
        Decision_Criteria_Master__c decisionMaster = new Decision_Criteria_Master__c(
            Name = 'Test Decision Criteria',
            Milestone__c = milestoneMaster.Id,
            Question__c = 'Decision Question?',
            Decision_Role__c = 'COO',
            Decision_User__c = user2.id,
            Decision__c = 'Kill',
            Decision_Rating__c = 'Kill'
        );
        insert decisionMaster;
    }

    @isTest
    static void testStageGateTrigger() {
        Test.startTest();

        // Fetch a valid picklist value for Current Milestone
        String validMilestone = 'Assess Feasibility'; // Change this to a valid picklist value if needed

        // Insert a Stage_Gate__c record with a valid Current Milestone value
        Stage_Gate__c stageGate = new Stage_Gate__c(
            Stage__c = validMilestone
        );
        insert stageGate;

        // Fetch the inserted record
        Stage_Gate__c insertedStageGate = [SELECT Id, Stage__c, Start_Date__c, End_Date__c FROM Stage_Gate__c LIMIT 1];

        // Fetch related Milestone records
        List<Milestone__c> milestones = [SELECT Id, Name, Stage_Gate__c FROM Milestone__c WHERE Stage_Gate__c = :insertedStageGate.Id];

        // Fetch related Assessment Criteria records
        List<Assessment_Criteria__c> assessments = [SELECT Id, Milestone__c FROM Assessment_Criteria__c];

        // Fetch related Decision Criteria records
        List<Decision_Criteria__c> decisions = [SELECT Id, Milestone__c FROM Decision_Criteria__c];

        Test.stopTest();
    }
}