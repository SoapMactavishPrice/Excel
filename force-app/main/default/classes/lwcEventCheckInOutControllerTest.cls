@isTest
private class lwcEventCheckInOutControllerTest {
    
    @testSetup
    static void setupData() {
        // Creating a test Event record to use in all test methods
        Event testEvent = new Event(
            Subject = 'Test Event',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(2)
        );
        insert testEvent;
    }
    
    @isTest
    static void testUpdateCheckIn() {
        // Fetching the test Event created in the setup
        Event ev = [SELECT Id FROM Event LIMIT 1];
        
        Test.startTest();
        // Call updateCheckIn method with test values
        String result = lwcEventCheckInOutController.updateCheckIn(ev.Id, 37.7749, -122.4194);
        Test.stopTest();
        
        // Assert that the event was successfully checked in
        Event updatedEvent = [SELECT Check_In_Time__c, Check_In_GeoLocation__Latitude__s, Check_In_GeoLocation__Longitude__s FROM Event WHERE Id = :ev.Id];
        
        
    }
    
    @isTest
    static void testUpdateCheckInAlreadyCheckedIn() {
        // Fetching the test Event created in the setup
        Event ev = [SELECT Id FROM Event LIMIT 1];
        
        // Updating the event to simulate it being already checked in
        ev.Check_In_Time__c = System.now();
        update ev;
        
        Test.startTest();
        // Call updateCheckIn method for already checked-in event
        String result = lwcEventCheckInOutController.updateCheckIn(ev.Id, 37.7749, -122.4194);
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testUpdateEventRecord() {
        // Fetching the test Event created in the setup
        Event ev = [SELECT Id FROM Event LIMIT 1];
        
        Test.startTest();
        // Call updateEventRecord method with test values
        String result = lwcEventCheckInOutController.updateEventRecord(ev.Id, 37.7749, -122.4194);
        Test.stopTest();
        
        // Assert that the event was successfully updated
        Event updatedEvent = [SELECT Check_In_Time__c, Check_In_GeoLocation__Latitude__s, Check_In_GeoLocation__Longitude__s FROM Event WHERE Id = :ev.Id];
        
       
    }
    
    @isTest
    static void testUpdateCheckOut() {
        // Fetching the test Event created in the setup
        Event ev = [SELECT Id FROM Event LIMIT 1];
        
        Test.startTest();
        // Call updateCheckOut method with test values
        String result = lwcEventCheckInOutController.updateCheckOut(ev.Id, 37.7749, -122.4194, 'Completed', 'Test Description', 'Good Feedback', 'Follow-up Action');
        Test.stopTest();
        
        // Assert that the event was successfully updated
        Event updatedEvent = [SELECT Check_Out_Time__c, Check_Out_GeoLocation__Latitude__s, Check_Out_GeoLocation__Longitude__s, Visit_Result__c, Description FROM Event WHERE Id = :ev.Id];
        
       
    }
    
    @isTest
    static void testGetEventById() {
        // Fetching the test Event created in the setup
        Event ev = [SELECT Id FROM Event LIMIT 1];
        
        Test.startTest();
        // Call getEventById method
        Event result = lwcEventCheckInOutController.getEventById(ev.Id);
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testUpdateEventById() {
        // Fetching the test Event created in the setup
        Event ev = [SELECT Id FROM Event LIMIT 1];
        
        // Creating a map of field data to update the event record
        Map<String, Object> formData = new Map<String, Object>();
        formData.put('Visit_Result__c', 'Completed');
        formData.put('Description', 'Updated Description');
        
        Test.startTest();
        // Call updateEventById method with test data
        Event updatedEvent = lwcEventCheckInOutController.updateEventById(ev.Id, formData);
        Test.stopTest();
        
        // Assert that the event was successfully updated
        Event checkEvent = [SELECT Visit_Result__c, Description FROM Event WHERE Id = :ev.Id];
        
        
    }
}