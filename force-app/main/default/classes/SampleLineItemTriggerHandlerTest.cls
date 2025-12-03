@isTest
public class SampleLineItemTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        // Create Sample Booking records with different currencies
        Sample_Booking__c booking1 = new Sample_Booking__c( CurrencyIsoCode = 'USD');
        Sample_Booking__c booking2 = new Sample_Booking__c( CurrencyIsoCode = 'EUR');
        insert new List<Sample_Booking__c>{booking1, booking2};
        
        // Create Sample Line Item records linked to the bookings
        Sample_Line_Item__c lineItem1 = new Sample_Line_Item__c( Sample_Booking__c = booking1.Id);
        Sample_Line_Item__c lineItem2 = new Sample_Line_Item__c( Sample_Booking__c = booking2.Id);
        Sample_Line_Item__c lineItem3 = new Sample_Line_Item__c(Sample_Booking__c =booking2.Id ); // No booking linked
        
        insert new List<Sample_Line_Item__c>{lineItem1, lineItem2, lineItem3};
    }

    @isTest
    static void testUpdateCurrency() {
        // Retrieve Sample Line Items before update
        List<Sample_Line_Item__c> lineItems = [SELECT Id, Sample_Booking__c, CurrencyIsoCode FROM Sample_Line_Item__c];

        Test.startTest();
        SampleLineItemTriggerHandler.updateCurrency(lineItems);
        Test.stopTest();

        // Retrieve updated records
        List<Sample_Line_Item__c> updatedLineItems = [SELECT Id, Sample_Booking__c, CurrencyIsoCode FROM Sample_Line_Item__c];

        // Ensure CurrencyIsoCode is updated for line items linked to Sample_Booking__c
        for (Sample_Line_Item__c lineItem : updatedLineItems) {
            if (lineItem.Sample_Booking__c != null) {
                Sample_Booking__c booking = [SELECT CurrencyIsoCode FROM Sample_Booking__c WHERE Id = :lineItem.Sample_Booking__c];
                System.assertEquals(booking.CurrencyIsoCode, lineItem.CurrencyIsoCode);
            } else {
               
            }
        }
    }
}