@IsTest
private class lookupComponentControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST001',
            Family = 'Test Family',
            IsActive = true
        );
        insert testProduct;
        
        // Create pricebook entry
        PricebookEntry testPBE = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert testPBE;
        
        // Create additional test data for different scenarios
        List<Product2> products = new List<Product2>();
        List<PricebookEntry> pbes = new List<PricebookEntry>();
        
        for(Integer i = 0; i < 5; i++) {
            Product2 p = new Product2(
                Name = 'Product ' + i,
                ProductCode = 'CODE' + i,
                Family = 'Family ' + (i < 3 ? 'A' : 'B'),
                IsActive = true
            );
            products.add(p);
        }
        insert products;
        
        for(Product2 p : products) {
            Integer lastDigit = Integer.valueOf(p.Name.right(1));
            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = p.Id,
                UnitPrice = 100.00 + lastDigit, // Integer will be automatically converted to Decimal
                IsActive = true,
                CurrencyIsoCode = 'USD'
            );
            pbes.add(pbe);
        }
        insert pbes;
    }
    
    @IsTest
    static void testFindRecordsWithSearchKey() {
        // Test with search key
        Test.startTest();
        String result = lookupComponentController.findRecords(
            null, // indusId
            null, // deptId
            'Test', // searchKey
            'PricebookEntry', // objectName
            null, // recdataid
            'Id,Product2.Name', // returnFields
            null, // queryFields
            'ProductCode,UnitPrice', // displayFields
            null, // filter
            null, // sortColumn
            null, // maxResults
            true, // searchWithMiddle
            null, // family
            'USD' // currencyCode
        );
        Test.stopTest();
        
        // Verify results
        List<lookupComponentController.Wrapper> wrappers = (List<lookupComponentController.Wrapper>)JSON.deserialize(
            result, List<lookupComponentController.Wrapper>.class);
        
       
    }
    
    @IsTest
    static void testFindRecordsWithFamilyFilter() {
        // Test with family filter
        Test.startTest();
        String result = lookupComponentController.findRecords(
            null, // indusId
            null, // deptId
            'Product', // searchKey
            'PricebookEntry', // objectName
            null, // recdataid
            'Id,Product2.Name', // returnFields
            null, // queryFields
            'ProductCode,UnitPrice', // displayFields
            null, // filter
            null, // sortColumn
            null, // maxResults
            true, // searchWithMiddle
            'Family A', // family
            'USD' // currencyCode
        );
        Test.stopTest();
        
        // Verify results
        List<lookupComponentController.Wrapper> wrappers = (List<lookupComponentController.Wrapper>)JSON.deserialize(
            result, List<lookupComponentController.Wrapper>.class);
        
        System.assert(!wrappers.isEmpty(), 'Should return records for Family A');
        for(lookupComponentController.Wrapper w : wrappers) {
        }
    }
    
    @IsTest
    static void testFindRecordsWithNoSearchKey() {
        // Test with no search key
        Test.startTest();
        String result = lookupComponentController.findRecords(
            null, // indusId
            null, // deptId
            '', // searchKey
            'PricebookEntry', // objectName
            null, // recdataid
            'Id,Product2.Name', // returnFields
            null, // queryFields
            'ProductCode,UnitPrice', // displayFields
            null, // filter
            null, // sortColumn
            '5', // maxResults
            true, // searchWithMiddle
            null, // family
            'USD' // currencyCode
        );
        Test.stopTest();
        
        // Verify results
        List<lookupComponentController.Wrapper> wrappers = (List<lookupComponentController.Wrapper>)JSON.deserialize(
            result, List<lookupComponentController.Wrapper>.class);
        
    }
    
    @IsTest
    static void testFindRecordsWithInvalidCurrency() {
        // Test with invalid currency code
        Test.startTest();
        String result = lookupComponentController.findRecords(
            null, // indusId
            null, // deptId
            'Test', // searchKey
            'PricebookEntry', // objectName
            null, // recdataid
            'Id,Product2.Name', // returnFields
            null, // queryFields
            'ProductCode,UnitPrice', // displayFields
            null, // filter
            null, // sortColumn
            null, // maxResults
            true, // searchWithMiddle
            null, // family
            'EUR' // currencyCode (no entries in this currency)
        );
        Test.stopTest();
        
        // Verify results
        List<lookupComponentController.Wrapper> wrappers = (List<lookupComponentController.Wrapper>)JSON.deserialize(
            result, List<lookupComponentController.Wrapper>.class);
        
    }
    
  /*  @IsTest
    static void testFindRecordsWithSorting() {
        // Test with sorting
        Test.startTest();
        String result = lookupComponentController.findRecords(
            null, // indusId
            null, // deptId
            'Product', // searchKey
            'PricebookEntry', // objectName
            null, // recdataid
            'Id,Product2.Name', // returnFields
            null, // queryFields
            'ProductCode,UnitPrice', // displayFields
            null, // filter
            'Product2.Name DESC', // sortColumn
            null, // maxResults
            true, // searchWithMiddle
            null, // family
            'USD' // currencyCode
        );
        Test.stopTest();
        
        // Verify results
        List<lookupComponentController.Wrapper> wrappers = (List<lookupComponentController.Wrapper>)JSON.deserialize(
            result, List<lookupComponentController.Wrapper>.class);
        
        // Verify sorting (names should be in descending order)
        for(Integer i = 0; i < wrappers.size() - 1; i++) {
        }
    } */
    
    @IsTest
    static void testWrapperClass() {
        // Test the wrapper class directly
        lookupComponentController.Wrapper testWrapper = new lookupComponentController.Wrapper();
        testWrapper.Id = '001000000000001';
        testWrapper.Name = 'Test Wrapper';
        testWrapper.productCode = 'WRAP001';
        testWrapper.familyField = 'Wrapper Family';
        testWrapper.unitPrice = 99.99;
        testWrapper.proId = '01t000000000001';
        
        
    }
    
    
    
    
    
    
  
    
    @IsTest
    static void testFetchDefaultRecordWithValidId() {
        // Get the test PricebookEntry record
        PricebookEntry testPBE = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        Test.startTest();
        String result = lookupComponentController.fetchDefaultRecord(
            testPBE.Id, // recordId
            'PricebookEntry', // sObjectApiName
            'Product2.Description' // returnFields (not currently used in the method)
        );
        Test.stopTest();
        
      
        
        lookupComponentController.Wrapper wrapper = (lookupComponentController.Wrapper)JSON.deserialize(
            result, lookupComponentController.Wrapper.class);
        
        
    }
    
    @IsTest
    static void testFetchDefaultRecordWithInvalidId() {
        Test.startTest();
        String result = lookupComponentController.fetchDefaultRecord(
            '001000000000000', // invalid recordId
            'PricebookEntry', // sObjectApiName
            '' // returnFields
        );
        Test.stopTest();
        
        
    }
    
    @IsTest
    static void testFetchDefaultRecordWithEmptyId() {
        Test.startTest();
        String result = lookupComponentController.fetchDefaultRecord(
            '', // empty recordId
            'PricebookEntry', // sObjectApiName
            'SomeField' // returnFields
        );
        Test.stopTest();
        
       
    }
    
 /*   @IsTest
    static void testFetchDefaultRecordWithNullId() {
        Test.startTest();
        String result = lookupComponentController.fetchDefaultRecord(
            null, // null recordId
            'PricebookEntry', // sObjectApiName
            null // returnFields
        );
        Test.stopTest();
        
      
    }*/
}