public class SampleDispatchToHandler {
    
    public static void updateAddressInformation(List<Sample_Dispatch_To__c> newAddressRecords) {
        Set<Id> postalCodeIds = new Set<Id>();
        Set<Id> areaIds = new Set<Id>();
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        
        // Collect all relevant IDs from the Sample_Dispatch_To__c records being processed
        for (Sample_Dispatch_To__c address : newAddressRecords) {
            if (address.Postal_Code__c != null) {
                postalCodeIds.add(address.Postal_Code__c);
            }
            /*
if (address.Area__c != null) {
areaIds.add(address.Area__c);
}*/
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
        Map<Id, Area__c> areaMap = new Map<Id, Area__c>(
            [SELECT Id, City__c, State__c, Country__c FROM Area__c WHERE Id IN :areaIds]
        );
        Map<Id, City__c> cityMap = new Map<Id, City__c>(
            [SELECT Id, State__c, Country__c FROM City__c WHERE Id IN :cityIds]
        );
        Map<Id, State__c> stateMap = new Map<Id, State__c>(
            [SELECT Id, Country__c FROM State__c WHERE Id IN :stateIds]
        );
        
        // Update the Sample_Dispatch_To__c fields based on the selected values
        for (Sample_Dispatch_To__c address : newAddressRecords) {
            if (address.Postal_Code__c != null && postalCodeMap.containsKey(address.Postal_Code__c)) {
                Postal_Code__c postalCode = postalCodeMap.get(address.Postal_Code__c);
                // address.Area__c = postalCode.Area__c;
                address.City__c = postalCode.City__c;
                address.State__c = postalCode.State__c;
                address.Country__c = postalCode.Country__c;
            } 
            /*else if (address.Area__c != null && areaMap.containsKey(address.Area__c)) {
Area__c area = areaMap.get(address.Area__c);
address.City__c = area.City__c;
address.State__c = area.State__c;
address.Country__c = area.Country__c;
} */
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
    

}