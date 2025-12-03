public class Lwc_collection_reportController {
    
    @AuraEnabled
    public static string getProductsData() {
        try {
            List<Product_Group__c>pcList = [SELECT Id, Name FROM Product_Group__c ORDER BY Name ASC];
            List < Map < String, Object >> parameterData = new List < Map < String, Object >> ();
            for (Product_Group__c p: pcList) {
                Map < String, Object > tempMap = new Map < String, Object > ();
                tempMap.put('ParameterPGName', p.Name);
                tempMap.put('ParameterId', p.Id);
                parameterData.add(tempMap);
            }
            system.debug(parameterData.size());
            return JSON.serialize(parameterData);
            
        } catch (Exception e) {
            system.debug(e.getLineNumber() +' - '+ e.getMessage());
            throw new AuraHandledException(e.getLineNumber() + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=True)
    public static List<Collection_Plan__c> getCollectionDetails() {
        Date currentDate = Date.today();  // Get today's date
        Date startOfMonth = Date.newInstance(currentDate.year(), currentDate.month(), 1);  
        List<Collection_Plan__c> coline = [SELECT Id,Name,Customer_Code__c,Product_Group__c	,Customer_Name__r.Name,Customer_Name_Backend__c,
                                           (SELECT Id,Actual_Collection_110th__c,Actual_Collection_1120th__c,Actual_Collection_2131st__c,
                                           Bal_ERP_Coll_Plan__c,Bal_Imm_Adv_Coll_Plan__c,Collection_Plan__c,Collection_Plan_110th__c,Collection_Plan_1120th__c,Collection_Plan_2131st__c,
                                           End_Date__c,ERP_Actual_Coll__c,ERP_Collectibles_110th__c,ERP_Collectibles_1120th__c,ERP_Collectibles_2131st__c,ERP_Collectibles_Due_Previous_Month__c,
                                           ERP_Plan__c,Imm_Adv_Actual_Coll__c,Imm_Adv_Plan__c,Month_Name__c,Plan_Vs_Actuals__c,Start_Date__c,Total_Actual_Collection__c,Total_Collection_Plan__c,
                                           Total_ERP_Collectibles__c,Total_Shortfall_Excess_in_Coll_Plan__c
                                           from Collection_Plan_Line_Item__r where Start_Date__c =:startOfMonth)
                                           from  Collection_Plan__c where Id IN (SELECT Collection_Plan__c  from 
                                                                                 Collection_Plan_Line_Item__c where Start_Date__c =:startOfMonth)];
        if(coline.size() > 0){
            system.debug(coline.size());
            return coline;
        }
        else {
           return  new List<Collection_Plan__c>();
        }
        
    }
    
}