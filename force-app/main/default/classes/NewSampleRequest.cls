public class NewSampleRequest {
    @AuraEnabled(Cacheable=true)
    public static string  getExistingProducts(string Id){
        string sOb = getObjectTypeFromId(Id);
        Map<string,object>  mp = new Map<string,object> ();
        List<String> locationParts = new List<String>();
        if(sOb=='Lead'){
            Lead ld =  [select Id,Name,CurrencyISOCode,Company,Area__r.Name,Product_Group_New__c	,City__r.Name,Postal_Code__r.Name,State__r.Name,Country__r.Name,Street__c from Lead where Id =:Id];
            if (String.isNotEmpty(ld.Street__c?.trim())) {
                locationParts.add(ld.Street__c.trim());
            }
            if (String.isNotEmpty(ld.Area__r?.Name?.trim())) {
                locationParts.add(ld.Area__r.Name.trim());
            }
            if (String.isNotEmpty(ld.City__r?.Name?.trim())) {
                locationParts.add(ld.City__r.Name.trim());
            }
            if (String.isNotEmpty(ld.Postal_Code__r?.Name?.trim())) {
                locationParts.add(ld.Postal_Code__r.Name.trim());
            }
            if (String.isNotEmpty(ld.State__r?.Name?.trim())) {
                locationParts.add(ld.State__r.Name.trim());
            }
            if (String.isNotEmpty(ld.Country__r?.Name?.trim())) {
                locationParts.add(ld.Country__r.Name.trim());
            }
            
            // Combine all parts into a single string (with a separator such as comma or space)
            String fullAddress = String.join(locationParts, ', ');
            
            
            wrapper wrp = new wrapper();
            wrp.Name = ld.Company;
            wrp.Sample_Request_Type = 'New Product New Customer';
            wrp.Sample_Requested_Date =null;
            wrp.Mode_of_Transport = null;
            wrp.Expected_By = null;
            wrp.CurrencyISOCode = ld.CurrencyIsoCode;
            if(!test.isRunningTest())
                if(string.isNotBlank(ld.Product_Group_New__c)){
            wrp.Approver = [select Approver__c from Product_Group__c where Name=:ld.Product_Group_New__c limit 1].Approver__c;
                }
            wrp.Use_Lead_Address_for_Sample_Dispatch_To = null;
            wrp.Adrress = fullAddress;
            wrp.Id = ld.Id;
            
            
            
            List<Product_Interested__c> picList   = [Select Id,Lead__c,Product__c ,Product_Code__c,New_Product__c,New_Product_Name__c,Pricebook_Entry_Id__c,List_Price__c,Product_Family__c,Product__r.Name,Product__r.ProductCode,Expected_Price__c,Volume_in_Kgs__c 
                       from Product_Interested__c where Lead__c =:Id]; 
            List<wrapperLine> wrpLineList = new List<wrapperLine>();
            for(Product_Interested__c pdl : picList){
                wrapperLine wrpLine = new wrapperLine();
                wrpLine.family = pdl.Product_Family__c;
                wrpLine.prodId = pdl.Product__c;
                wrpLine.prodName =pdl.Product__r.Name ;
                wrpLine.prodCode = pdl.Product_Code__c;
                wrpLine.pbeId = pdl.Pricebook_Entry_Id__c;
                wrpLine.volume = pdl.Volume_in_Kgs__c;
                wrpLine.New_Product =pdl.New_Product__c ;
                wrpLine.New_Product_Name =pdl.New_Product_Name__c ;
                wrpLine.unitPrice = pdl.List_Price__c;
                wrpLine.remark ='' ;
                wrpLine.address = null;
                wrpLineList.add(wrpLine);
            }
            mp.put('lead',wrp);
            mp.put('Product_Interested',wrpLineList);
        }
        else if(sOb=='Account'){
            Account ld =  [select Id,CurrencyIsoCode,Name,Product_Group__c/*Area__r.Name,City__r.Name,Postal_Code__r.Name,State__r.Name,Country__r.Name,Street__c*/ from Account where Id =:Id];
            String fullAddress = '';
            
            wrapper wrp = new wrapper();
            wrp.Name = ld.Name;
            wrp.Sample_Request_Type = 'New Product Existing Customer';
            wrp.Sample_Requested_Date =null;
            wrp.Mode_of_Transport = null;
            wrp.CurrencyISOCode = ld.CurrencyIsoCode;
            if(string.isNotBlank(ld.Product_Group__c)){
            wrp.Approver = [select Approver__c from Product_Group__c where Id=:ld.Product_Group__c limit 1].Approver__c;
            }
            wrp.Expected_By = null;
            wrp.Use_Lead_Address_for_Sample_Dispatch_To = null;
            wrp.Adrress = fullAddress;
            wrp.Id = ld.Id;
            
            
            
            List<Product_Interested__c> picList;
            picList = [Select Id,Lead__c,Product__c ,Product_Code__c,New_Product__c,New_Product_Name__c,Pricebook_Entry_Id__c,List_Price__c,Product_Family__c,Product__r.Name,Product__r.ProductCode,Expected_Price__c,Volume_in_Kgs__c 
                       from Product_Interested__c where Account__c =:Id]; 
            List<wrapperLine> wrpLineList = new List<wrapperLine>();
            for(Product_Interested__c pdl : picList){
                wrapperLine wrpLine = new wrapperLine();
                wrpLine.family = pdl.Product_Family__c;
                wrpLine.prodId = pdl.Product__c;
                wrpLine.prodName =pdl.Product__r.Name ;
                wrpLine.prodCode = pdl.Product_Code__c;
                wrpLine.pbeId = pdl.Pricebook_Entry_Id__c;
                wrpLine.volume = pdl.Volume_in_Kgs__c;
                wrpLine.New_Product =pdl.New_Product__c ;
                wrpLine.New_Product_Name =pdl.New_Product_Name__c ;
                wrpLine.unitPrice = pdl.List_Price__c;
                wrpLine.remark ='' ;
                wrpLine.address = '';
                wrpLineList.add(wrpLine);
            }
            mp.put('lead',wrp);
            mp.put('Product_Interested',wrpLineList);
        }
        
        else if(sOb=='Opportunity'){
            Opportunity ld =  [select Id,Name,Product_Group__c,CurrencyIsoCode from Opportunity where Id =:Id];
            String fullAddress = '';
            wrapper wrp = new wrapper();
            wrp.Name = ld.Name;
            wrp.Sample_Request_Type = 'New Product Existing Customer';
            wrp.Sample_Requested_Date =null;
            wrp.Mode_of_Transport = null;
                        wrp.CurrencyISOCode = ld.CurrencyIsoCode;
			if(string.isNotBlank(ld.Product_Group__c)){
            wrp.Approver = [select Approver__c from Product_Group__c where Id=:ld.Product_Group__c limit 1].Approver__c;
            }
            wrp.Expected_By = null;
            wrp.Use_Lead_Address_for_Sample_Dispatch_To = null;
            wrp.Adrress = fullAddress;
            wrp.Id = ld.Id;
            List<OpportunityLineItem> picList;
            picList = [Select Id,Product2Id,Product2.Name,ProductCode,Description,Quantity,unitPrice,Product2.family,pricebookEntryId
                       from OpportunityLineItem where OpportunityId =:ld.Id]; 
            
            
            List<wrapperLine> wrpLineList = new List<wrapperLine>();
            for(OpportunityLineItem pdl : picList){
                wrapperLine wrpLine = new wrapperLine();
                wrpLine.family = pdl.Product2.family;
                wrpLine.prodId = pdl.Product2Id;
                wrpLine.prodName =pdl.Product2.Name ;
                wrpLine.prodCode = pdl.ProductCode;
                wrpLine.pbeId = pdl.pricebookEntryId;
                wrpLine.volume = pdl.Quantity;
                wrpLine.New_Product =false;
                wrpLine.New_Product_Name =null;
                wrpLine.unitPrice = pdl.unitPrice;
                wrpLine.remark ='' ;
                wrpLine.address = '';
                wrpLineList.add(wrpLine);
            }
            mp.put('lead',wrp);
            mp.put('Product_Interested',wrpLineList);
            
        }
        
        else if(sOb=='Quote'){
            Quote ld =  [select Id,Name from Quote where Id =:Id];
            String fullAddress = '';
            wrapper wrp = new wrapper();
            wrp.Name = ld.Name;
            wrp.Sample_Request_Type = 'New Product Existing Customer';
            wrp.Sample_Requested_Date =null;
            wrp.Mode_of_Transport = null;
            wrp.Expected_By = null;
            wrp.Use_Lead_Address_for_Sample_Dispatch_To = null;
            wrp.Adrress = fullAddress;
            wrp.Id = ld.Id;
            List<QuoteLineItem> picList;
            picList = [Select Id,Product2Id,Product2.Name,Product2.ProductCode,Description,Quantity,unitPrice,Product2.family,pricebookEntryId
                       from QuoteLineItem where QuoteId =:ld.Id]; 
            
            
            List<wrapperLine> wrpLineList = new List<wrapperLine>();
            for(QuoteLineItem pdl : picList){
                wrapperLine wrpLine = new wrapperLine();
                wrpLine.family = pdl.Product2.family;
                wrpLine.prodId = pdl.Product2Id;
                wrpLine.prodName =pdl.Product2.Name ;
                wrpLine.prodCode = pdl.Product2.ProductCode;
                wrpLine.pbeId = pdl.pricebookEntryId;
                wrpLine.volume = pdl.Quantity;
                wrpLine.New_Product =false;
                wrpLine.New_Product_Name =null;
                wrpLine.unitPrice = pdl.unitPrice;
                wrpLine.remark ='' ;
                wrpLine.address = '';
                wrpLineList.add(wrpLine);
            }
            mp.put('lead',wrp);
            mp.put('Product_Interested',wrpLineList);
            
        }
        return  JSON.serialize(mp);       
    }
    
    
    public static String getObjectTypeFromId(String recordId) {
        string sObjectType=  '';
        if (String.isNotEmpty(recordId)) {
            String prefix = recordId.substring(0, 3);
            
            if (prefix == '00Q') {
                sObjectType= 'Lead';
            } else if (prefix == '001') {
                sObjectType= 'Account';
            } else if (prefix == '006') {
                sObjectType= 'Opportunity';
            } else if (prefix == '0Q0') {
                sObjectType= 'Quote';
            }
        }
        return sObjectType;
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
    public static Map<string,string> saveProductInterested(Id Id, string sample, string JS,string defaultApprover){
        system.debug('Id'+Id);
        //system.debug('JS'+JS);
        Map<string,string> result = new Map<string,string>();
        try{
            
            Map<string,Object> samBookMap = (Map<string,Object>)JSON.deserializeUntyped(sample);
            Sample_Booking__c sbo = new Sample_Booking__c();
            String typeOfObj =  getObjectTypeFromId(Id);
            system.debug('typeOfObj-->'+typeOfObj);
            if(typeOfObj=='Lead'){
                sbo.Lead__c = Id;
            }
            if(typeOfObj=='Account'){
                sbo.Account__c = Id;
            }
            if(typeOfObj=='Opportunity'){
                sbo.Opportunity__c = Id;
            }
            if(typeOfObj=='Quote'){
                sbo.Quote__c = Id;
            }
            
            
            //sbo.Lead__c = Id;
            sbo.Sample_Request_Type__c = (string)samBookMap.get('Sample_Request_Type');
            sbo.New_Customer__c = (string)samBookMap.get('New_Customer');
            sbo.Existing_Customer__c = (string)samBookMap.get('Existing_Customer');
            sbo.Sample_Requested_Date__c = date.valueOf((string)samBookMap.get('Sample_Requested_Date'));
            sbo.Mode_of_Transport__c = (string)samBookMap.get('Mode_of_Transport');
            sbo.Approver__c = defaultApprover;
            sbo.Expected_By__c = date.valueOf((string)samBookMap.get('Expected_By'));
            sbo.Use_Lead_Address_for_Sample_Dispatch_To__c = (boolean)samBookMap.get('Use_Lead_Address_for_Sample_Dispatch_To');
            insert sbo;
            
            List<Sample_Line_Item__c> piList = new List<Sample_Line_Item__c>();
            
            List<Object> jsList = (List<Object>)JSON.deserializeUntyped(JS);
            
            for(Object obj : jsList){
                Map<string,object>objMap = (Map<string,object>)obj;
                Sample_Line_Item__c pm = new Sample_Line_Item__c();
                pm.Sample_Booking__c  =sbo.Id ;
                if(string.isNotBlank((string)objMap.get('prodId'))){
                    pm.Product__c = (Id)objMap.get('prodId');
                }
                string var = string.valueOf(objMap.get('volume'));
                pm.Quantity__c = Decimal.valueOf(var);
                //pm.Approver__c = defaultApprover;
                pm.Product_Family__c = (string) objMap.get('family');
                pm.Remarks__c = (string) objMap.get('remark');
                pm.Pricebook_Entry_Id__c = (string)objMap.get('pbeId');
                pm.List_Price__c = double.valueOf(objMap.get('unitPrice'));
                pm.Address__c =  (string) objMap.get('address');
                pm.New_Product_Name__c = (string) objMap.get('New_Product_Name');
                pm.New_Product__c = (boolean) objMap.get('New_Product');
                piList.add(pm);
            }
            
            if(piList.size() > 0){
                insert piList;
            }
            
            result.put('message','success');
            result.put('Id',sbo.Id);
        }catch(exception e){
            system.debug(e);
            result.put('message',e.getMessage()+e.getLineNumber()); 
        }
        return result;
    }  
    
    
    public class wrapper {
        public string Name;
        public string Approver;
        public string Adrress;
        public String Sample_Request_Type;
        public String New_Customer;
        public String CurrencyISOCode;
        public String Sample_Requested_Date;
        public String Mode_of_Transport;
        public String Expected_By;
        public String Use_Lead_Address_for_Sample_Dispatch_To;
        public String Id;
    }
    
    
    public class wrapperLine {
        public string family;
        public string prodId;
        public string prodName;
        public string prodCode;
        public Decimal volume;
        public string pbeId;
        public boolean New_Product;
        public string New_Product_Name;
        public Decimal unitPrice;
        public string remark;
        public string address;
    }
    
}