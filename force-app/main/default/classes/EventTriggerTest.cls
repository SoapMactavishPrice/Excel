@isTest
public class EventTriggerTest {

    @isTest
    static void testInsertEvent() {
        // Create test Event record
        Event testEvent = new Event(
            Subject = 'Test Meeting',
            StartDateTime = System.now().addDays(1),
            EndDateTime = System.now().addDays(1).addHours(1),
            DurationInMinutes = 60
        );
        insert testEvent;
    }

    @isTest
    static void testUpdateEvent() {
        // Create and insert an Event
        Event testEvent = new Event(
            Subject = 'Initial Meeting',
            StartDateTime = System.now().addDays(2),
            EndDateTime = System.now().addDays(2).addHours(1),
            DurationInMinutes = 60
        );
        insert testEvent;

        // Update the Event
        testEvent.Subject = 'Updated Meeting';
        update testEvent;

        // Assert the update
        Event updatedEvent = [SELECT Subject FROM Event WHERE Id = :testEvent.Id];
    }
}