public class Lwc_SNOP_SalesReportController {
    
    
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
    
    
    @AuraEnabled
    public static String getSalesDetail(String productionId) {
        List<Production__c> proList= [SELECT Id, Product_Category__c,Name,Product_Category__r.Name,Product_Category__r.Product_Group__c,
                                      (SELECT Id, Start_Date__c, End_Date__c,Domestic_Sales__c,Closing_Stock__c,CC_Sales__c,Export_Sales__c,Month_Name__c,  
                                       Actual_Closing_Stock__c,Actual_Domestic_Sales__c,Actual_Export_Sales__c,Actual_Opening_Stock__c,Actual_production__c,Actual_Total_Stock__c,Actual_Total_Sales__c
                                       ,Opening_Stock__c,Actual_CC__c,Rate__c ,Actual_Sales_Value__c,Actual_Rate__c,Sales_Value__c, Production__c , Production_Stock__c ,Total_Sales__c,Total_Stock__c FROM Production_Line_Items__r where End_Date__c >=: system.today()
                                       ORDER BY Start_Date__c) FROM Production__c  
                                      where ID IN (select Production__c from Production_Line_Item__c where End_Date__c >=: system.today())
                                      and Product_Category__r.Product_Group__c !=:null
                                      ORDER BY Product_Category__r.Name ASC];
        
        
        List<object> result = new List<object>();
        for (Production__c record: proList) {
            Map < String, Object > tempMap = new Map < String, Object > ();
            tempMap.put('Id', record.Id);
            tempMap.put('ParameterId', record.Product_Category__c);
            tempMap.put('ParameterName', record.Product_Category__r.Name);
            tempMap.put('ParameterPGId', record.Product_Category__r.Product_Group__c);
            integer i = 0;
            List<Map < String, Object >> objMaplist = new List<Map < String, Object >>();
            for (Production_Line_Item__c childRec: record.Production_Line_Items__r) {
                Map < String, Object > childMap = new Map < String, Object > ();
                Map < String, Object > newActualMap = new Map < String, Object > ();
                if(childRec.Start_Date__c >= System.today()){
                    childMap.put('ParameterId', childRec.Id);
                    childMap.put('index',i);
                    childMap.put('randomNum',0);
                    childMap.put('Domestic_Sales', childRec.Domestic_Sales__c!= null ? childRec.Domestic_Sales__c.setScale(2) : 0);
                    childMap.put('Production', childRec.Production_Stock__c!= null ? childRec.Production_Stock__c.setScale(2) : 0);
                    childMap.put('monthName',childRec.Month_Name__c.toUpperCase());
                    childMap.put('rate',childRec.Rate__c != null ? childRec.Rate__c.setScale(2) : 0);
                    childMap.put('salesValue',childRec.Sales_Value__c != null ? childRec.Sales_Value__c.setScale(2) : 0);
                    childMap.put('targetAmountEdit', false);
                    i++;
                    objMaplist.add(childMap);
                    
                }
                else
                    if(childRec.Start_Date__c <= System.today() && System.today() <= childRec.End_Date__c){
                        
                        childMap.put('ParameterId', childRec.Id);
                        childMap.put('index',i);
                        childMap.put('randomNum',0);
                        childMap.put('monthName', 'PLAN '+childRec.Month_Name__c.toUpperCase());
                        childMap.put('Domestic_Sales', childRec.Domestic_Sales__c!= null ? childRec.Domestic_Sales__c.setScale(2) : 0);
                        childMap.put('Production', childRec.Production_Stock__c!= null ? childRec.Production_Stock__c.setScale(2) : 0);
                        
                        childMap.put('isCurrentMonth', false);
                        childMap.put('targetAmountEdit', false);
                        childMap.put('rate',childRec.Rate__c != null ? childRec.Rate__c.setScale(2) : 0);
                        childMap.put('salesValue',childRec.Sales_Value__c != null ? childRec.Sales_Value__c.setScale(2)  : 0);
                        objMaplist.add(childMap);
                        i++;
                        
                        newActualMap.put('ParameterId', childRec.Id);
                        newActualMap.put('index',i);
                        newActualMap.put('randomNum',0);
                        newActualMap.put('monthName', 'ACTUAL '+childRec.Month_Name__c.toUpperCase());
                        newActualMap.put('Actual_Production', childRec.Actual_Production__c !=null ? childRec.Actual_Production__c.setScale(2) : 0);
                        newActualMap.put('Actual_Domestic_Sales', childRec.Actual_Domestic_Sales__c != null ? childRec.Actual_Domestic_Sales__c.setScale(2) : 0);
                        newActualMap.put('targetAmountEdit', false);
                        newActualMap.put('rate',childRec.Actual_Rate__c != null ?childRec.Actual_Rate__c.setScale(2) :0);
                        newActualMap.put('salesValue',childRec.Actual_Sales_Value__c != null ? childRec.Actual_Sales_Value__c.setScale(2) : 0);
                        objMaplist.add(newActualMap);
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
    public static String getSaleSave(String js){
        try {
            system.debug('js-->'+js);
            List<SalesData> objMap = parse(js);
            Map<Id,Production_Line_Item__c> pliList = new Map<Id,Production_Line_Item__c> ();
            for (SalesData ibj : objMap) {
                if(ibj.monthName.contains('ACTUAL')){
                Production_Line_Item__c pli  =  new Production_Line_Item__c();
                pli.Id = ibj.ParameterId;
                Decimal rate = ibj.rate;
                pli.Actual_Rate__c = rate;
                if(!ibj.monthName.contains('ACTUAL')){
                    pli.rate__c = rate; 
                }
                pliList.put(pli.Id,pli);
                }
            }
            
            if(pliList.size()> 0){
                update pliList.values();
            }
            
            
            Map<Id,Production_Line_Item__c> pliList1 = new Map<Id,Production_Line_Item__c> ();
            for (SalesData ibj : objMap) {
                if(!ibj.monthName.contains('ACTUAL')){
                Production_Line_Item__c pli  =  new Production_Line_Item__c();
                pli.Id = ibj.ParameterId;
                Decimal rate = ibj.rate;
                pli.rate__c = rate; 
                pliList1.put(pli.Id,pli);
                }
            }
            
            if(pliList1.size()> 0){
                system.debug('pli-->'+pliList1);
                update pliList1.values();
            }
            return 'Success';
            
        } catch (Exception e) {
            return e.getMessage() + ' - ' + e.getLineNumber();
        }
    }
    
    public static List<SalesData> parse(string js){
        return  (List<SalesData>)JSON.deserialize(js, List<SalesData>.class);
    }
    
    public class SalesData {
        public Decimal salesValue;
        public Decimal rate;
        public Boolean targetAmountEdit;
        public Boolean isCurrentMonth;
        public Decimal Production;
        public Decimal Domestic_Sales;
        public String monthName;
        public Integer randomNum;
        public Integer index;
        public String ParameterId;
    }
    
    
}