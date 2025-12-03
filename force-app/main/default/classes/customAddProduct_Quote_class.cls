public without sharing class customAddProduct_Quote_class {
	 @AuraEnabled
    public static String findProduct(string recordId, List<String> productFamily){
        system.debug('recordId '+recordId);
        Quote op = [SELECT Id, Pricebook2Id,CurrencyISOCode,AccountId, Pricebook2.Name FROM Quote WHERE Id =:recordId];
        
        List<QuoteLineItem>  oplIst = [select Id,Product2Id from QuoteLineItem where QuoteId =:recordId ]; 
        
        set<Id>existingProdId = new set<Id>();
        if(oplIst.size() > 0){for(QuoteLineItem opr : oplIst){ existingProdId.add(opr.Product2Id);}
                              
                              
                              
                             }
        wrapperClass wc = new wrapperClass();
        wc.priceBook = op.Pricebook2.Name;
         wc.CurrencyISOCode = op.CurrencyISOCode;
        
     /*   string productQuery = 'select Id,Name,Family  from Product2 where Id NOT IN :existingProdId';
        
        if(productFamily.size() > 0){ productQuery+=' where Family IN : productFamily';
                                     
                                     // productQuery+=' where Family IN '+productFamily;
                                    }*/
        
        String productQuery = 'SELECT Id, Name FROM Product2 ';
        if (!productFamily.isEmpty()) {
            productQuery += 'WHERE Family IN :productFamily';  // ✅ Space added before 'WHERE'
        }

        
        set<Id> prodId = new set<Id>();
        //List<Product2> pdList = database.query(productQuery);
        for(Product2 pd : database.query(productQuery)){
            prodId.add(pd.Id);
        }
        
        
        String query = 'SELECT Id ,UnitPrice,Product2Id,Product2.Name,Product2.Family,Product2.ProductCode,Product2.Description FROM PricebookEntry WHERE Pricebook2Id = \''+ op.Pricebook2Id +'\' AND IsActive = true AND Product2Id IN :prodId';
        system.debug('query-->'+query);
        List<PricebookEntry> lstPBE = (List<PricebookEntry>)Database.query(query);
        
        List<ProductWrapper> lstProduct= new List<ProductWrapper>();
        integer i = 0;
        List<string> prodCodeList   = new  List<string>();                                     
        for(PricebookEntry pbe : lstPBE){
            if(!prodCodeList.contains(pbe.Product2.ProductCode)){
                prodCodeList.add(pbe.Product2.ProductCode);
                ProductWrapper pw = new ProductWrapper();
                pw.Id = pbe.Id;
                pw.purl = '/lightning/r/' +pbe.Id+'/view';
                pw.Product2Id = pbe.Product2Id;
                pw.Name =pbe.Product2.Name;
                pw.ProductCode = pbe.Product2.ProductCode;
                
                //pw.PackSize = pbe.Product2.Pack_Size__c;
                pw.Family = pbe.Product2.Family;
                
                pw.Description= pbe.Product2.Description;
                pw.Price = pbe.UnitPrice;
                pw.SalesPrice = null;
                /*pw.hsnMasterId = pbe.Product2.HSN_Code__c;
pw.hsnMasterCode =pbe.Product2.HSN_Code__r.Name;
pw.CGSTRATE = pbe.Product2.HSN_Code__r.CGST_Rate__c;
pw.SGSTRATE = pbe.Product2.HSN_Code__r.SGST_Rate__c;
pw.IGSTRATE = pbe.Product2.HSN_Code__r.IGST_Rate__c;*/
                pw.index = i++;
                pw.showError = false;
                lstProduct.add(pw);
                system.debug(lstProduct);
            }
        }
        wc.productList = lstProduct;
        return JSON.serialize(wc);
    }


    @AuraEnabled(cacheable=true)
public static List<QuoteLineItem> findRecentPrices(String accountId, String productId) {
    system.debug(accountId+' -'+ productId);
    if (String.isEmpty(accountId) || String.isEmpty(productId)) {
        return new List<QuoteLineItem>();
    }
    
    // Query to fetch the last 5 prices for the given account and product
    List<QuoteLineItem> oliList = [
        SELECT Id, QuoteId, Product2.Name, UnitPrice, TotalPrice, Quantity, CreatedDate,
            Quote.Account.Name, Quote.Name, ListPrice
        FROM QuoteLineItem
        WHERE QuoteId IN (SELECT Id FROM Quote WHERE AccountId = :accountId)
        AND Product2Id = :productId
        ORDER BY CreatedDate DESC
        LIMIT 5
    ];
    
    return oliList;
}
    
    @AuraEnabled
    public static List<PicklistValue> getproductfamily(){
        String strObjectName = 'Product2';
        String strPicklistField = 'Family';
        Map<String, String> mapPickListValues = new Map<String, String>();
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(strObjectName);
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe();
        Map<String, Schema.SObjectField> mapFields = objDescribeSobject.fields.getMap();
        List<Schema.PicklistEntry> lstPickListValues = mapFields.get(strPicklistField).getDescribe().getPickListValues();
        List<PicklistValue> pvList = new List<PicklistValue>();
        for (Schema.PicklistEntry objPickList : lstPickListValues) {
            PicklistValue pv = new PicklistValue(objPickList.getValue(), objPickList.getLabel());
            pvList.add(pv);
            //system.debug(pvList);
        }
        return pvList;
        
    }
    
    @AuraEnabled
    public static String saveProducts( String recordData, String recId ){
        
        List<ProductWrapper> wc  = (List<ProductWrapper>)json.deserialize(recordData, List<ProductWrapper>.class);
        List<QuoteLineItem> lstOpp = new List<QuoteLineItem>();
        for(ProductWrapper pw : wc){
            System.debug(' pw' + pw);
            QuoteLineItem oli = new QuoteLineItem();
            oli.Quantity = pw.Quantity;
            //oli.Product_Category__c = pw.Family;
            oli.UnitPrice = pw.SalesPrice;
            oli.ServiceDate = system.today();
            oli.Discount = pw.Discount;
            oli.Description = pw.LineDescription;
            oli.QuoteId = recId;//'0065j00000N2RXiAAN';
            oli.Product2Id = pw.Product2Id;
            /* oli.HSN_Master__c = pw.hsnMasterId;
oli.CGST_RATE__c = pw.CGSTRATE;
oli.SGST_RATE__c = pw.SGSTRATE;
oli.IGST_RATE__c = pw.IGSTRATE;
*///oli.Pack_Size__c = pw.PackSize;
            oli.PricebookEntryId = pw.Id;//'01u5j000003Pq51AAC';
            lstOpp.add(oli);
            System.debug(' pw' + lstOpp);
            
        }
        try {
            insert lstOpp;
            return 'success';
        } catch (Exception e) {
            System.debug(e.getMessage());
            return 'error';
        }        
    }
    
    public with sharing class wrapperClass {
        public String priceBook;
        public string CurrencyISOCode;
        public List<ProductWrapper> productList;
    }
    
    public with sharing class ProductWrapper {
        public String Name;
        public String Id;
        public String purl;
        public String Product2Id;
        public String ProductCode;
        public String PackSize;
        public String hsnMasterId;
        public String hsnMasterCode;
        public integer index;
        public Decimal Price;
        public Decimal SalesPrice;
        public Decimal Quantity = 0;
        public String Family;
        public Date PDate;
        public String Description;
        public String LineDescription;
        public decimal CGSTRATE;
        public decimal IGSTRATE;
        public decimal SGSTRATE;
        public boolean showError;
        public decimal Discount = 0;
    }
    
    public class PicklistValue {
        @auraenabled
        public String label {get;set;}
        @auraenabled
        public String value {get;set;}
        
        public PicklistValue(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
}