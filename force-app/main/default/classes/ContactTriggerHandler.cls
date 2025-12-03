public class ContactTriggerHandler {
    
    public static void updateContactAddresses(List<Contact> newContacts) {
        Set<Id> postalCodeIds = new Set<Id>();
        Set<Id> areaIds = new Set<Id>();
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        
        // Collect all relevant IDs from the Contact records being processed
        for (Contact contact : newContacts) {
            if (contact.Mailing_Zip_Code__c != null) {
                postalCodeIds.add(contact.Mailing_Zip_Code__c);
            }
            if (contact.Mailing_Area__c != null) {
                areaIds.add(contact.Mailing_Area__c);
            }
            if (contact.Mailing_City__c != null) {
                cityIds.add(contact.Mailing_City__c);
            }
            if (contact.Mailing_State__c != null) {
                stateIds.add(contact.Mailing_State__c);
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
        
        // Update the Contact fields based on the selected values
        for (Contact contact : newContacts) {
            if (contact.Mailing_Zip_Code__c != null && postalCodeMap.containsKey(contact.Mailing_Zip_Code__c)) {
                Postal_Code__c postalCode = postalCodeMap.get(contact.Mailing_Zip_Code__c);
                contact.Mailing_Area__c = postalCode.Area__c;
                contact.Mailing_City__c = postalCode.City__c;
                contact.Mailing_State__c = postalCode.State__c;
                contact.Mailing_Country__c = postalCode.Country__c;
            } else if (contact.Mailing_Area__c != null && areaMap.containsKey(contact.Mailing_Area__c)) {
                Area__c area = areaMap.get(contact.Mailing_Area__c);
                contact.Mailing_City__c = area.City__c;
                contact.Mailing_State__c = area.State__c;
                contact.Mailing_Country__c = area.Country__c;
            } else if (contact.Mailing_City__c != null && cityMap.containsKey(contact.Mailing_City__c)) {
                City__c city = cityMap.get(contact.Mailing_City__c);
                contact.Mailing_State__c = city.State__c;
                contact.Mailing_Country__c = city.Country__c;
            } else if (contact.Mailing_State__c != null && stateMap.containsKey(contact.Mailing_State__c)) {
                State__c state = stateMap.get(contact.Mailing_State__c);
                contact.Mailing_Country__c = state.Country__c;
            }
        }
    }
}