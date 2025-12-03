public without sharing class ProductionSalesController {
    
    
    @AuraEnabled
    public static string getDefaultFilterValues() {
        Map < String, Object > result = new Map < String, Object >();
        Fiscal_Year__c fsc = [SELECT Id, FY_Start_Date__c, FY_End_Date__c FROM Fiscal_Year__c WHERE isActive__c = true LIMIT 1];
        result.put('Fiscal_Year__c', fsc.Id);
        result.put('startDate', fsc.FY_Start_Date__c);
        result.put('endDate', fsc.FY_End_Date__c);
        return JSON.serialize(result);
        
    }
    
    @AuraEnabled
    public static string getSelectedFiscalYear(string Id) {
        Map < String, Object > result = new Map < String, Object >();
        Fiscal_Year__c fsc = [SELECT Id, FY_Start_Date__c, FY_End_Date__c FROM Fiscal_Year__c WHERE Id =: Id and Is_Planning__c=:true limit 1];
        result.put('Fiscal_Year__c', fsc.Id);
        result.put('startDate', fsc.FY_Start_Date__c);
        result.put('endDate', fsc.FY_End_Date__c);
        return JSON.serialize(result);
        
    }
    
    @AuraEnabled
    public static string getProductsData() {
        try {
            List<Product_Category__c>pcList = [SELECT Id, Name,Is_Active__c,Product_Group__r.Name,Product_Group__c FROM Product_Category__c where Is_Active__c=:true ORDER BY Index__c ASC];
            List < Map < String, Object >> parameterData = new List < Map < String, Object >> ();
            for (Product_Category__c p: pcList) {
                if(p.Is_Active__c){
                    Map < String, Object > tempMap = new Map < String, Object > ();
                    tempMap.put('ParameterId', p.Id);
                    tempMap.put('Id', '');
                    tempMap.put('ParameterName', p.Name);
                    tempMap.put('ParameterCode', p.Name);
                    parameterData.add(tempMap);
                }
            }
            system.debug(parameterData.size());
            return JSON.serialize(parameterData);
            
        } catch (Exception e) {
            system.debug(e.getLineNumber() +' - '+ e.getMessage());
            throw new AuraHandledException(e.getLineNumber() + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string getProductionDetail(string fiscalYear ){
        
        
        string queryFront = '';
         List<Production__c> proList= [SELECT Id, Product_Category__c,Name,Product_Category__r.Name,Product_Category__r.Product_Group__r.Name,Product_Category__r.Product_Group__c,
                                      (SELECT Id, Start_Date__c, End_Date__c,Domestic_Sales__c,Closing_Stock__c,CC_Sales__c,Export_Sales__c,Month_Name__c,  
                                       Actual_Closing_Stock__c,Actual_Domestic_Sales__c,Actual_Export_Sales__c,Actual_Opening_Stock__c,Actual_production__c,Actual_Total_Stock__c,Actual_Total_Sales__c
                                      ,Opening_Stock__c,Actual_CC__c,Rate__c ,Actual_Sales_Value__c,Actual_Rate__c,Sales_Value__c, Production__c , Production_Stock__c ,Total_Sales__c,Total_Stock__c FROM Production_Line_Items__r where End_Date__c >=: system.today()
                                      ORDER BY Start_Date__c) FROM Production__c  
                                      where ID IN (select Production__c from Production_Line_Item__c where End_Date__c >=: system.today())
                                      and Product_Category__r.Product_Group__c !=:null
                                      ORDER BY Product_Category__r.Name ASC];
        
         System.debug('Retrieved Production__c records: ' + proList.size()); 	
        
        List<object> result = new List<object>();
        for (Production__c record: proList) {
            Map < String, Object > tempMap = new Map < String, Object > ();
            tempMap.put('Id', record.Id);
            tempMap.put('ParameterId', record.Product_Category__c);
            tempMap.put('ParameterName', record.Product_Category__r.Name);
            integer i = 0;
            List<Map < String, Object >> objMaplist = new List<Map < String, Object >>();
            for (Production_Line_Item__c childRec: record.Production_Line_Items__r) {
                Map < String, Object > childMap = new Map < String, Object > ();
                Map < String, Object > newActualMap = new Map < String, Object > ();
                if(childRec.Start_Date__c >= System.today()){
                    childMap.put('ParameterId', childRec.Id);
                    childMap.put('index',i);
                    childMap.put('Closing_Stock', childRec.Closing_Stock__c.setScale(2));
                    childMap.put('monthName', childRec.Month_Name__c.toUpperCase());
                    childMap.put('Domestic_Sales', childRec.Domestic_Sales__c.setScale(2));
                    childMap.put('Export_Sales', childRec.Export_Sales__c.setScale(2));
                    childMap.put('Opening_Stock', childRec.Opening_Stock__c.setScale(2));
                    childMap.put('production_Stock', childRec.production_Stock__c.setScale(2));
                    childMap.put('Total_Stock', childRec.Total_Stock__c.setScale(2));
                    childMap.put('Total_Sales', childRec.Total_Sales__c.setScale(2));
                    childMap.put('CC_Sales', childRec.CC_Sales__c.setScale(2));
                    childMap.put('isCurrentMonth', false);
                    childMap.put('targetAmountEdit', false);
                     i++;
                    objMaplist.add(childMap);
                    
                }
                else
                    if(childRec.Start_Date__c <= System.today() && System.today() <= childRec.End_Date__c){
                        
                         newActualMap.put('monthName', 'ACTUAL '+childRec.Month_Name__c.toUpperCase());
                        newActualMap.put('Actual_Domestic_Sales', childRec.Actual_Domestic_Sales__c != null ? childRec.Actual_Domestic_Sales__c.setScale(2) : 0);
                        newActualMap.put('Actual_Export_Sales', childRec.Actual_Export_Sales__c != null ? childRec.Actual_Export_Sales__c.setScale(2) : 0);
                        newActualMap.put('Actual_Opening_Stock', childRec.Actual_Opening_Stock__c != null ? childRec.Actual_Opening_Stock__c.setScale(2) : 0);
                        newActualMap.put('Actual_production_Stock', childRec.Actual_production__c != null ? childRec.Actual_production__c.setScale(2) : 0);
                        newActualMap.put('Actual_Total_Stock', childRec.Actual_Total_Stock__c != null ? childRec.Actual_Total_Stock__c.setScale(2) : 0);
                        newActualMap.put('Actual_Total_Sales', childRec.Actual_Total_Sales__c != null ? childRec.Actual_Total_Sales__c.setScale(2) : 0);
                        newActualMap.put('Actual_CC_Sales', childRec.Actual_CC__c != null ? childRec.Actual_CC__c.setScale(2) : 0);
                        newActualMap.put('Actual_Closing_Stock', childRec.Actual_Closing_Stock__c != null ? childRec.Actual_Closing_Stock__c.setScale(2) : 0);                        
                        newActualMap.put('isCurrentMonth', true);
                        newActualMap.put('targetAmountEdit', false);
                        system.debug('newActualMap--'+newActualMap);
                        objMaplist.add(newActualMap);
                         i++;
                        childMap.put('ParameterId', childRec.Id);
                        childMap.put('index',i);
                        childMap.put('Closing_Stock', childRec.Closing_Stock__c.setScale(2));
                        childMap.put('monthName', 'PLAN '+childRec.Month_Name__c.toUpperCase());
                        childMap.put('Domestic_Sales', childRec.Domestic_Sales__c.setScale(2));
                        childMap.put('Export_Sales', childRec.Export_Sales__c.setScale(2));
                        childMap.put('Opening_Stock', childRec.Opening_Stock__c.setScale(2));
                        childMap.put('production_Stock', childRec.production_Stock__c.setScale(2));
                        childMap.put('Total_Stock', childRec.Total_Stock__c.setScale(2));
                        childMap.put('Total_Sales', childRec.Total_Sales__c.setScale(2));
                        childMap.put('CC_Sales', childRec.CC_Sales__c.setScale(2));
                        childMap.put('isCurrentMonth', false);
                        childMap.put('targetAmountEdit', false);
                           
                        objMaplist.add(childMap);
                         i++;
                       
                        
                    }
                
               
            }
            if(objMaplist.size() > 0){
            tempMap.put('childData', objMaplist);
            }
            result.add(tempMap);
        }
        
        return JSON.serialize(result);
    }
    
    
    @AuraEnabled 
    public static string save (string jsonData, string fiscalYear){
        
        try{
            List<Production> productionList = (List<Production>) JSON.deserialize(jsonData, List<Production>.class);
            
            List<Production__c> plList = new List<Production__c>();
            List<Production_Line_Item__c> pline = new List<Production_Line_Item__c>();
            Production__c pr = new Production__c();
            
            for (Production parentData : productionList) {
                Production__c production = new Production__c();
                if(string.isNotblank(parentData.Id)){
                    production.Id = parentData.Id;
                }
                production.Product_Category__c = parentData.parameterId;
                production.Fiscal_Year__c = fiscalYear;
                plList.add(production);
                
            }
            
            Map<string,Id> mps = new  Map<string,Id>();
            if(plList.size() > 0){
                upsert plList;
                for(Production__c pro : plList ){
                    mps.put(pro.Product_Category__c,pro.Id);
                }
            }
            
            Fiscal_Year__c fy = [SELECT Id, FY_Start_Date__c, FY_End_Date__c FROM Fiscal_Year__c WHERE isActive__c = true and Id=:fiscalYear LIMIT 1];
            Date dt1 = fy.FY_Start_Date__c.toStartOfMonth();
            Date dt2 = fy.FY_End_Date__c;
            Integer monthsInBetween = dt1.toStartOfMonth().monthsBetween(dt2.addDays(1));
            
            Map<string,Id> toBeUpdateMap = new Map<string,Id>();
            
            
            for (Production parentData : productionList) {
                for (ProductionLineItem childData : parentData.childData) {
                    String monthName = childData.monthName.toUpperCase();
                    system.debug('monthName-->'+monthName);
                    if(!monthName.contains('ACTUAL')){
                        Production_Line_Item__c lineItem = new Production_Line_Item__c();
                        if(mps.containsKey(parentData.ParameterId)){
                            lineItem.Production__c = mps.get(parentData.ParameterId);
                        }
                        if(string.isNotBlank(childData.Id)) {    
                            lineItem.Id = childData.Id;
                        }
                        if (monthName.contains('PLAN')) {
                            monthName = monthName.replace('PLAN', '').trim();  // Remove the word "ACTUAL" and trim extra spaces
                        }
                        
                        lineItem.Month_Name__c = monthName;
                        
                        lineItem.Start_Date__c = DateFormatProceedController.getStartDateOfMonth(date.today(),monthName.toUpperCase());
                        lineItem.End_Date__c = DateFormatProceedController.getEndDateOfMonth(date.today(),monthName.toUpperCase());
                        lineItem.Opening_Stock__c = childData.Opening_Stock;
                        lineItem.Production_Stock__c = childData.production_Stock;
                        lineItem.Domestic_Sales__c = childData.Domestic_Sales;
                        lineItem.Export_Sales__c = childData.Export_Sales;
                        lineItem.CC_Sales__c = childData.CC_Sales;
                        
                        if(childData.isCurrentMonth){
                            lineItem.Actual_Opening_Stock__c = childData.Actual_Opening_Stock;
                            lineItem.Actual_Production__c = childData.Actual_production_Stock;
                            lineItem.Actual_Domestic_Sales__c = childData.Actual_Domestic_Sales;
                            lineItem.Actual_Export_Sales__c = childData.Actual_Export_Sales;
                            lineItem.Actual_CC__c = childData.Actual_CC_Sales;
                        }
                        pline.add(lineItem);  // Insert
                    }
                }
            }
            if(pline.size() > 0){
                system.debug('pline-->'+pline.size());
                upsert pline;
                
                for(Production_Line_Item__c ple :  [Select Id,Name ,Product_Category__c,Month_Name__c from Production_Line_Item__c where Id IN : pline]){
                    string key = ple.Product_Category__c + '-' +ple.Month_Name__c;
                    toBeUpdateMap.put(key.toUpperCase(),ple.Id);
                    system.debug('toBeUpdateMap-->'+toBeUpdateMap);
                    
                }
            }
            
            
            system.debug('toBeUpdateMap-->'+toBeUpdateMap);
            List<Production_Line_Item__c> plinetoToUpdate = new List<Production_Line_Item__c>();
            for (Production parentData : productionList) {
                for (ProductionLineItem childData : parentData.childData) {
                    String monthName = childData.monthName.toUpperCase();
                    
                    if(monthName.contains('ACTUAL')){  
                        system.debug('toBeUpdateMap-->'+monthName);
                        monthName = monthName.replace('ACTUAL', '').trim();  // Remove the word "ACTUAL" and trim extra spaces
                        string key = childData.ParameterId + '-' +monthName;
                        key = key.toUpperCase();
                        system.debug('key-->'+key);
                        if(toBeUpdateMap.containsKey(key)){
                            system.debug('inside key-->'+key+childData.isCurrentMonth);
                            Production_Line_Item__c lineItem = new Production_Line_Item__c();
                            lineItem.Id = toBeUpdateMap.get(key);
                            
                            
                            if(childData.isCurrentMonth){
                                lineItem.Actual_Opening_Stock__c = childData.Actual_Opening_Stock;
                                lineItem.Actual_Production__c = childData.Actual_production_Stock;
                                lineItem.Actual_Domestic_Sales__c = childData.Actual_Domestic_Sales;
                                lineItem.Actual_Export_Sales__c = childData.Actual_Export_Sales;
                                lineItem.Actual_CC__c = childData.Actual_CC_Sales;
                            }
                            plinetoToUpdate.add(lineItem); 
                            
                        }
                    }
                }
            }
            if(plinetoToUpdate.size() > 0){
                system.debug('toBeUpdateMap-->'+toBeUpdateMap);
                update plinetoToUpdate;
            }
            return 'Success';
        }catch(exception e)
        {
            return e.getMessage()+'-'+e.getLineNumber();
        }
    }
    
    
    public static void getMonthIndex(){
        
    }
    
    
    // Method to save the data
    
    public class Production {
        public String Id;
        public String ParameterId;
        public String ParameterName;
        public List<ProductionLineItem> childData;
    }
    
    // Wrapper class for the child ProductionLineItem
    public class ProductionLineItem {
        public String index;
        public String Id;
        public String pId;
        public String ParameterId;
        public Decimal Closing_Stock;
        public Decimal Domestic_Sales;
        public Decimal Export_Sales;
        public String monthName;
        public Decimal Opening_Stock;
        public Decimal production_Stock;
        public Decimal Total_Stock;
        public Decimal Total_Sales;
        public Decimal CC_Sales;
        public Boolean targetAmountEdit;
        public Decimal Actual_Closing_Stock;
        public Decimal Actual_Domestic_Sales;
        public Decimal Actual_Export_Sales;
        public Decimal Actual_Opening_Stock;
        public Decimal Actual_production_Stock;
        public Decimal Actual_Total_Stock;
        public Decimal Actual_Total_Sales;
        public Decimal Actual_CC_Sales;
        public boolean isCurrentMonth;
    }
}