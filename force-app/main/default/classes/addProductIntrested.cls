public class addProductIntrested {
    
    
    @AuraEnabled 
    public static Map<string,object> getProdInterest(string Id){
        Map<string,object> result = new Map<string,object>();
        result.put('currencyCode',[select id ,CurrencyIsoCode from lead where Id =:Id].CurrencyIsoCode);
        List<Product_Interested__c> piList= [Select Id,Product__c,Pricebook_Entry_Id__c,New_Product_Name__c,New_Product__c,List_Price__c,Product__r.Name,Volume_in_Kgs__c,Expected_Price__c,Product_Family__c,Add_In_Opty__c,Product_Code__c,Volume_Frequency__c, Name from Product_Interested__c where Lead__c=:Id order by CreatedDate];
      result.put('piList',piList);
        system.debug(result);
        return result;
    }
    
    @AuraEnabled 
    public static string deleteProductInterested(string Id){
         Product_Interested__c  piList= [Select Id,Product__c,Product__r.Name,Volume_in_Kgs__c,Expected_Price__c,New_Product__c,New_Product_Name__c,Product_Family__c,Add_In_Opty__c,
                                              Product_Code__c,Volume_Frequency__c, Name from Product_Interested__c where Id=:Id limit 1];
        string pInName =piList.Name;
        delete piList; 
        return 'Product Interested record deleted '+pInName;
    }
    
    
    
   @AuraEnabled(Cacheable=true)
    public static List<Id> getExistingProducts(string Id){
        List<Id> ids = new List<Id>();
        List<Product_Interested__c> pi= [Select Id,Product__c from Product_Interested__c where Lead__c=:Id];
        for(Product_Interested__c p : pi){
            ids.add(p.Product__c);
            }
        return ids;       
    }
    
    // @AuraEnabled(Cacheable=true)
    // public static List<Map<string,string>> getPicklistValues() {
    //     Schema.DescribeFieldResult fieldResult = Product_Interested__c.Product_Family__c.getDescribe();
    //     List<Map<string,string>> picklist= new List<Map<string,string>>();
    //     List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
    //     // Iterate over and print the picklist values
    //     for (Schema.PicklistEntry pickValue : picklistValues) {
    //         Map<string,string> pic = new Map<string,string>();
    //         pic.put('label',pickValue.getLabel());
    //         pic.put('value',pickValue.getValue());
    //         picklist.add(pic);
    //     }



        
    //     // UOM picklist
    //     Schema.DescribeFieldResult uomField = Product_Interested__c.Volume_Frequency__c.getDescribe();
    //     List<Map<String, String>> uomList = new List<Map<String, String>>();
    //     for (Schema.PicklistEntry uomPick : uomField.getPicklistValues()) {
    //         uomList.add(new Map<String, String>{
    //             'label' => uomPick.getLabel(),
    //                 'value' => uomPick.getValue()
    //                 });
    //     }
    //     allPicklists.put('frequency', uomList);

    //     return picklist;
    // }

      @AuraEnabled(Cacheable=true)
public static Map<String, List<Map<String, String>>> getPicklistValues() {
    Map<String, List<Map<String, String>>> allPicklists = new Map<String, List<Map<String, String>>>();
    
    // Product Family picklist
    Schema.DescribeFieldResult productFamilyField = Product_Interested__c.Product_Family__c.getDescribe();
    List<Map<String, String>> productFamilyList = new List<Map<String, String>>();
    for (Schema.PicklistEntry pickValue : productFamilyField.getPicklistValues()) {
        productFamilyList.add(new Map<String, String>{
            'label' => pickValue.getLabel(),
            'value' => pickValue.getValue()
        });
    }
    allPicklists.put('productFamily', productFamilyList);
    
    // Volume Frequency picklist
    Schema.DescribeFieldResult frequencyField = Product_Interested__c.Volume_Frequency__c.getDescribe();
    List<Map<String, String>> frequencyList = new List<Map<String, String>>();
    for (Schema.PicklistEntry frequencyPick : frequencyField.getPicklistValues()) {
        frequencyList.add(new Map<String, String>{
            'label' => frequencyPick.getLabel(),
            'value' => frequencyPick.getValue()
        });
    }
    allPicklists.put('frequency', frequencyList);
    
    return allPicklists;
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
                if(string.isNotBlank((string) objMap.get('inId'))){
                   pm.Id = (Id)objMap.get('inId');
                }
                pm.Lead__c  =Id ;
                if(string.isNotBlank((string)objMap.get('prodId'))){
                pm.Product__c = (Id)objMap.get('prodId');
                }
                pm.Volume_in_Kgs__c = double.valueOf(objMap.get('volume'));
                pm.Expected_Price__c = double.valueOf(objMap.get('price'));
                pm.Pricebook_Entry_Id__c = (string)objMap.get('pbeId');
                pm.List_Price__c = double.valueOf(objMap.get('unitPrice'));
                pm.Product_Family__c = (string) objMap.get('prodFamily');
                pm.Add_In_Opty__c = (boolean) objMap.get('Add_In_Opty');
                
                 pm.New_Product_Name__c = (string) objMap.get('New_Product_Name');
                pm.New_Product__c = (boolean) objMap.get('New_Product');
                 pm.Volume_Frequency__c = (String) objMap.get('frequency');
                piList.add(pm);
            }
            
            if(piList.size() > 0){
                upsert piList;
            }
            
            result.put('message','success');  
        }catch(exception e){
            system.debug(e);
            result.put('message',e.getLineNumber()+' - '+e.getMessage()); 
        }
        return result;
    }
  
    
}