public class QuotationPDFController {
    public List<Product2> productPrices { get; set; }
    public id qId {get;set;}
    public Quote quData {get;set;}
    public Decimal totalQuantity { get; set; }
    public Decimal totalValueINR{ get; set; } 
    // public string address {get;set;}
    public string PINo {get;set;}
    public String currentMonthYear { get; set; }
    public string QuoteNo {get;set;}
    public Date QuoteDate {get;set;}
    
    public string Paymentterms {get;set;}
    public string AdCode {get;set;}
    public string TaxId {get;set;}
    public Decimal IGSTrate { get; set; }
    public string PSS {get;set;}
    public Decimal PotentialQtyPerYear { get; set; }
    public Decimal IGSTValue { get; set; }
    public decimal TotalGst {get;set;}
    public string no2words {get;set;}
    public Date PIDate {get;set;}
    public List<QuoteLineItem> qItem {get;set;}
    public string pdfName{get;set;}
    public boolean showSaveQuote {get;set;}
    public string emailId{get;set;}
    public string BillingName {get;set;}
    public string Description {get;set;}
    public string ShippingName {get;set;}
    public string Baddress {get;set;}
    public string Saddress {get;set;}
    public boolean isValid{get;set;}
    public string CC_Addresses{get; set;}
    public String subject {get; set;}
    public String body {get; set;}
    public Boolean createNew {get; set;}
    public PageReference pdf {get; set;}
    public String pdfUrl {get; set;}
    public QuotedataWrapper quoteRecord {get;set;}
    public string CurrencyIsoCode {get;set;}
    public string IECNO {get;set;}
    public string CustomsReg {get;set;}
    public string CINNo {get;set;}
    public string PAN {get;set;}
    public Decimal SGSTrate { get; set; }
    public Decimal SGSTValue { get; set; }
    public Decimal CGSTrate { get; set; }
    public Decimal CGSTValue { get; set; }
    
