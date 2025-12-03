public class SampleLineItemTriggerHandler {
    public static void updateCurrency(List<Sample_Line_Item__c> lineItems) {
        Set<Id> bookingIds = new Set<Id>();
        
        // Collect Sample_Booking__c Ids from Sample_Line_Item__c records
        for (Sample_Line_Item__c lineItem : lineItems) {
            if (lineItem.Sample_Booking__c != null) {
                bookingIds.add(lineItem.Sample_Booking__c);
            }
        }
        
        // Query Sample_Booking__c records
        Map<Id, Sample_Booking__c> bookingMap = new Map<Id, Sample_Booking__c>([SELECT Id, CurrencyIsoCode FROM Sample_Booking__c WHERE Id IN :bookingIds]);
        
        // Collect records to update
        List<Sample_Line_Item__c> lineItemsToUpdate = new List<Sample_Line_Item__c>();
        for (Sample_Line_Item__c lineItem : lineItems) {
            if (lineItem.Sample_Booking__c != null && bookingMap.containsKey(lineItem.Sample_Booking__c)) {
                Sample_Line_Item__c lineItemToUpdate = new Sample_Line_Item__c(Id = lineItem.Id);
                lineItemToUpdate.CurrencyIsoCode = bookingMap.get(lineItem.Sample_Booking__c).CurrencyIsoCode;
                lineItemsToUpdate.add(lineItemToUpdate);
            }
        }
        
        // Perform DML update
        if (!lineItemsToUpdate.isEmpty()) {
            update lineItemsToUpdate;
        }
    }
}