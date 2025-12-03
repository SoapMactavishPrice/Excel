public class SampleBookingTriggerHandler {
    /**
     * Method to auto-populate Requested_By__c with the same value as OwnerId
     * @param newRecords List of Sample_Booking__c records in Trigger.new
     */
    public static void populateRequestedBy(List<Sample_Booking__c> newRecords) {
        for (Sample_Booking__c booking : newRecords) {
            // Ensure OwnerId is not null
            if (booking.OwnerId != null) {
                booking.Requested_By__c = booking.OwnerId;
            }
        }
    }
    
    public static void handleBeforeInsertUpdate(List<Sample_Booking__c> newBookings, Map<Id, Sample_Booking__c> oldBookingMap) {
        Set<Id> leadIds = new Set<Id>();

        // Collect Lead IDs from Sample_Booking__c records
        for (Sample_Booking__c booking : newBookings) {
            if (booking.Sample_Request_Type__c == 'New Product New Customer' || booking.Sample_Request_Type__c == 'Old Product New Customer') {
                if (booking.Lead__c != null) {
                    leadIds.add(booking.Lead__c);
                }
            }
        }

        // Query Lead records
        Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT Id, Company FROM Lead WHERE Id IN :leadIds]);

        // Update New_Customer__c field in Sample_Booking__c
        for (Sample_Booking__c booking : newBookings) {
            if (booking.Sample_Request_Type__c == 'New Product New Customer' || booking.Sample_Request_Type__c == 'Old Product New Customer') {
                Lead lead = leadMap.get(booking.Lead__c);
                if (lead != null) {
                    booking.New_Customer__c = lead.Company;
                }
            }
        }
    }

  /*  public static void handleAfterInsertUpdate(List<Sample_Booking__c> newBookings) {
        List<Sample_Dispatch_To__c> dispatchRecords = new List<Sample_Dispatch_To__c>();
        Set<Id> leadIds = new Set<Id>();

        // Collect Lead IDs from Sample_Booking__c records
        for (Sample_Booking__c booking : newBookings) {
            if (booking.Use_Lead_Address_for_Sample_Dispatch_To__c == true && booking.Lead__c != null) {
                leadIds.add(booking.Lead__c);
            }
        }

        // Query Lead records
        Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT Id, Company, Country__c, State__c, Postal_Code__c, City__c, Street__c
                                                   FROM Lead WHERE Id IN :leadIds]);

        // Create Sample_Dispatch_To__c records
        for (Sample_Booking__c booking : newBookings) {
            if (booking.Use_Lead_Address_for_Sample_Dispatch_To__c == true && booking.Lead__c != null) {
                Lead lead = leadMap.get(booking.Lead__c);
                if (lead != null) {
                    Sample_Dispatch_To__c dispatch = new Sample_Dispatch_To__c();
                    dispatch.Sample_Booking__c = booking.Id;
                    dispatch.Ship_To_Name__c = lead.Company;
                    dispatch.Country__c = lead.Country__c;
                    dispatch.State__c = lead.State__c;
                    dispatch.Postal_Code__c = lead.Postal_Code__c;
                    dispatch.City__c = lead.City__c;
                    dispatch.Line_1_Block__c = lead.Street__c;
                    dispatchRecords.add(dispatch);
                }
            }
        }

        if (!dispatchRecords.isEmpty()) {
            insert dispatchRecords;
        }
    }
*/
    public static void handleAfterInsertUpdate(List<Sample_Booking__c> newBookings) {
    List<Sample_Dispatch_To__c> dispatchRecords = new List<Sample_Dispatch_To__c>();
    Set<Id> leadIds = new Set<Id>();
    Set<Id> existingBookingIds = new Set<Id>();

    // Collect Lead IDs from Sample_Booking__c records
    for (Sample_Booking__c booking : newBookings) {
        if (booking.Use_Lead_Address_for_Sample_Dispatch_To__c == true && booking.Lead__c != null) {
            leadIds.add(booking.Lead__c);
        }
    }

    // Query existing Sample_Dispatch_To__c records to avoid duplicates
    Map<Id, Sample_Dispatch_To__c> existingDispatchMap = new Map<Id, Sample_Dispatch_To__c>();
    for (Sample_Dispatch_To__c existingDispatch : [
        SELECT Sample_Booking__c FROM Sample_Dispatch_To__c
        WHERE Sample_Booking__c IN :newBookings
    ]) {
        existingBookingIds.add(existingDispatch.Sample_Booking__c);
    }

    // Query Lead records
    Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT Id, Company, Country__c, State__c, Postal_Code__c, City__c, Street__c
                                               FROM Lead WHERE Id IN :leadIds]);

    // Create Sample_Dispatch_To__c records only if not already present
    for (Sample_Booking__c booking : newBookings) {
        if (booking.Use_Lead_Address_for_Sample_Dispatch_To__c == true && 
            booking.Lead__c != null && 
            !existingBookingIds.contains(booking.Id)) {
            
            Lead lead = leadMap.get(booking.Lead__c);
            if (lead != null) {
                Sample_Dispatch_To__c dispatch = new Sample_Dispatch_To__c();
                dispatch.Sample_Booking__c = booking.Id;
                dispatch.Ship_To_Name__c = lead.Company;
                dispatch.Country__c = lead.Country__c;
                dispatch.State__c = lead.State__c;
                dispatch.Postal_Code__c = lead.Postal_Code__c;
                dispatch.City__c = lead.City__c;
                dispatch.Line_1_Block__c = lead.Street__c;
                dispatchRecords.add(dispatch);
            }
        }
    }

    if (!dispatchRecords.isEmpty()) {
        insert dispatchRecords;
    }
}

      
    public static void updateCurrency(List<Sample_Booking__c> bookings) {
        Set<Id> leadIds = new Set<Id>();
        
        // Collect Lead Ids from Sample_Booking__c records
        for (Sample_Booking__c booking : bookings) {
            if (booking.Lead__c != null) {
                leadIds.add(booking.Lead__c);
            }
        }
        
        // Query Lead records
        Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT Id, CurrencyIsoCode FROM Lead WHERE Id IN :leadIds]);
        
        // Collect records to update
        List<Sample_Booking__c> bookingsToUpdate = new List<Sample_Booking__c>();
        for (Sample_Booking__c booking : bookings) {
            if (booking.Lead__c != null && leadMap.containsKey(booking.Lead__c)) {
                Sample_Booking__c bookingToUpdate = new Sample_Booking__c(Id = booking.Id);
                bookingToUpdate.CurrencyIsoCode = leadMap.get(booking.Lead__c).CurrencyIsoCode;
                bookingsToUpdate.add(bookingToUpdate);
            }
        }
        
        // Perform DML update
        if (!bookingsToUpdate.isEmpty()) {
            update bookingsToUpdate;
        }
    }
}