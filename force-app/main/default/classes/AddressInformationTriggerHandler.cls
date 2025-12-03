public class AddressInformationTriggerHandler {
    
    public static void updateAddressInformation(List<Address_Information__c> newAddressRecords) {
        Set<Id> postalCodeIds = new Set<Id>();
        //Set<Id> areaIds = new Set<Id>();
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        
        // Collect all relevant IDs from the Address_Information__c records being processed
        for (Address_Information__c address : newAddressRecords) {
            if (address.Postal_Code__c != null) {
                postalCodeIds.add(address.Postal_Code__c);
            }
            //if (address.Area__c != null) {
                //areaIds.add(address.Area__c);
            //}
            if (address.City__c != null) {
                cityIds.add(address.City__c);
            }
            if (address.State__c != null) {
                stateIds.add(address.State__c);
            }
        }
        
        // Query the related records
        Map<Id, Postal_Code__c> postalCodeMap = new Map<Id, Postal_Code__c>(
            [SELECT Id, Area__c, City__c, State__c, Country__c FROM Postal_Code__c WHERE Id IN :postalCodeIds]
        );
        //Map<Id, Area__c> areaMap = new Map<Id, Area__c>(
            //[SELECT Id, City__c, State__c, Country__c FROM Area__c WHERE Id IN :areaIds]
        //);
        Map<Id, City__c> cityMap = new Map<Id, City__c>(
            [SELECT Id, State__c, Country__c FROM City__c WHERE Id IN :cityIds]
        );
        Map<Id, State__c> stateMap = new Map<Id, State__c>(
            [SELECT Id, Country__c FROM State__c WHERE Id IN :stateIds]
        );
        
        // Update the Address_Information__c fields based on the selected values
        for (Address_Information__c address : newAddressRecords) {
            if (address.Postal_Code__c != null && postalCodeMap.containsKey(address.Postal_Code__c)) {
                Postal_Code__c postalCode = postalCodeMap.get(address.Postal_Code__c);
                //address.Area__c = postalCode.Area__c;
                address.City__c = postalCode.City__c;
                address.State__c = postalCode.State__c;
                address.Country__c = postalCode.Country__c;
            } /*else if (address.Area__c != null && areaMap.containsKey(address.Area__c)) {
                Area__c area = areaMap.get(address.Area__c);
                address.City__c = area.City__c;
                address.State__c = area.State__c;
                address.Country__c = area.Country__c;
            }*/ 
            else if (address.City__c != null && cityMap.containsKey(address.City__c)) {
                City__c city = cityMap.get(address.City__c);
                address.State__c = city.State__c;
                address.Country__c = city.Country__c;
            } else if (address.State__c != null && stateMap.containsKey(address.State__c)) {
                State__c state = stateMap.get(address.State__c);
                address.Country__c = state.Country__c;
            }
        }
    }
    
    public static void handleCopyBillToShipTo(List<Address_Information__c> addressList) {
        // Filter addresses that require Ship To creation
        List<Address_Information__c> shipToRecords = new List<Address_Information__c>();
        Id shipToRecordTypeId = getShipToRecordTypeId();
        
        for (Address_Information__c address : addressList) {
            if (address.Copy_Bill_To_to_Ship_To__c) {
                shipToRecords.add(createShipToRecord(address, shipToRecordTypeId));
            }
        }
        
        // Insert Ship To records if there are any
        if (!shipToRecords.isEmpty()) {
            insert shipToRecords;
        }
    }
    
    // Helper method to get the Record Type ID for 'Ship_To'
    private static Id getShipToRecordTypeId() {
        return [SELECT Id FROM RecordType WHERE SObjectType = 'Address_Information__c' AND DeveloperName = 'Ship_To' LIMIT 1].Id;
    }
    
    // Helper method to create a Ship To record based on the Bill To record
    private static Address_Information__c createShipToRecord(Address_Information__c billTo, Id shipToRecordTypeId) {
        return new Address_Information__c(
            RecordTypeId = shipToRecordTypeId,
            Name = 'Ship To - ' + billTo.City__c,
            Account__c =billTo.Account__c,
            Address_1__c = billTo.Address_1__c,
            Address_2__c = billTo.Address_2__c,
            City__c = billTo.City__c,
            Postal_Code__c = billTo.Postal_Code__c,
            State__c = billTo.State__c,
            //Address_Code__c = billTo.Address_Code__c,
            Country__c = billTo.Country__c,
            GSTIN_no__c = billTo.GSTIN_no__c,
            Contact_phone_no__c=billTo.Contact_phone_no__c,
            Contact_email_ID__c=billTo.Contact_email_ID__c
            //GST_Type__c = billTo.GST_Type__c
        );
    }
    
    public static void handleInfoCorrection(List<Address_Information__c> newAddressInfo){
        
        List<Address_Information__c> updateList = new List<Address_Information__c>();
        for(Address_Information__c a : newAddressInfo){
            Address_Information__c ai = new Address_Information__c();
            String suc = '';
            if (a.SF_Address_Code__c != null) {
                suc = a.SF_Address_Code__c;
                if (a.City__c != null) {
                    City__c c = [SELECT Id, Name FROM City__c WHERE Id = :a.City__c];
                    suc += ' - ' + c.Name; 
                }
            }
            ai.Id = a.Id;
            ai.Name = a.name + ' - ' + suc;
            updateList.add(ai);
        }
        
        if(updateList.size() > 0){
            update updateList;
        }
    }
    
}