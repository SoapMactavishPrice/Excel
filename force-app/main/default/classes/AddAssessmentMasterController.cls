public class AddAssessmentMasterController {
    
    // Existing method to fetch data based on recordId
    @AuraEnabled(Cacheable = true)
    public static List<Assessment_Answer__c> isFetchdata(Id recordId) {
        return [SELECT Id, Name FROM Assessment_Answer__c WHERE Assessment_Master__c = :recordId];    
    }
    
    // Method to save answers
    @AuraEnabled
    public static Map<String, String> saveAnswer(Id Id, String JS) {
        system.debug('JS-->'+JS);
        List<Object> objList = (List<Object>)JSON.deserializeUntyped(JS);
        Map<String, String> result = new Map<String, String>();
        try {
            List<Assessment_Master__c> aaList = new List<Assessment_Master__c>();
            for (Object obj : objList) {
                Map<String, Object> objMap = (Map<String, Object>)obj;
                Assessment_Master__c aa = new Assessment_Master__c();
                aa.Milestone__c = Id;
                aa.Name = (String)objMap.get('Assessment_Score');
                aa.Assessment_Remarks__c = (String)objMap.get('Assessment_Answer');
                aa.Criteria_Measure__c = (String)objMap.get('Criteria_Measure');
                aa.Assessment_Question__c = (String)objMap.get('Assessment_Question');
                
                aa.Question_Type__c = 'Picklist';
                aa.Responsibilty_Role__c  = (String)objMap.get('respRole');
                aa.Responsibilty_User__c  = (Id)objMap.get('respRoleUser');
                aa.Accessor_User__c  = (Id)objMap.get('accessorRoleUser');
                aa.Accessor_Role__c  = (String)objMap.get('accessorRole');
                aaList.add(aa);
            }
            
            if (aaList.size() > 0) {
                insert aaList;
            }
            result.put('message', 'success');
        } catch (Exception e) {
            system.debug(e.getLineNumber());
            result.put('message', e.getMessage());
        }
        
        return result;
    }
    
    // Helper method to validate picklist value
    public static Boolean isValidPicklistValue(String objectName, String fieldName, String value) {
        // Dynamically get the Schema for the object and field
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        Schema.DescribeFieldResult fieldResult = objectDescribe.fields.getMap().get(fieldName).getDescribe();
        
        // Get the picklist values for the field
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry entry : picklistValues) {
            if (entry.getValue() == value) {
                return true;
            }
        }
        return false;
    }
    
    // PicklistOption inner class to return picklist values
    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        
        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
    
    // Method to fetch picklist values for a field on an object
    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getPicklistValues(String objectName, String fieldName) {
        List<PicklistOption> options = new List<PicklistOption>();
        
        // Describe the object and field
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        Schema.DescribeFieldResult fieldResult = objectDescribe.fields.getMap().get(fieldName).getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        // Add picklist options to the list
        for (Schema.PicklistEntry entry : picklistValues) {
            options.add(new PicklistOption(entry.getLabel(), entry.getValue()));
        }
        
        return options;
    }
}