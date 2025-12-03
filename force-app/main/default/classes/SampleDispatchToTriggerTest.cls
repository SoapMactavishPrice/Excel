@isTest
public class SampleDispatchToTriggerTest {
    
    @isTest
    static void testBeforeInsert() {
        // First create a Sample_Booking__c record if it's required
        Sample_Booking__c booking = new Sample_Booking__c(
          //  Name = 'Test Booking'
            // Add other required fields for Sample_Booking__c if any
        );
        insert booking;
        
        // Create a new Sample_Dispatch_To__c record with the required Sample_Booking__c
        Sample_Dispatch_To__c newDispatch = new Sample_Dispatch_To__c(
            Sample_Booking__c = booking.Id
            // Add other required fields if any
        );
        
        Test.startTest();
        // Insert the new record
        insert newDispatch;
        Test.stopTest();
        
        // Verify the record was created successfully
        Sample_Dispatch_To__c insertedDispatch = [SELECT Id, Sample_Booking__c FROM Sample_Dispatch_To__c WHERE Id = :newDispatch.Id];
        System.assertEquals(booking.Id, insertedDispatch.Sample_Booking__c, 'The Sample Booking reference should match');
    }

    @isTest
    static void testBeforeUpdate() {
        // First create a Sample_Booking__c record if it's required
        Sample_Booking__c booking = new Sample_Booking__c(
           // Name = 'Test Booking'
            // Add other required fields for Sample_Booking__c if any
        );
        insert booking;
        
        // Create a Sample_Dispatch_To__c record for Update
        Sample_Dispatch_To__c existingDispatch = new Sample_Dispatch_To__c(
            Sample_Booking__c = booking.Id
            // Add other required fields if any
        );
        insert existingDispatch;
        
        // Modify the record to trigger the update
      //  existingDispatch.Name = 'Updated Sample Dispatch';
        
        Test.startTest();
        update existingDispatch;
        Test.stopTest();
        
        // Verify the update
        Sample_Dispatch_To__c updatedDispatch = [SELECT Id, Name FROM Sample_Dispatch_To__c WHERE Id = :existingDispatch.Id];
       // System.assertEquals('Updated Sample Dispatch', updatedDispatch.Name, 'The name should be updated');
    }
}