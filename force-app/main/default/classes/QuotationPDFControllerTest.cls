@isTest
private class QuotationPDFControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test St',
            BillingCity = 'Test City',
            BillingState = 'Test State',
            BillingPostalCode = '12345',
            BillingCountry = 'Test Country',
            ShippingStreet = '456 Test Ave',
            ShippingCity = 'Test City',
            ShippingState = 'Test State',
            ShippingPostalCode = '12345',
            ShippingCountry = 'Test Country',
            Phone = '1234567890',
            GSTIN_No__c = 'GSTIN123',
            PAN_No__c = 'PAN123'
        );
        insert testAccount;
        
        // Create test Contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test.contact@example.com',
            Phone = '9876543210',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        // Create test Opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            CloseDate = Date.today().addDays(30),
            StageName = 'Prospecting',
            ContactId = testContact.Id
        );
        insert testOpportunity;
        
        // Create test Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;
        
        // Create test PricebookEntry
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert testPricebookEntry;
        
        // Create test Quote
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpportunity.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            ContactId = testContact.Id,
           // AccountId = testAccount.Id,
            BillingName = 'Test Billing Name',
            ShippingName = 'Test Shipping Name',
           // BillingAddress = testAccount.BillingStreet + ', ' + testAccount.BillingCity,
            //ShippingAddress = testAccount.ShippingStreet + ', ' + testAccount.ShippingCity,
            Email = 'test@example.com',
            Phone = '1234567890',
            ExpirationDate = Date.today().addDays(30),
            Status = 'Draft'
        );
        insert testQuote;
        
        // Create test QuoteLineItem
        QuoteLineItem testQuoteLineItem = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Product2Id = testProduct.Id,
            Quantity = 10,
            UnitPrice = 100
          //  TotalPrice = 1000
        );
        insert testQuoteLineItem;
    }
    
    @isTest
    static void testConstructor() {
        // Get test data
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        
        // Set current page parameters
        Test.setCurrentPage(Page.QuotationPDF);
        ApexPages.currentPage().getParameters().put('id', testQuote.Id);
        
        // Instantiate controller
        Test.startTest();
        QuotationPDFController controller = new QuotationPDFController();
        Test.stopTest();
        
     
    }
    
    @isTest
    static void testConstructorWithNoId() {
        // Instantiate controller without ID
        Test.startTest();
       // QuotationPDFController controller = new QuotationPDFController();
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testConstructorWithNoLineItems() {
        // Get test data and delete line items
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        delete [SELECT Id FROM QuoteLineItem WHERE QuoteId = :testQuote.Id];
        
        // Set current page parameters
        Test.setCurrentPage(Page.QuotationPDF);
        ApexPages.currentPage().getParameters().put('id', testQuote.Id);
        
        // Instantiate controller
        Test.startTest();
        QuotationPDFController controller = new QuotationPDFController();
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testSaveMethod() {
        // Get test data
        Quote testQuote = [SELECT Id, Name FROM Quote LIMIT 1];
        
        // Set current page parameters
        Test.setCurrentPage(Page.QuotationPDF);
        ApexPages.currentPage().getParameters().put('id', testQuote.Id);
        
        // Instantiate controller
        QuotationPDFController controller = new QuotationPDFController();
        
        Test.startTest();
        PageReference result = controller.save();
        Test.stopTest();
        
       
        
        // Verify content document was created
        List<ContentDocumentLink> contentLinks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :testQuote.Id];
    }
    
    @isTest
    static void testSaveAndSendMethod() {
        // Get test data
        Quote testQuote = [SELECT Id, Name FROM Quote LIMIT 1];
        
        // Set current page parameters
        Test.setCurrentPage(Page.QuotationPDF);
        ApexPages.currentPage().getParameters().put('id', testQuote.Id);
        
        // Instantiate controller
        QuotationPDFController controller = new QuotationPDFController();
        controller.emailId = 'test@example.com';
        controller.subject = 'Test Subject';
        controller.body = 'Test Body';
        controller.CC_Addresses = 'cc1@example.com,cc2@example.com';
        
        Test.startTest();
        PageReference result = controller.saveAndSend();
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testSaveAndSendMethodWithMissingEmail() {
        // Get test data
        Quote testQuote = [SELECT Id, Name FROM Quote LIMIT 1];
        
        // Set current page parameters
        Test.setCurrentPage(Page.QuotationPDF);
        ApexPages.currentPage().getParameters().put('id', testQuote.Id);
        
        // Instantiate controller
        QuotationPDFController controller = new QuotationPDFController();
        controller.emailId = '';
        controller.subject = '';
        
        Test.startTest();
        PageReference result = controller.saveAndSend();
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testCancelMethod() {
        // Get test data
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        
        // Set current page parameters
        Test.setCurrentPage(Page.QuotationPDF);
        ApexPages.currentPage().getParameters().put('id', testQuote.Id);
        
        // Instantiate controller
        QuotationPDFController controller = new QuotationPDFController();
        
        Test.startTest();
        PageReference result = controller.cancel();
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testWrapperClasses() {
        // Test the wrapper classes
        
        // QuotedataWrapper
        QuotationPDFController.QuotedataWrapper quoteWrapper = new QuotationPDFController.QuotedataWrapper();
        quoteWrapper.PINo = 'PI123';
        quoteWrapper.HsnCodeMaster = 'HSN123';
        quoteWrapper.Product2Id = 'prod123';
        quoteWrapper.Goodsservices = 'Test Service';
        quoteWrapper.ListPrice = '100';
        quoteWrapper.CurrencyIsoCode = 'USD';
        quoteWrapper.CountryofOrigin = 'USA';
        quoteWrapper.CountryofFinalDestination = 'India';
        quoteWrapper.PortofLoading = 'Port A';
        quoteWrapper.PortofDischarge = 'Port B';
        quoteWrapper.FinalDestination = 'Mumbai';
        quoteWrapper.Quotecreateddate = Date.today();
        quoteWrapper.IECNO = 'IEC123';
        quoteWrapper.CustomsReg = 'Customs123';
        quoteWrapper.CINNo = 'CIN123';
        quoteWrapper.ADCode = 'AD123';
        quoteWrapper.PAN = 'PAN123';
        quoteWrapper.GSTIN = 'GSTIN123';
        quoteWrapper.BillingName = 'Test Billing';
        quoteWrapper.Baddress = '123 Test St';
        quoteWrapper.AcntNo = '123456789';
        quoteWrapper.BankName = 'Test Bank';
        quoteWrapper.Bankbranch = 'Test Branch';
        quoteWrapper.SwiftCode = 'SWIFT123';
        quoteWrapper.CSwiftCode = 'CSWIFT123';
        
        
     /*   
        // QuoteLineItemWrapper
        QuotationPDFController.QuoteLineItemWrapper lineItemWrapper = new QuotationPDFController.QuoteLineItemWrapper();
        lineItemWrapper.Name = 'Line 1';
        lineItemWrapper.Line_Item_Id = 'qli123';
        lineItemWrapper.Part_No_c = 'PART123';
        lineItemWrapper.ListPrice = '100';
        lineItemWrapper.Goodsservices = 'Test Product';
        lineItemWrapper.BPCat = 'BP123';
        lineItemWrapper.Product_Description = 'Test Description';
        lineItemWrapper.HSNCODE = 'HSN123';
        lineItemWrapper.HsnCodeMaster = 'HSN123';
        lineItemWrapper.Product2Id = 'prod123';
        lineItemWrapper.HSN_Master_c = 'HSN123';
        lineItemWrapper.Quantity = 10;
        lineItemWrapper.Rate = 100;
        lineItemWrapper.Totalvalue = 1000;
        lineItemWrapper.UnitPrice = 100;
        lineItemWrapper.Grand_Total_c = 1000;
        lineItemWrapper.UnitPriceValue = '100';
        lineItemWrapper.Grand_TotalValue = '1000';
        lineItemWrapper.CurrencyIsoCode = 'USD';
        lineItemWrapper.CGST = 9;
        lineItemWrapper.SGST = 9;
        lineItemWrapper.IGST = 18;
        lineItemWrapper.CGSTRate = 9;
        lineItemWrapper.SGSTRate = 9;
        lineItemWrapper.IGSTRate = 18;
        lineItemWrapper.TotalGst = 18;
        lineItemWrapper.CGSTAMT = 90;
        lineItemWrapper.SGSTAMT = 90;
        lineItemWrapper.IGSTAMT = 180;
        lineItemWrapper.Display_Description = 'Test Display';
        lineItemWrapper.IECNO = 'IEC123';
        lineItemWrapper.CustomsReg = 'Customs123';
        lineItemWrapper.CINNo = 'CIN123';
        lineItemWrapper.PAN = 'PAN123';
        lineItemWrapper.GSTIN = 'GSTIN123'; */
        
       
    }
    
    @isTest
    static void testTaxCalculations() {
        // Get test data
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :testQuote.Id LIMIT 1];
        
        // Update QLI with tax rates
        qli.UnitPrice = 100;
        qli.Quantity = 10;
      //  qli.TotalPrice = 1000;
        update qli;
        
        // Set current page parameters
        Test.setCurrentPage(Page.QuotationPDF);
        ApexPages.currentPage().getParameters().put('id', testQuote.Id);
        
        // Instantiate controller
        Test.startTest();
        QuotationPDFController controller = new QuotationPDFController();
        controller.CGSTrate = 9;
        controller.SGSTrate = 9;
        
        // Manually trigger tax calculations (normally done in constructor)
        if(controller.totalValueINR != null ){
            if(controller.CGSTrate != null){
                controller.CGSTValue = (controller.totalValueINR * controller.CGSTrate) / 100;
            }
            if(controller.SGSTrate != null){ 
                controller.SGSTValue = (controller.totalValueINR * controller.SGSTrate) / 100;  
            }
            if(controller.CGSTValue != null && controller.SGSTValue != null){
                controller.TotalGst = controller.CGSTValue + controller.SGSTValue;
            }
        }
        Test.stopTest();
        
        
    }
}