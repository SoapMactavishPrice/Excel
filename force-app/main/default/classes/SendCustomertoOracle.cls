public class SendCustomertoOracle {
    
    @AuraEnabled
    public static String getContactDetail(String accId) {
        List<Contact> contactList = new List<Contact>();
        try {
            contactList = [
                SELECT Id, Name, FirstName, LastName, Title, MobilePhone, Email, LinkedIn_URL__c
                FROM Contact
                WHERE AccountId = :accId
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return JSON.serialize(contactList);
    }
    
    @AuraEnabled
    public static String getAddInfoDetail(String accId) {
        List<Address_Information__c> addInfoList = new List<Address_Information__c>();
        try {
            addInfoList = [
                SELECT Id, Name, Postal_Code__c, SF_Address_Code__c, Postal_Code__r.Name, Area__c, Area__r.Name,
                City__c, City__r.Name, State__c, State__r.Name, Country__c, Country__r.Name, Primary_Address__c
                FROM Address_Information__c
                WHERE Account__c = :accId
            ];
    
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return JSON.serialize(addInfoList);
    }

    @AuraEnabled
    public static string getRecordTypeId(String name){
        RecordType rt = new RecordType();
        try {
            rt = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Address_Information__c' AND DeveloperName =: name LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return rt.Id;
    }

    @AuraEnabled
    public static Boolean hasRequiredAddressInfo(String accId) {
        // Required DeveloperNames for Address_Information__c record types
        Set<String> requiredDevNames = new Set<String>{'Bill_To', 'Ship_To'};

        // Query RecordType to get Ids for the required DeveloperNames
        Map<String, Id> devNameToIdMap = new Map<String, Id>();
        for (RecordType rt : [
            SELECT Id, DeveloperName 
            FROM RecordType 
            WHERE SObjectType = 'Address_Information__c' 
            AND DeveloperName IN :requiredDevNames
        ]) {
            devNameToIdMap.put(rt.DeveloperName, rt.Id);
        }

        // Validate all required record types exist
        if (devNameToIdMap.size() < requiredDevNames.size()) {
            throw new AuraHandledException('One or more required RecordTypes not found.');
        }

        // Query Address_Information__c records related to the Account with matching RecordTypeIds
        List<Address_Information__c> addressList = [
            SELECT Id, RecordTypeId 
            FROM Address_Information__c 
            WHERE Account__c = :accId 
            AND RecordTypeId IN :devNameToIdMap.values()
        ];

        // Track found DeveloperNames based on RecordTypeId
        Set<String> foundDevNames = new Set<String>();
        for (Address_Information__c addr : addressList) {
            for (String devName : devNameToIdMap.keySet()) {
                if (addr.RecordTypeId == devNameToIdMap.get(devName)) {
                    foundDevNames.add(devName);
                }
            }
        }

        // Return true if all required types were found
        return foundDevNames.containsAll(requiredDevNames);
    }

    @AuraEnabled(cacheable=true)
    public static string getPinCodeDetails(String pincode) {
        try {
            Postal_Code__c pinCodeRecord = [
                SELECT Id, Area__c, City__c, State__c, Country__c 
                FROM Postal_Code__c WHERE id = :pincode LIMIT 1
            ];
            pinWrap pin = new pinWrap();
            pin.Id = pinCodeRecord.Id;
            pin.areaId = pinCodeRecord.Area__c;
            pin.cityId = pinCodeRecord.City__c;
            pin.stateId = pinCodeRecord.State__c;
            pin.countryId = pinCodeRecord.Country__c;
            
            return JSON.serialize(pin); 
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving Pin Code details: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static string deleteAddressInfo(String addId){
        try {
            Address_Information__c add = [SELECT Id, Account__c FROM Address_Information__c WHERE Id = :addId];
            delete add;
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private class pinWrap{
        Id Id;
        String cityId;
        String stateId;
        String countryId;
        String areaId;
    }

}