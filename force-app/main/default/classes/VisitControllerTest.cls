@isTest
public class VisitControllerTest {
    
    @isTest
    static void testCreateVisits_WithExternalContact() {
        // Step 1: Create test Account and Contact (external contact)
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(FirstName = 'External', LastName = 'Contact', AccountId = testAccount.Id, Email = 'external@example.com');
        insert testContact;

        // Create test User (internal attendee)
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User1',
            Email = 'testuser1@example.com',
            Username = 'testuser1@example.com.' + System.currentTimeMillis(),
            Alias = 'tuser1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // Step 2: Build JSON with external contact for an Account
        String visitJson = '[{' +
            '"purpose": "Account Visit",' +
            '"description": "Follow-up meeting",' +
            '"startDateTime": "2025-06-01T09:00:00.000Z",' +
            '"endDateTime": "2025-06-01T10:00:00.000Z",' +
            '"accountId": "' + testAccount.Id + '",' +
            '"objectType": "Account",' +
            '"attendees": [{' +
                '"id": "' + testUser.Id + '"' +
            '}],' +
            '"externalContacts": [{' +
                '"id": "' + testContact.Id + '"' +
            '}]' +
        '}]';

        Test.startTest();
        Map<String, Object> result = VisitController.createVisits(visitJson);
        Test.stopTest();

        // Step 3: Validate response
        System.assertEquals('Success', result.get('Message'), 'Expected success message');

        // Step 4: Validate Event created
        List<Event> events = [
            SELECT Id, WhatId, WhoId, Subject, Description, StartDateTime, EndDateTime
            FROM Event
            WHERE WhatId = :testAccount.Id
        ];
        System.assertEquals(1, events.size(), 'One event should be created');
        Event createdEvent = events[0];
        System.assertEquals('Account Visit', createdEvent.Subject);
        System.assertEquals('Follow-up meeting', createdEvent.Description);

        // For external contacts used as WhoId, you may need to update controller logic to set it.
        // For now, validate that WhoId is null (as per current code) or set it manually in controller if needed.

        // Step 5: Validate EventRelation for internal attendee
        List<EventRelation> attendeeRelations = [
            SELECT Id, EventId, RelationId
            FROM EventRelation
            WHERE EventId = :createdEvent.Id AND RelationId = :testUser.Id
        ];
        System.assertEquals(1, attendeeRelations.size(), 'Internal attendee should be linked');

        // Step 6: Validate EventRelation for external contact
        List<EventRelation> externalRelations = [
            SELECT Id, EventId, RelationId
            FROM EventRelation
            WHERE EventId = :createdEvent.Id AND RelationId = :testContact.Id
        ];
        System.assertEquals(1, externalRelations.size(), 'External contact should be linked');
    }
}