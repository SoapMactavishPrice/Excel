@isTest
public class SampleDispatchToHandlerTest {
    
    @isTest
    static void testUpdateAddressInformation() {
        // Step 1: Create test data for related objects
         Country__c testCountry = new Country__c(Name = 'India');
        insert testCountry;
        
        State__c testState = new State__c(Name = 'Test State', Country__c = testCountry.Id);
        insert testState;
        
        City__c testCity = new City__c(Name = 'Test City', State__c = testState.Id, Country__c = testCountry.Id);
        insert testCity;
        
        Area__c testArea = new Area__c(Name = 'Test Area', City__c = testCity.Id, State__c = testState.Id, Country__c = testCountry.Id);
        insert testArea;
        
        Postal_Code__c testPostalCode = new Postal_Code__c(Name = '12345', Area__c = testArea.Id, City__c = testCity.Id, State__c = testState.Id, Country__c = testCountry.Id);
        insert testPostalCode;
        
          // Create a Sample_Booking__c record (since it's required)
        Sample_Booking__c sampleBooking = new Sample_Booking__c();
        insert sampleBooking;
        
        
        // Step 2: Create test records for Sample_Dispatch_To__c
        Sample_Dispatch_To__c dispatchRecord1 = new Sample_Dispatch_To__c(
           // Name = 'Dispatch 1',
            Sample_Booking__c = sampleBooking.Id,
            Postal_Code__c = testPostalCode.Id
        );
        
        Sample_Dispatch_To__c dispatchRecord2 = new Sample_Dispatch_To__c(
           // Name = 'Dispatch 2',
            Sample_Booking__c = sampleBooking.Id,
            City__c = testCity.Id
        );
        
        Sample_Dispatch_To__c dispatchRecord3 = new Sample_Dispatch_To__c(
          //  Name = 'Dispatch 3',
            Sample_Booking__c = sampleBooking.Id,
            State__c = testState.Id
        );
        
        List<Sample_Dispatch_To__c> dispatchRecords = new List<Sample_Dispatch_To__c> { dispatchRecord1, dispatchRecord2, dispatchRecord3 };
        insert dispatchRecords;

        // Step 3: Query inserted records to pass into the handler method
        List<Sample_Dispatch_To__c> newDispatchRecords = [SELECT Id, Postal_Code__c, City__c, State__c FROM Sample_Dispatch_To__c];
        
        // Step 4: Call the handler method
        Test.startTest();
        SampleDispatchToHandler.updateAddressInformation(newDispatchRecords);
        Test.stopTest();

        // Step 5: Validate the results
        List<Sample_Dispatch_To__c> updatedDispatchRecords = [
            SELECT Id, Postal_Code__c, City__c, State__c, Country__c
            FROM Sample_Dispatch_To__c
        ];

        for (Sample_Dispatch_To__c record : updatedDispatchRecords) {
            if (record.Postal_Code__c == testPostalCode.Id) {
                System.assertEquals(testPostalCode.City__c, record.City__c, 'City should match for Postal Code');
                System.assertEquals(testPostalCode.State__c, record.State__c, 'State should match for Postal Code');
                System.assertEquals(testPostalCode.Country__c, record.Country__c, 'Country should match for Postal Code');
            } else if (record.City__c == testCity.Id) {
                System.assertEquals(testCity.State__c, record.State__c, 'State should match for City');
                System.assertEquals(testCity.Country__c, record.Country__c, 'Country should match for City');
            } else if (record.State__c == testState.Id) {
                System.assertEquals(testState.Country__c, record.Country__c, 'Country should match for State');
            }
        }
    }
}