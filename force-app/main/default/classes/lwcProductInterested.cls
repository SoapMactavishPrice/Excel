public class lwcProductInterested {
    
    @AuraEnabled(Cacheable=true)
    public static List<Id> getExistingProducts(string Id){
        List<Id> ids = new List<Id>();
        List<Product_Interested__c> pi= [Select Id,Product__c from Product_Interested__c where Lead__c=:Id];
        for(Product_Interested__c p : pi){
            ids.add(p.Product__c);
            }
        return ids;       
    }
    @AuraEnabled(Cacheable=true)
    public static List<Map<string,string>> getPicklistValues() {
        Schema.DescribeFieldResult fieldResult = Product_Interested__c.Product_Family__c.getDescribe();
        List<Map<string,string>> picklist= new List<Map<string,string>>();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        // Iterate over and print the picklist values
        for (Schema.PicklistEntry pickValue : picklistValues) {
            Map<string,string> pic = new Map<string,string>();
            pic.put('label',pickValue.getLabel());
            pic.put('value',pickValue.getValue());
            picklist.add(pic);
        }
        return picklist;
    }
    
    
    @AuraEnabled(Cacheable=true)
    public static List<Product2> getProducts(string family , List<Id> ids){
        
        
        string query = 'Select Id ,Name,Family ,ProductCode from Product2 where Id NOT IN : ids';
        if(string.isNotBlank(family)){
            query +=' and Family = \''+family+'\'';
        }else {
            query +=' limit 1000';
        }
        system.debug(query);
        List<Product2> pdList = database.query(query);
        if(pdList.size() > 0)
            return pdList;
        else 
            return null;
        
    }
    
    @AuraEnabled
    public static Map<string,string> saveProductInterested(Id Id, string JS){
        system.debug('Id'+Id);
        system.debug('JS'+JS);
        Map<string,string> result = new Map<string,string>();
        try{
            
            List<Product_Interested__c> piList = new List<Product_Interested__c>();
            
            List<Object> jsList = (List<Object>)JSON.deserializeUntyped(JS);
            
            for(Object obj : jsList){
                Map<string,object>objMap = (Map<string,object>)obj;
                Product_Interested__c pm = new Product_Interested__c();
                pm.Lead__c  =Id ;
                pm.Product__c = (Id)objMap.get('Id');
                pm.Volume_in_Kgs__c = Decimal.valueOf((string)objMap.get('volume'));
                pm.Expected_Price__c = Decimal.valueOf((string)objMap.get('price'));
                pm.Product_Family__c = (string) objMap.get('family');
                piList.add(pm);
            }
            
            if(piList.size() > 0){
                insert piList;
            }
            
            result.put('message','success');  
        }catch(exception e){
            system.debug(e);
            result.put('message',e.getMessage()); 
        }
        return result;
    }
    
    
    
    
}