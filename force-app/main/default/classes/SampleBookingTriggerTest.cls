@isTest
public class SampleBookingTriggerTest {
    
    @isTest
    static void testBeforeInsertUpdate() {
        // Create a new Sample_Booking__c record for Insert
        Sample_Booking__c newBooking = new Sample_Booking__c(
            // Add necessary field values here
            // Example: Name = 'Sample Booking 1',
            //          Requested_By__c = 'Test User'
        );
        
        Test.startTest();
        // Insert the new record
        insert newBooking;
        Test.stopTest();
        
        // Verify if the trigger behavior works as expected
        // Assert statements go here to check the expected behavior.
        // Example: 
        // System.assertEquals('Expected Value', newBooking.SomeField__c);
    }

    @isTest
    static void testBeforeUpdate() {
        // Create a Sample_Booking__c record for Update
        Sample_Booking__c existingBooking = new Sample_Booking__c(
            // Add necessary field values here
        );
        
        insert existingBooking; // Insert record first
        
       // existingBooking.Name = 'Updated Sample Booking';
        // Update the record as needed
        Test.startTest();
        update existingBooking;
        Test.stopTest();
        
        // Verify if the trigger behavior works as expected after the update
        // Example:
        // System.assertEquals('Updated Sample Booking', existingBooking.Name);
    }

    @isTest
    static void testAfterInsert() {
        // Create a new Sample_Booking__c record for Insert
        Sample_Booking__c newBooking = new Sample_Booking__c(
            // Add necessary field values here
        );
        
        Test.startTest();
        // Insert the new record
        insert newBooking;
        Test.stopTest();
        
        // Verify if the trigger behavior works as expected
        // Example:
        // System.assertEquals('Expected Value after Insert', newBooking.SomeField__c);
    }

    @isTest
    static void testAfterUpdate() {
        // Create a Sample_Booking__c record for Update
        Sample_Booking__c existingBooking = new Sample_Booking__c(
            // Add necessary field values here
        );
        
        insert existingBooking; // Insert record first
        
     //   existingBooking.Name = 'Updated Sample Booking';
        // Update the record as needed
        Test.startTest();
        update existingBooking;
        Test.stopTest();
        
        // Verify if the trigger behavior works as expected after the update
        // Example:
        // System.assertEquals('Updated Sample Booking', existingBooking.Name);
    }
    
}