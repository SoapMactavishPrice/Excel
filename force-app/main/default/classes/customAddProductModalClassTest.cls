@isTest
public class customAddProductModalClassTest {
    
    @isTest
    static void testFindProducts() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        // Create a custom Pricebook
        Pricebook2 customPB = new Pricebook2(Name = 'Test Pricebook', IsActive = true);
        insert customPB;
        
        // Create Products
        Product2 prod1 = new Product2(Name = 'Test Product 1', ProductCode = 'TP001', Family = 'TestFamily', IsActive = true, CurrencyIsoCode = 'USD');
        Product2 prod2 = new Product2(Name = 'Test Product 2', ProductCode = 'TP002', Family = 'TestFamily', IsActive = true, CurrencyIsoCode = 'USD');
        insert new List<Product2>{prod1, prod2};
            
            // Insert Standard PricebookEntries
            PricebookEntry stdPbe1 = new PricebookEntry(
                Pricebook2Id = standardPricebook.Id,
                Product2Id = prod1.Id,
                UnitPrice = 100,
                IsActive = true,
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD'
            );
        PricebookEntry stdPbe2 = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod2.Id,
            UnitPrice = 200,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD'
        );
        insert new List<PricebookEntry>{ stdPbe1, stdPbe2 };
            
            // Now insert custom PricebookEntries
            PricebookEntry pbe1 = new PricebookEntry(
                Pricebook2Id = customPB.Id,
                Product2Id = prod1.Id,
                UnitPrice = 100,
                IsActive = true,
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD'
            );
        PricebookEntry pbe2 = new PricebookEntry(
            Pricebook2Id = customPB.Id,
            Product2Id = prod2.Id,
            UnitPrice = 200,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD'
        );
        insert new List<PricebookEntry>{ pbe1, pbe2 };
            
            // Create Opportunity using custom Pricebook
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(10),
                Pricebook2Id = customPB.Id,
                CurrencyIsoCode = 'USD'
            );
        insert opp;
        
        // Add Opportunity Line Item (for exclusion test)
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            PricebookEntryId = pbe1.Id,
            UnitPrice = 100
            // CurrencyIsoCode = 'USD'
        );
        insert oli;
        
        // Product Family filter
        List<String> productFamily = new List<String>{'TestFamily'};
            
            // Call method
            Test.startTest();
        String result = customAddProductModalClass.findProducts(opp.Id, productFamily);
        Test.stopTest();
    }
    
    
    
    
    @isTest
    static void testGetProductFamily() {
        Test.startTest();
        List<customAddProductModalClass.PicklistValue> result = customAddProductModalClass.getproductfamily();
        Test.stopTest();
    }
    
    @isTest
    static void testSaveProducts() {
        // Get standard pricebook ID
        Id standardPBId = Test.getStandardPricebookId();
        
        // Make sure the standard pricebook is active (already is, but for clarity)
       Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        // Create Custom Pricebook
        Pricebook2 customPB = new Pricebook2(Name = 'TestPB', IsActive = true);
        insert customPB;
        
        // Create Product
        Product2 prod = new Product2(
            Name = 'TestProduct',
            ProductCode = 'P001',
            Family = 'TestFamily',
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert prod;
        
        //  Insert Standard Pricebook Entry first
        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPBId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD'
        );
        insert standardPBE;
        
        //  Now insert Custom Pricebook Entry
        PricebookEntry customPBE = new PricebookEntry(
            Pricebook2Id = customPB.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD'
        );
        insert customPBE;
        
        // Create Opportunity using Custom Pricebook
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(10),
            Pricebook2Id = customPB.Id,
            CurrencyIsoCode = 'USD'
        );
        insert opp;
        
        // Prepare wrapper data for saveProducts
        List<customAddProductModalClass.ProductWrapper> wrapperList = new List<customAddProductModalClass.ProductWrapper>();
        
        customAddProductModalClass.ProductWrapper wrapper = new customAddProductModalClass.ProductWrapper();
        wrapper.Id = customPBE.Id;
        wrapper.Product2Id = prod.Id;
        wrapper.Quantity = 2;
        wrapper.SalesPrice = 120;
        wrapper.Discount = 10;
        wrapper.LineDescription = 'Line item for testing';
        
        wrapperList.add(wrapper);
        
        // Serialize wrapper
        String jsonData = JSON.serialize(wrapperList);
        
        // Call method
        Test.startTest();
        String result = customAddProductModalClass.saveProducts(jsonData, opp.Id);
        Test.stopTest();
        
    }
}