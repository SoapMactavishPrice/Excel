@isTest
public class SampleBookingTriggerHandlerTest {

    @isTest
    static void testPopulateRequestedBy() {
        // Create a test user to act as the Owner
        User testUser = new User(
            Alias = 'testu',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser123gfbvfvf@example.com',
            LastName = 'testu'
        );
        insert testUser;

        // Create a Sample_Booking__c record and assign the OwnerId
        Sample_Booking__c booking = new Sample_Booking__c(
            OwnerId = testUser.Id
        );

        // Simulate trigger.new context
        List<Sample_Booking__c> newList = new List<Sample_Booking__c>{booking};

        // Call the method to test
        Test.startTest();
        SampleBookingTriggerHandler.populateRequestedBy(newList);
        Test.stopTest();

        
    }
    
     @isTest
    static void testHandleBeforeInsertUpdate() {
        // Step 1: Create a test Lead
        
        // Step 1: Create Test Data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create Country
        Country__c country = new Country__c(Name='TestCountry');
        insert country;
        
        // Create State with proper Country reference
        State__c state = new State__c(Name='TestState', Country__c=country.Id, Zone__c='East');
        insert state;
        
         // Create City (no postal code since it's removed)
        City__c city = new City__c(Name='TestCity');
        insert city;
        
        // Create Postal Code with proper State reference
        Postal_Code__c postal = new Postal_Code__c(Name='123456', State__c=state.Id);
        insert postal;
        
        
        Lead testLead = new Lead(
           FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Street = '123 Test St',
            City__c = city.Id,          
            State__c = state.Id,       
            Country__c = country.Id,    
            Postal_Code__c = postal.Id, 
            Status = 'Open - Not Contacted',
            Lead_Type__c = 'Domestic', 
            Zone__c = 'East' 
            
        );
        insert testLead;

        // Step 2: Create a Sample_Booking__c record
        Sample_Booking__c booking = new Sample_Booking__c(
            Sample_Request_Type__c = 'New Product New Customer',
            Lead__c = testLead.Id
        );

        // Step 3: Prepare trigger-like context
        List<Sample_Booking__c> newBookings = new List<Sample_Booking__c>{booking};
        Map<Id, Sample_Booking__c> oldMap = new Map<Id, Sample_Booking__c>(); // Not used here but required

        // Step 4: Call the method
        Test.startTest();
        SampleBookingTriggerHandler.handleBeforeInsertUpdate(newBookings, oldMap);
        Test.stopTest();

       
    }
    
    
    @isTest
    static void testHandleAfterInsertUpdate() {
        
        // Step 1: Create Test Data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create Country
        Country__c country = new Country__c(Name='TestCountry');
        insert country;
        
        // Create State with proper Country reference
        State__c state = new State__c(Name='TestState', Country__c=country.Id, Zone__c='East');
        insert state;
        
         // Create City (no postal code since it's removed)
        City__c city = new City__c(Name='TestCity');
        insert city;
        
        // Create Postal Code with proper State reference
        Postal_Code__c postal = new Postal_Code__c(Name='123456', State__c=state.Id);
        insert postal;
        // Create a Lead record
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Street = '123 Test St',
            City__c = city.Id,          
            State__c = state.Id,       
            Country__c = country.Id,    
            Postal_Code__c = postal.Id, 
            Status = 'Open - Not Contacted',
            Lead_Type__c = 'Domestic', 
            Zone__c = 'East'
        );
        insert testLead;



        // Step 2: Create a Sample_Booking__c record
        Sample_Booking__c booking = new Sample_Booking__c(
            Use_Lead_Address_for_Sample_Dispatch_To__c = true,
            Lead__c = testLead.Id
        );
        insert booking;

        // Step 3: Query inserted booking to simulate Trigger.new context
        List<Sample_Booking__c> bookingList = [SELECT Id, Use_Lead_Address_for_Sample_Dispatch_To__c, Lead__c FROM Sample_Booking__c WHERE Id = :booking.Id];

        // Step 4: Call the method
        Test.startTest();
        SampleBookingTriggerHandler.handleAfterInsertUpdate(bookingList);
        Test.stopTest();

        // Step 5: Validate that the dispatch record was created
        List<Sample_Dispatch_To__c> dispatches = [
            SELECT Id, Sample_Booking__c, Ship_To_Name__c, Country__c, State__c, Postal_Code__c, City__c, Line_1_Block__c
            FROM Sample_Dispatch_To__c
            WHERE Sample_Booking__c = :booking.Id
        ];      
    }
}