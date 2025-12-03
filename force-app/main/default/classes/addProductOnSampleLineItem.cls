public class addProductOnSampleLineItem {

    @AuraEnabled(Cacheable=true)
    public static Map<string,object> getExistingProducts(string Id){
        List<Id> ids = new List<Id>();
        List<Sample_Line_Item__c> pi = [Select Id, Product__c, Product__r.Name, Product__r.ProductCode, Quantity__c from Sample_Line_Item__c where Sample_Booking__c=:Id];
        for(Sample_Line_Item__c p : pi){
            ids.add(p.Product__c);
        }
        List<Product_Interested__c> picList;
        picList = [Select Id, Lead__c, Product__c ,Product_Code__c, Product_Family__c, Product__r.Name, Product__r.ProductCode, Expected_Price__c, Volume_in_Kgs__c 
                   from Product_Interested__c where Lead__c IN (Select Lead__c from Sample_Booking__c where Id=:Id)];
        Map<string,object> mp = new Map<string,object>();
        mp.put('id', ids);
        //mp.put('Product_Interested', picList);
        return mp;       
    }

    @AuraEnabled(Cacheable=true)
    public static List<Map<string,string>> getPicklistValues() {
        Schema.DescribeFieldResult fieldResult = Product_Interested__c.Product_Family__c.getDescribe();
        List<Map<string,string>> picklist = new List<Map<string,string>>();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        // Iterate over and print the picklist values
        for (Schema.PicklistEntry pickValue : picklistValues) {
            Map<string,string> pic = new Map<string,string>();
            pic.put('label', pickValue.getLabel());
            pic.put('value', pickValue.getValue());
            picklist.add(pic);
        }
        return picklist;
    }       

    @AuraEnabled(Cacheable=true)
    public static List<Product2> getProducts(string family , List<Id> ids){
        string query = 'Select Id, Name, Family, ProductCode from Product2 where Id NOT IN : ids';
        if(string.isNotBlank(family)){
            query += ' and Family = \'' + family + '\'';
        } else {
            query += ' limit 1000';
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
        system.debug('Id' + Id);
        system.debug('JS' + JS);
        Map<string,string> result = new Map<string,string>();
        try{
            List<Sample_Line_Item__c> piList = new List<Sample_Line_Item__c>();
            List<Object> jsList = (List<Object>)JSON.deserializeUntyped(JS);
            
            for(Object obj : jsList){
                Map<string,object> objMap = (Map<string,object>)obj;
                Sample_Line_Item__c pm = new Sample_Line_Item__c();
                pm.Sample_Booking__c = Id;
                
                // Check if Product__c exists in Product2 before assigning it
                Id productId = (Id)objMap.get('prodId');
                Product2 existingProduct = [SELECT Id FROM Product2 WHERE Id = :productId LIMIT 1];
                
                if (existingProduct != null) {
                    pm.Product__c = productId; // Valid Product ID
                } else {
                    throw new DmlException('Product does not exist or does not match filter criteria.');
                }

                pm.Quantity__c = Decimal.valueOf((string)objMap.get('volume'));
                pm.Product_Family__c = (string) objMap.get('family');
                pm.Remarks__c = (string) objMap.get('remark');
                piList.add(pm);
            }

            if(piList.size() > 0){
                insert piList;
            }

            result.put('message','success');  
        } catch(exception e){
            system.debug(e);
            result.put('message',e.getMessage() + e.getLineNumber()); 
        }
        return result;
    }    
}