@isTest
public class customAddProduct_Quote_class_Test {

    @isTest
    static void testFindProduct() {
        // Get Standard Pricebook ID
        Id standardPricebookId = Test.getStandardPricebookId();
        
        // Create Product2
        Product2 prod = new Product2();
        prod.Name = 'Product A';
        prod.IsActive = true;
        insert prod;

        // Create Standard PricebookEntry (Required)
        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPricebookId, 
            Product2Id = prod.Id, 
            UnitPrice = 100, 
            IsActive = true
        );
        insert standardPBE;

        // Create a Custom Pricebook for testing
        Pricebook2 customPricebook = new Pricebook2(Name = 'Test Pricebook', IsActive = true);
        insert customPricebook;

        // Create Custom PricebookEntry for the Product (matching custom Pricebook)
        PricebookEntry customPBE = new PricebookEntry(
            Pricebook2Id = customPricebook.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100, 
            IsActive = true
        );
        insert customPBE;

        // Create an Account for Opportunity
        Account acc = new Account(Name = 'Finesse');
        insert acc;

        // Create Opportunity with the **custom Pricebook**
        Opportunity opp = new Opportunity(
            Name = 'Finesse',
            StageName = 'Sampling',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            Pricebook2Id = customPricebook.Id  // Use Custom Pricebook
        );
        insert opp;

        // Create Quote linked to Opportunity with the **same Pricebook**
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = customPricebook.Id, // Use Custom Pricebook
            Status = 'Draft'
        );
        insert quote;

        // Create QuoteLineItem with **the correct PricebookEntryId**
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100, 
            Quantity = 2, 
            PricebookEntryId = customPBE.Id  // Use Custom PricebookEntry
        );
        insert qli;

        // List of product families for testing
        List<String> productFamily = new List<String>{'Test Family'};

        // Call the method to be tested
        Test.startTest();
        try {
            String result = customAddProduct_Quote_class.findProduct(quote.Id, productFamily);
            System.debug('Result: ' + result);
        } catch (Exception e) {
            System.debug('Error Message: ' + e.getMessage());  // Logs the error message
            throw e;
        }
        Test.stopTest();

    }



    @isTest
    static void testGetProductFamily() {
        // Call the method
        Test.startTest();
        List<customAddProduct_Quote_class.PicklistValue> result = customAddProduct_Quote_class.getproductfamily();
        Test.stopTest();

        // Verify the result
        System.assertNotEquals(0, result.size(), 'The result should contain picklist values');
    }

    @isTest
    static void testSaveProducts() {
        // Create test data
          Id PID = Test.getStandardPricebookId();
        Product2 prod = new Product2();
        prod.name='Product A';
        prod.isActive=true;
        insert prod;
      
        
        Pricebook2 pricebook = new Pricebook2(Name = 'Test Pricebook', IsActive = true);
        insert pricebook;
        /* PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = PID, 
            Product2Id = prod.Id,
            UnitPrice = 1000,
            IsActive = true);
        insert standardPrice; */
               
        Account acc = new Account();
        acc.Name = 'Finesse';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Finesse';
        opp.StageName = 'Sampling';
        opp.CloseDate = Date.today();
        opp.AccountId = acc.Id;
     //   opp.Contact__c = con.Id;
        opp.Pricebook2Id=PID;
        insert opp;
        
         PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = PID, 
            Product2Id = prod.Id, 
            UnitPrice = 100, 
            IsActive = true
        );
        insert testPricebookEntry;
        
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = PID,
            Status = 'Draft'
        );
        insert quote;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100, 
            Quantity = 2, 
            PricebookEntryId = testPricebookEntry.Id
        );
        insert qli;

        // Create a list of ProductWrapper to simulate the request body
        List<customAddProduct_Quote_class.ProductWrapper> productWrappers = new List<customAddProduct_Quote_class.ProductWrapper>();
        customAddProduct_Quote_class.ProductWrapper pw = new customAddProduct_Quote_class.ProductWrapper();
        pw.Product2Id = prod.Id;
        pw.Price = 100;
        pw.SalesPrice = 90;
        pw.Quantity = 1;
        pw.Discount = 10;
        pw.LineDescription = 'Test Description';
        pw.Id = '01u5j000003Pq51AAC';
        productWrappers.add(pw);

        String recordData = JSON.serialize(productWrappers);

        // Call the method
        Test.startTest();
        String result = customAddProduct_Quote_class.saveProducts(recordData, quote.Id);
        Test.stopTest();

        // Verify the QuoteLineItem insertion
        List<QuoteLineItem> qliList = [SELECT Id, Quantity, UnitPrice, QuoteId, Product2Id FROM QuoteLineItem WHERE QuoteId = :quote.Id];
    }
}