    public string GSTIN {get;set;}
	public string AcntNo {get;set;}
    public string BankName {get;set;}
    public string Bankbranch {get;set;}
    public string SwiftCode {get;set;}
    public string CSwiftCode {get;set;}
    public string OBAcntNo {get;set;} 
    public string OBBankName {get;set;} 
    public string OBBankbranch {get;set;} 
    public string OBSwiftCode {get;set;} 
    public string OBCSwiftCode {get;set;} 
    public Boolean formSubmitted { get; set; }
    public string Document {get;set;}
    public string PriceQuoted { get; set; }
    public string Salestype { get; set; }
   // public string BusinessCatNo { get; set; }
   	public boolean sendEmailSuccess { get; set; }
    public boolean sendEmailError { get; set; }
    public string errorMessage { get; set; }
    public string CompanyAddress { get; set; }
    public string CompanyPhone { get; set; }
    public string CompanyPan { get; set; }
    public string CompanyEmail { get; set; }
    public string CompanyGSTIN { get; set; }
    public string SalesPerson { get; set; }
    public string SalesPersonContact { get; set; }
    public string MSME { get; set; }
    public string BillState { get; set; }
    public Decimal BillStateCode { get; set; }
    public string ShipState { get; set; }
    public Decimal ShipStateCode { get; set; }
    public string Transporter { get; set; }
    public string Destination { get; set; }
    public string BillGst { get; set; }
    public string ShipGst { get; set; }
    public string BillingMode { get; set; }
    public string TermsConditions { get; set; }
    public string QuoteContactPerson { get; set; }
    public string QuoteContactEmail { get; set; }
    public string QuoteContactMobile { get; set; }
    public string Carraige { get; set; }
    public Decimal GrandTotal { get; set; }
    public Decimal ShippingHandling { get; set; }
    public Decimal Tax { get; set; }
    public List<QuoteLineItemWrapper> lineItems {get; set;}
    public String userName { get; set; }
    public String userTitle { get; set; }
    public String userMobile { get; set; }

    
     public QuotationPDFController(){
        
        
        sendEmailSuccess = false;
        sendEmailError = false;
         
        errorMessage = '';
        
        
        
        qId = ApexPages.currentPage().getparameters().get('id');
        
        if(qId ==null){
            qId ='0Q0Hz00000027U2KAI';
            system.debug('qId'+qId);
           // ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Error, 'Quote doesn't exist));
          //  isValid = false;
        }
         
         quoteRecord = new QuotedataWrapper();
         showSaveQuote = true;
         Decimal granTotal = 0;
        // Decimal ListPrice = 0;
        totalQuantity = 0;
        totalValueINR = 0;
         quData =[SELECT Id,AccountId,AdditionalAddress,AdditionalName,Agent_Name__c,Approved_Date__c,Bill_To__c,BillingAddress,BillingName,Commission_Type__c,Commission_Value__c,Company_Name__c,ContactId,
                  ContractId,CreatedById,Currency_Type__c,Delivery_Terms__c,Description,Discount,Document_Type__c,Email,Fax,Freight_Terms__c,GrandTotal,INCO_Terms__c,LastModifiedById,LastModifiedDate,
                  Legalization__c,LineItemCount,OpportunityId,OwnerId,Palleltization__c,Payment_Method__c,Payment_Terms__c,Phone,Product_Group__c,CurrencyIsoCode,ExpirationDate,Quote_Expiry_Status__c,Name,
                  QuoteNumber,Quote_Source__c,QuoteToAddress,QuoteToName,Quote_Type__c,Ship_To__c,ShippingAddress,ShippingName,ShippingHandling,Shipping_Instructions__c,Status,
                  Subtotal,IsSyncing,Tax,TotalPrice,Validity_Period_in_days__c, Opportunity.Owner.Email
                  FROM Quote where ID =:qId];
         system.debug('quData'+quData);
         
         
         // Retrieve the current user or user associated with the quote
         User currentUser = [SELECT Id, Name, Title, MobilePhone FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
         
         // Assign values to variables
         userName = currentUser.Name;
         userTitle = currentUser.Title;
         userMobile = currentUser.MobilePhone != null ? currentUser.MobilePhone : ''; // Handle null mobile number
         
         // Get the current month and year
         Datetime now = Datetime.now();
         currentMonthYear = now.format('MMMM yyyy', 'en_US'); 
         
        pdf = Page.QuotationPDF;
        pdfURL = '/apex/QuotationPDF?id='+qId+'#toolbar=0';
        pdfName = quData.Name;
        QuoteNo = quData.QuoteNumber;
       // QuoteDate = quData.Quote_Created_Date__c;
        formSubmitted = false;
        isValid = true;
        createNew = true;
        subject = '';
        subject += 'Excel - Quotation';
        body ='';
        body += 'Dear Sir/Madam, <br/><br/>';
        body += 'Please find attached Quotation.<br/><br/><br/><br/>';
         
         qItem = new List<QuoteLineItem>();
         qItem = [SELECT Id,CreatedById,CreatedDate,CurrencyIsoCode,Description,Discount,IsDeleted,LastModifiedById,LastModifiedDate,ServiceDate,Estimated_Commission_Per_Kgs__c,
                  Estimated_Freight_Per_Kgs__c,Estimated_Inspection_Fee_Per_Kgs__c,Estimated_Ocean_Freight_Per_Kgs__c,GST__c,HSN_SAC_Code__c,Insurance_Charges__c,LC_Confirmation_Charges_Per_Kgs__c,
                  Line_Amount__c,LineNumber,ListPrice,Plant_Code__c,Product2Id,Product2.name,Quantity,QuoteId,UnitPrice,SortOrder,Specification__c,Subtotal,TotalPrice,Type_of_Packing__c,Unit__c                       
                  FROM QuoteLineItem where QuoteId =:quData.Id]; 
         system.debug('qItem'+qItem);
         system.debug('Size'+qItem.size());
          if(qItem.size() > 0){
            for(QuoteLineItem qli : qItem) {
                QuoteLineItemWrapper Ql = new QuoteLineItemWrapper();
                Ql.Line_Item_Id = qli.Id;
                Ql.Name = qli.LineNumber;
                Ql.Goodsservices = qli.Product2.name; 
                Ql.CurrencyIsoCode = qli.CurrencyIsoCode; 
                Ql.ListPrice = string.valueof(qli.ListPrice);
                Ql.UnitPrice = Integer.valueof(qli.UnitPrice); 
                
              //  Ql.Goodsservices = qli.Product2.name;
              //  Ql.BPCat =qli.Business_Partner_Catalogue_Number__r.name;
                
             //   Ql.BPCat = (qli.Business_Partner_Catalogue_Number__r.name != null && qli.Business_Partner_Catalogue_Number__r.name != '') 
                //    ? qli.Business_Partner_Catalogue_Number__r.name 
                 //   : qli.Product2.name;
                
                /*    quoteRecord.PortofDischarge = quData.Port_of_Discharge__c;
                if(quoteRecord.PortofDischarge == 'Other'){
                    quoteRecord.PortofDischarge = quData.Port_of_Discharge_Others__c;
                }
              */  
                
                Ql.Quantity = qli.Quantity;
              //	Ql.HsnCodeMaster = qli.Product2.HSN_Code__r.Name;
                Ql.Rate = qli.UnitPrice;
               // IGSTrate = qli.IGST_Rate__c;
               // PSS = qli.OpportunityLineItem.PSS__c;
               // PotentialQtyPerYear = qli.OpportunityLineItem.Potential_Quantity_in_KGS_Per_Year__c;
                Ql.Totalvalue=qli.TotalPrice;
               // Ql.Totalvalue= qli.Total_Amount__c;
               system.debug('qliData'+totalQuantity);
                totalQuantity += qli.Quantity;
                
                
                if(Ql.Totalvalue != null){
                    system.debug('Totalvalue'+Ql.Totalvalue);
                    totalValueINR += Ql.Totalvalue;
                    system.debug('totalValueINR'+totalValueINR);
                    
                }
                
              /*  Integer totalValueINRInt = totalValueINR.intValue(); // Convert to Integer if needed
                String totalValueINRWords = convertCurrencytowords.convert(totalValueINRInt);
                
                if (qli.Quote.CurrencyIsoCode == 'INR') {
                    no2words = totalValueINRWords + ' Rupees Only.';
                } else {
                    no2words = 'USD ' + totalValueINRWords+' Only.';
                }
                */
               // system.debug(Ql.Goodsservices);
                quoteRecord.lineItems.add(Ql);
                system.debug('quoteRecord.lineItems'+ quoteRecord.lineItems);
            }
            
             if(totalValueINR != null ){
                if(CGSTrate != null){
                    CGSTValue = (totalValueINR * CGSTrate) / 100;
                }
                if(SGSTrate != null){ 
                    SGSTValue = (totalValueINR * SGSTrate) / 100;  
                }
                if(CGSTValue != null && SGSTValue != null){
                    TotalGst = CGSTValue + SGSTValue;
                }
                
            }
            
            /*
            if(IGSTrate != null){ 
                IGSTValue = (totalValueINR * IGSTrate) / 100;
                TotalGst = IGSTValue;
            }
            */
            
        } else{
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Error, 'Before making a Quote Pdf please add atleast One Product'));
            isValid = false;
        }	
     }
    
    
     public PageReference save() {
        
        // Check if Salestype is null
        //if (String.isBlank(Salestype)) {
            // Add an error message to the page
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: Sales type must be selected.'));
            //return null; // Prevent further processing and stay on the same page
        //}
        
        
        String finalString = '%' + quData.Name + '%';
        List<ContentDocument > contentDocs = [select Id, title from ContentDocument where title like: finalString order by createdDate desc limit 1];
        String version = '0';
        if(contentDocs.size() > 0)
            version = contentDocs[0].title.substringAfterLast('_').subStringBeforelast('.');
        if(!createNew) {
            if(contentDocs.size() > 0)
                Database.delete(contentDocs, false);
        }
        formSubmitted = true;
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.ContentLocation = 'S';
        Integer newVersion = Integer.valueOf(version) + 1;
        contentVersion.PathOnClient = String.valueOf(quData.Name+ '_' + newVersion + '.pdf');
        contentVersion.Title = String.valueOf(quData.Name + '_' + newVersion + '.pdf');
        contentVersion.isMajorVersion = false;
        if(Test.isRunningTest())
            ContentVersion.versionData = Blob.toPdf('test');
        else
            ContentVersion.versionData = pdf.getContentAsPDF();
        upsert contentVersion;
        
        contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: contentVersion.Id];
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = contentVersion.ContentDocumentId;
        contentDocumentLink.LinkedEntityId = quData.Id;
        contentDocumentLink.ShareType = 'V';
        upsert contentDocumentLink;
        
        Pagereference pageRef = new PageReference('/'+qId);
        pageRef.setRedirect(true);
        return pageRef;    
    }
    
    public PageReference saveAndSend() {
        
        //if (String.isBlank(Salestype)) {
            // Add an error message to the page
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: Sales type must be selected.'));
            //return null; // Prevent further processing and stay on the same page
        //}
        
        
        if(emailId != '' && subject != '') {
            String finalString = '%' + quData.Name + '%';
            List<ContentDocument> contentDocs = [select Id, title from ContentDocument where title like: finalString order by createdDate desc limit 1];
            String version = '0';
            if(contentDocs.size() > 0)
                version = contentDocs[0].title.substringAfterLast('_').subStringBeforelast('.');
            if(!createNew) {
                if(contentDocs.size() > 0)
                    Database.delete(contentDocs, false);
            }
            
            List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
            if(qId !=null)
                cdls = [select id, ContentDocument.LatestPublishedVersionId from ContentDocumentLink where LinkedEntityId =: qId];
            Set<String> LatestPublishedVersionIds = new Set<String>();
          /*  for(ContentDocumentLink cdl: cdls) {
                LatestPublishedVersionIds.add(cdl.ContentDocument.LatestPublishedVersionId);
            }*/
            formSubmitted = true;
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.ContentLocation = 'S';
            Integer newVersion = Integer.valueOf(version) + 1;
            contentVersion.PathOnClient = String.valueOf(quData.Name+ '_' + newVersion + '.pdf');
            contentVersion.Title = String.valueOf(+ quData.Name + '_' + newVersion + '.pdf');
            contentVersion.isMajorVersion = false;
            if(Test.isRunningTest())
                ContentVersion.versionData = Blob.toPdf('test');
            else
                ContentVersion.versionData = pdf.getContentAsPDF();
            upsert contentVersion;
            
            contentVersion = [SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersionId, Title, versionData
                              FROM ContentVersion WHERE Id =: contentVersion.Id];
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = contentVersion.ContentDocumentId;
            contentDocumentLink.LinkedEntityId = qId;
            contentDocumentLink.ShareType = 'V';
            upsert contentDocumentLink;
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            System.debug(emailId);
            email.setToAddresses(new String[] {emailId});
            if(String.isNotBlank(CC_Addresses)){
                CC_Addresses = CC_Addresses.replaceAll('[;,:]', ',');
                Set<String> CCEmails = new Set<String>();
                for(String str : CC_Addresses.split(',')) {
                    if(String.isNotBlank(str))
                        CCEmails.add(str);
                }
                
                email.setCcAddresses(new List<String>(CCEmails));
                System.debug(CC_Addresses);
            }
            
            LatestPublishedVersionIds.add(contentVersion.ContentDocument.LatestPublishedVersionId);
            
            if(LatestPublishedVersionIds.size() > 0) {
                List<String> LatestPublishedVersionIdList = new List<String>();
                LatestPublishedVersionIdList.addAll(LatestPublishedVersionIds);
                email.setEntityAttachments(LatestPublishedVersionIdList);
            }
            
            email.setReplyTo(quData.Opportunity.Owner.Email);
            if(String.isNotBlank(quData.Opportunity.Owner.Email)) {
                email.setBccAddresses(new List<String> {quData.Opportunity.Owner.Email});
            }
            email.setSubject(subject);
            email.setHtmlBody(body);
            
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            sendEmailSuccess = true;
            sendEmailError = false;
            
            
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Email Id and subject are the mandatory fields, please verify'));
            return null;
        }
        
        Pagereference pageRef = new PageReference('/'+qId);
        pageRef.setRedirect(true);
        return pageRef;
        
    }
    
   public  class QuotedataWrapper {
        
        public string PINo {get;set;}
        public string HsnCodeMaster {get;set;}
        public string Product2Id {get;set;} 
        public string Goodsservices {get;set;}   
        public string ListPrice {get;set;}   
        public string CurrencyIsoCode {get;set;}
        public string CountryofOrigin {get;set;}
        public string CountryofFinalDestination {get;set;}
        public string PortofLoading {get;set;} 
        public string PortofDischarge {get;set;}
        public string FinalDestination {get;set;}
       //public string Quotecreateddate{get;set;}
        public Date Quotecreateddate {get;set;} 
        public string IECNO {get;set;}
        public string CustomsReg {get;set;}
        public string CINNo {get;set;}
        public string ADCode {get;set;}
        public string PAN {get;set;}
        public string GSTIN {get;set;}
        public string BillingName {get;set;}
        public string Baddress {get;set;}
        public List<QuoteLineItemWrapper> lineItems {get; set;}
        public string AcntNo {get;set;}
        public string BankName {get;set;}
        public string Bankbranch {get;set;}
        public string SwiftCode {get;set;}
        public string CSwiftCode {get;set;}
        
        public QuotedataWrapper() {
            lineItems = new List<QuoteLineItemWrapper>();
        }
    }
    
    class QuoteLineItemWrapper {
        public string Name {get;set;}
        public string Line_Item_Id {get;set;}
        public string Part_No_c {get;set;}
        public string ListPrice {get;set;}
        public string Goodsservices{get;set;}
        public string BPCat{get;set;}
        public string Product_Description {get;set;}
        public string HSNCODE{get;set;}
        public string HsnCodeMaster{get;set;}
        public string Product2Id {get;set;} 
        public string HSN_Master_c{get;set;}
        public Decimal Quantity{get;set;}
        public Decimal Rate{get;set;}
        public Decimal Totalvalue{get;set;}
        // public Decimal Totalvalue{get;set;}
        public integer UnitPrice {get;set;}
        public integer Grand_Total_c {get;set;}
        //  public Integer Quantity {get;set;}
        public string UnitPriceValue {get;set;}
        public string Grand_TotalValue {get;set;}
        public string CurrencyIsoCode {get;set;}
        public decimal CGST {get;set;}
        public decimal SGST {get;set;}
        public decimal IGST {get;set;}
        public decimal CGSTRate {get;set;}
        public decimal SGSTRate {get;set;}
        public decimal IGSTRate {get;set;}
        public decimal TotalGst {get;set;}
        public decimal CGSTAMT {get;set;}
        public decimal SGSTAMT {get;set;}
        public decimal IGSTAMT {get;set;}
        public string Display_Description {get;set;}
        public string IECNO{get;set;}
        public string CustomsReg {get;set;}
        public string CINNo {get;set;}
		public string PAN {get;set;}
        public string GSTIN {get;set;}
      
    }
    
    public PageReference cancel() {
        Pagereference pageRef = new PageReference('/'+qId);
        pageRef.setRedirect(true);
        formSubmitted = false;
        return pageRef;
        
    }
    
}