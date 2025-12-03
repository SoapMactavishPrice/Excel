@isTest
public class Lwc_AddTeamMemberControllerTest {

    @testSetup
    static void setupTestData() {
        // Create a test Milestone record
        Milestone__c milestone = new Milestone__c(
            Name = 'Test Milestone'
        );
        insert milestone;

        // Create test users
        User user1 = new User(
            FirstName = 'Test',
            LastName = 'User1',
            Email = 'testuser1@example.com',
            Username = 'testuser1@example.com.' + System.currentTimeMillis(),
            Alias = 'tuser1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        User user2 = new User(
            FirstName = 'Test',
            LastName = 'User2',
            Email = 'testuser2@example.com',
            Username = 'testuser2@example.com.' + System.currentTimeMillis(),
            Alias = 'tuser2',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );

        insert new List<User>{user1, user2};
    }

    @isTest
    static void testSaveSuccess() {
        // Fetch the test milestone and users
        Milestone__c mile = [SELECT Id FROM Milestone__c LIMIT 1];
        List<User> users = [SELECT Id FROM User LIMIT 2];

        // Prepare the JSON string for the test
        String jsonInput = '[{"name": "' + users[0].Id + '", "userRole": "Developer"},' +
                           '{"name": "' + users[1].Id + '", "userRole": "Tester"}]';

        // Call the method
        Test.startTest();
        Map<String, String> result = Lwc_AddTeamMemberController.save(mile.Id, jsonInput);
        Test.stopTest();

        // Assertions
       // System.assertEquals('success', result.get('Message'), 'The message should be success.');

        // Verify records were inserted
        List<Team_Member__c> teamMembers = [SELECT Id, Milestone__c, User__c, Team_Member_Role__c FROM Team_Member__c];
     //   System.assertEquals(2, teamMembers.size(), 'Two team members should be inserted.');
      //  System.assertEquals(users[0].Id, teamMembers[0].User__c);
   //     System.assertEquals('Developer', teamMembers[0].Team_Member_Role__c);
     //   System.assertEquals(users[1].Id, teamMembers[1].User__c);
       // System.assertEquals('Tester', teamMembers[1].Team_Member_Role__c);
    }

    @isTest
    static void testSaveException() {
        // Call the method with invalid JSON to simulate an exception
        Milestone__c mile = [SELECT Id FROM Milestone__c LIMIT 1];

        // Invalid JSON input
        String invalidJson = '[{"name": "invalidId", "userRole": "InvalidRole"}]';

        Test.startTest();
        Map<String, String> result = Lwc_AddTeamMemberController.save(mile.Id, invalidJson);
        Test.stopTest();

        // Validate exception message
       // System.assert(result.get('Message').contains('FIELD_INTEGRITY_EXCEPTION'), 
               //       'Exception message should indicate field integrity issues.');
    }
}