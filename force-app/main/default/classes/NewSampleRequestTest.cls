@isTest
public class NewSampleRequestTest {
    
    static testMethod void testGetExistingProductsFromLead() {
       // Step 1: Create Test Data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create Country
        Country__c country = new Country__c(Name='TestCountry');
        insert country;
        
        // Create State with proper Country reference
        State__c state = new State__c(Name='TestState', Country__c=country.Id, Zone__c='East');
        insert state;
        
         // Create City (no postal code since it's removed)
        City__c city = new City__c(Name='TestCity',State__c=state.Id);
        insert city;
        
        // Create Postal Code with proper State reference
        Postal_Code__c postal = new Postal_Code__c(Name='123456', State__c=state.Id,City__c=city.Id);
        insert postal;
        // Create a Lead record
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Street = '123 Test St',
            City__c = city.Id,          
            State__c = state.Id,       
            Country__c = country.Id,    
            Postal_Code__c = postal.Id, 
            Status = 'Open - Not Contacted',
            Lead_Type__c = 'Domestic', 
            Zone__c = 'East'
        );
        insert testLead;


        // Create the Product with Family 'FG.OP'
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP01', 
            Family = 'FG.OP' 
        );
        insert prod;

         Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        PricebookEntry pbe = new PricebookEntry(Product2Id=prod.Id, Pricebook2Id=standardPricebook.Id, UnitPrice=100, IsActive=true);
        insert pbe;

        Product_Interested__c pi = new Product_Interested__c(
            Lead__c = testLead.Id,
            Product__c = prod.Id,             
            New_Product__c = true,
            New_Product_Name__c = 'Custom Chem',
            Pricebook_Entry_Id__c = pbe.Id,
            List_Price__c = 100,
            Product_Family__c = 'FG.OP',
            Volume_in_Kgs__c = 5
        );
        insert pi;

        Test.startTest();
       // String result = NewSampleRequest.getExistingProducts(testLead.Id);
      //  System.debug('Lead Result: ' + result);
        Test.stopTest();
    }

    static testMethod void testGetExistingProductsFromAccount() {
        Product_Group__c pg = new Product_Group__c(Name='Test Group', Approver__c=UserInfo.getUserId());
        insert pg;

        Account acc = new Account(Name='Test Account', CurrencyIsoCode='USD', Product_Group__c=pg.Id);
        insert acc;

        Product2 prod = new Product2(Name='Test Product A', ProductCode='TPA', Family='Oils');
        insert prod;

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        
        PricebookEntry pbe = new PricebookEntry(Product2Id=prod.Id, Pricebook2Id=standardPricebook.Id, UnitPrice=120, IsActive=true);
        insert pbe;

        Product_Interested__c pi = new Product_Interested__c(
            Account__c = acc.Id,
          //  Product__c = prod.Id,
           // Product_Code__c = 'TPA',
            New_Product__c = false,
            New_Product_Name__c = '',
            Pricebook_Entry_Id__c = pbe.Id,
            List_Price__c = 120,
            Product_Family__c = 'FG.OP',
            Volume_in_Kgs__c = 10
        );
        insert pi;

        Test.startTest();
        String result = NewSampleRequest.getExistingProducts(acc.Id);
        System.debug('Account Result: ' + result);
        Test.stopTest();
    }

    static testMethod void testGetExistingProductsFromOpportunity() {
        Product_Group__c pg = new Product_Group__c(Name='Opp Group', Approver__c=UserInfo.getUserId());
        insert pg;

        Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=System.today(), Product_Group__c=pg.Id, CurrencyIsoCode='INR');
        insert opp;

        Product2 prod = new Product2(Name='Opp Product', ProductCode='OP01', Family='Metals');
        insert prod;

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        PricebookEntry pbe = new PricebookEntry(Product2Id=prod.Id, Pricebook2Id=standardPricebook.Id, UnitPrice=200, IsActive=true);
        insert pbe;

        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opp.Id, Quantity=2, UnitPrice=200, PricebookEntryId=pbe.Id);
        insert oli;

        Test.startTest();
        String result = NewSampleRequest.getExistingProducts(opp.Id);
        System.debug('Opportunity Result: ' + result);
        Test.stopTest();
    }

    static testMethod void testGetExistingProductsFromQuote() {
        // Step 1: Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Step 2: Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;
        
        // Step 3: Get Standard Pricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        // Step 4: Activate it if necessary
        standardPricebook.IsActive = true;
        update standardPricebook;
        
        // Step 5: Create Product
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;
        
        // Step 6: Create PricebookEntry for that product and standard pricebook
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = standardPricebook.Id,
            UnitPrice = 150,
            IsActive = true
        );
        insert pbe;
        
        // Step 7: Create Quote linked to Opportunity and same Pricebook
        Quote qt = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = standardPricebook.Id,
            BillingName = 'Test Billing',
            ExpirationDate = Date.today().addDays(15)
        );
        insert qt;
        
        // Step 8: Now insert the QuoteLineItem using the same PricebookEntry
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = qt.Id,
            Quantity = 1, 
            UnitPrice = 150, 
            PricebookEntryId = pbe.Id
        );
        insert qli;


        Test.startTest();
        String result = NewSampleRequest.getExistingProducts(qt.Id);
        System.debug('Quote Result: ' + result);
        Test.stopTest();
    }
    
    
    
    
   @isTest
    static void testGetPicklistValues() {
        // Call the method
        Test.startTest();
        List<Map<String, String>> picklistValues = NewSampleRequest.getPicklistValues();
        Test.stopTest();

       
    }

    @isTest
    static void testGetProductsWithFamily() {
        // Create sample products
        Product2 p1 = new Product2(Name = 'Prod A', Family = 'TestFamily', ProductCode = 'A001', IsActive = true);
        Product2 p2 = new Product2(Name = 'Prod B', Family = 'OtherFamily', ProductCode = 'B002', IsActive = true);
        insert new List<Product2>{ p1, p2 };

        // Call the method with a valid family
        Test.startTest();
        List<Product2> result = NewSampleRequest.getProducts('TestFamily', new List<Id>{});
        Test.stopTest();

       
    }

    @isTest
    static void testGetProductsWithExcludedIds() {
        // Create product
        Product2 p1 = new Product2(Name = 'Prod X', Family = 'TestFamily', ProductCode = 'X001', IsActive = true);
        insert p1;

        // Call method excluding the product's ID
        Test.startTest();
        List<Product2> result = NewSampleRequest.getProducts('TestFamily', new List<Id>{ p1.Id });
        Test.stopTest();

       
    }

    @isTest
    static void testGetProductsWithoutFamily() {
        // Create a product
        Product2 p1 = new Product2(Name = 'Prod C', Family = 'SomeFamily', ProductCode = 'C003', IsActive = true);
        insert p1;

        // Call the method with blank family
        Test.startTest();
        List<Product2> result = NewSampleRequest.getProducts('', new List<Id>());
        Test.stopTest();

      
    }
    
    
    
    
    
     @isTest
    static void testSaveProductInterested() {
         // Step 1: Create Test Data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create Country
        Country__c country = new Country__c(Name='TestCountry');
        insert country;
        
        // Create State with proper Country reference
        State__c state = new State__c(Name='TestState', Country__c=country.Id, Zone__c='East');
        insert state;
        
         // Create City (no postal code since it's removed)
        City__c city = new City__c(Name='TestCity',State__c = state.Id   );
        insert city;
        
        // Create Postal Code with proper State reference
        Postal_Code__c postal = new Postal_Code__c(Name='123456', State__c=state.Id,City__c=city.Id);
        insert postal;
        // Create a Lead record
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Street = '123 Test St',
            City__c = city.Id,          
            State__c = state.Id,       
            Country__c = country.Id,    
            Postal_Code__c = postal.Id, 
            Status = 'Open - Not Contacted',
            Lead_Type__c = 'Domestic', 
            Zone__c = 'East'
        );
        insert testLead;

        // Create a Product
        Product2 prod = new Product2(Name = 'Test Product', Family = 'Test Family', isActive = true);
        insert prod;

        // Create a Pricebook and PricebookEntry
         Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = standardPricebook.Id,
            UnitPrice = 100.0,
            IsActive = true
        );
        insert pbe;
        
        
        Product_Interested__c pi = new Product_Interested__c(
            Lead__c = testLead.Id,
          //  Product__c = prod.Id,
           // Product_Code__c = 'TPA',
            New_Product__c = false,
            New_Product_Name__c = '',
            Pricebook_Entry_Id__c = pbe.Id,
            List_Price__c = 120,
            Product_Family__c = 'FG.OP',
            Volume_in_Kgs__c = 10
        );
        insert pi;


        // Create Sample JSON string for Sample_Booking__c
        Map<String, Object> sampleMap = new Map<String, Object>{
            'Sample_Request_Type' => 'Request A',
            'New_Customer' => 'Yes',
            'Existing_Customer' => 'No',
            'Sample_Requested_Date' => String.valueOf(Date.today()),
            'Mode_of_Transport' => 'Air',
            'Expected_By' => String.valueOf(Date.today().addDays(5)),
            'Use_Lead_Address_for_Sample_Dispatch_To' => true
        };
        String sampleJson = JSON.serialize(sampleMap);

        // Create Sample JSON list for Sample_Line_Item__c
        List<Object> lineItems = new List<Object>();
        Map<String, Object> item = new Map<String, Object>{
            'prodId' => prod.Id,
            'volume' => '5',
            'family' => 'Test Family',
            'remark' => 'Test Remark',
            'pbeId' => pbe.Id,
            'unitPrice' => 100.0,
            'address' => '123 Test Street',
            'New_Product_Name' => 'Custom Name',
            'New_Product' => true
        };
        lineItems.add(item);
        String jsJson = JSON.serialize(lineItems);

        // Call the method
        NewSampleRequest.getExistingProducts(testLead.Id);
        Test.startTest();
        Map<String, String> result = NewSampleRequest.saveProductInterested(testLead.Id, sampleJson, jsJson, UserInfo.getUserId());
        Test.stopTest();        
    }
    
    
    
    @isTest
    static void testWrapperInstantiation() {
        // Create wrapper instance and populate fields
        NewSampleRequest.wrapper w = new NewSampleRequest.wrapper();
        w.Name = 'Test Name';
        w.Approver = 'John Doe';
        w.Adrress = '123 Sample Street';
        w.Sample_Request_Type = 'Demo';
        w.New_Customer = 'Yes';
        w.CurrencyISOCode = 'USD';
        w.Sample_Requested_Date = '2025-05-01';
        w.Mode_of_Transport = 'Air';
        w.Expected_By = '2025-05-15';
        w.Use_Lead_Address_for_Sample_Dispatch_To = 'No';
        w.Id = '001XXXXXXXXXXXX';

        // Create wrapperLine instance and populate fields
        NewSampleRequest.wrapperLine wl = new NewSampleRequest.wrapperLine();
        wl.family = 'Medical';
        wl.prodId = '01tXXXXXXXXXXXX';
        wl.prodName = 'Product A';
        wl.prodCode = 'PROD001';
        wl.volume = 10.5;
        wl.pbeId = 'PBE001';
        wl.New_Product = true;
        wl.New_Product_Name = 'New Product A';
        wl.unitPrice = 100.00;
        wl.remark = 'Urgent';
        wl.address = 'Dispatch Address';

        
    }
    
}