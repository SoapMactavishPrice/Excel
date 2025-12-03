public class AddDecisionCriteriaMaster {
    
    @AuraEnabled(Cacheable = true)
    public static List<Assessment_Answer__c> isFetchdata(Id recordId){
        return [SELECT Id, Name FROM Assessment_Answer__c WHERE Assessment_Master__c = :recordId];    
    }
    
    @AuraEnabled
    public static Map<String, String> saveAnswer(Id Id, String JS) {
        system.debug('JS-->'+JS);
        List<Object> objList = (List<Object>)JSON.deserializeUntyped(JS);
        Map<String, String> result = new Map<String, String>();
        try {
            List<Decision_Criteria_Master__c> aaList = new List<Decision_Criteria_Master__c>();
            for (Object obj : objList) {
                Map<String, Object> objMap = (Map<String, Object>)obj;
                Decision_Criteria_Master__c aa = new Decision_Criteria_Master__c();
                aa.Milestone__c = Id;
                aa.Name = (String)objMap.get('Assessment_Score');
                aa.Question__c = (String)objMap.get('Question');
                aa.Decision__c = (String)objMap.get('Decision__c');
                aa.Decision_Role__c =(String)objMap.get('decRole');
                aa.Decision_User__c = (Id)objMap.get('decUser');
               
                
                // Validate picklist value for Decision__c before assigning
                String decisionValue = (String)objMap.get('Decision__c');
                if (isValidPicklistValue('Decision_Criteria_Master__c', 'Decision__c', decisionValue)) {
                    aa.Decision__c = decisionValue;
                } else {
                    result.put('message', 'Invalid picklist value for Decision__c');
                    return result;
                }

                aaList.add(aa);
            }

            if (aaList.size() > 0) {
                insert aaList;
            }
            result.put('message', 'success');
        } catch (Exception e) {
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