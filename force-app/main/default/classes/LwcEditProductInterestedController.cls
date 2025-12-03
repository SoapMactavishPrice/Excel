public class LwcEditProductInterestedController {

    @AuraEnabled 
    public static List<Product_Interested__c> getProdInterest(string Id){
        List<Product_Interested__c> piList= [Select Id,Product__c,Product__r.Name,Volume_in_Kgs__c,Expected_Price__c,Product_Family__c,Add_In_Opty__c,Product_Code__c, Name from Product_Interested__c where Lead__c=:Id order by CreatedDate];
      return piList;
    }
    
    
    @AuraEnabled 
    public static Map<string,string> updateData(string JS){
        system.debug('JS'+JS);
        Map<string,string> result = new Map<string,string>();
        try{
            
            List<Product_Interested__c> piList = new List<Product_Interested__c>();
            
            List<Object> jsList = (List<Object>)JSON.deserializeUntyped(JS);
            
            for(Object obj : jsList){
                Map<string,object>objMap = (Map<string,object>)obj;
                Product_Interested__c pm = new Product_Interested__c();
                pm.Id = (Id)objMap.get('Id');
                pm.Volume_in_Kgs__c = double.valueOf(objMap.get('Volume_in_Kgs'));
                pm.Expected_Price__c = double.valueOf(objMap.get('Expected_Price'));
                pm.Add_In_Opty__c = (boolean) objMap.get('Add_In_Opty');
                piList.add(pm);
            }
            
            if(piList.size() > 0){
                update piList;
            }
            
            result.put('message','success');  
        }catch(exception e){
            system.debug(e);
            result.put('message',e.getLineNumber() + ' - ' +e.getMessage()); 
        }
        return result;
    }
    
    }