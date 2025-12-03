@isTest
public class lwcProductInterestedTest {
    @testSetup
    static void setupTestData() {
         // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create Country
        Country__c country = new Country__c(Name='TestCountry');
        insert country;
        
        // Create State with proper Country reference
        State__c state = new State__c(Name='TestState', Country__c=country.Id, Zone__c='East');
        insert state;
        
         // Create City (no postal code since it's removed)
        City__c city = new City__c(Name='TestCity');
        insert city;
        
        // Create Postal Code with proper State reference
        Postal_Code__c postal = new Postal_Code__c(Name='123456', State__c=state.Id);
        insert postal;
        
        // Create a test Lead
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
        
        Product2 testProduct1 = new Product2(
            Name = 'Test Product 1',
            Family = 'Test Family'
        );
        insert testProduct1;
        
        Product2 testProduct2 = new Product2(
            Name = 'Test Product 2',
            Family = 'Test Family'
        );
        insert testProduct2;
        
        // Create a Product_Interested__c record related to the Lead
        Product_Interested__c pi = new Product_Interested__c(
            // Name = 'Test Product',
            Lead__c = testLead.Id
        );
        insert pi;
        /*
        Product_Interested__c pi = new Product_Interested__c(
            Lead__c = testLead.Id,
            Product__c = testProduct1.Id,
            Volume_in_Kgs__c = 100,
            Expected_Price__c = 500,
            Product_Family__c = 'Test Family'
        );
        insert pi;*/
    }
    
    @isTest
    static void testGetExistingProducts() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Test.startTest();
        List<Id> productIds = lwcProductInterested.getExistingProducts(testLead.Id);
        Test.stopTest();
        System.assertEquals(1, productIds.size(), 'There should be one existing product.');
    }
    
    @isTest
    static void testGetPicklistValues() {
        Test.startTest();
        List<Map<String, String>> picklistValues = lwcProductInterested.getPicklistValues();
        Test.stopTest();
        System.assert(picklistValues != null, 'Picklist values should not be null.');
    }
    
    @isTest
    static void testGetProducts() {
        List<Id> existingProductIds = new List<Id>();
        for (Product_Interested__c pi : [SELECT Id, Product__c FROM Product_Interested__c]) {
            existingProductIds.add(pi.Product__c);
        }
        Test.startTest();
        List<Product2> products = lwcProductInterested.getProducts('Test Family', existingProductIds);
        Test.stopTest();
  
    }
    
    @isTest
    static void testSaveProductInterested() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        List<Product2> availableProducts = [SELECT Id, Name, Family FROM Product2];
        
        Map<String, Object> productMap = new Map<String, Object>();
        productMap.put('Id', availableProducts[0].Id);
        productMap.put('volume', '150');
        productMap.put('price', '600');
        productMap.put('family', availableProducts[0].Family);
        
        List<Object> productList = new List<Object>();
        productList.add(productMap);
        
        String jsonString = JSON.serialize(productList);
        
        Test.startTest();
        Map<String, String> response = lwcProductInterested.saveProductInterested(testLead.Id, jsonString);
        Test.stopTest();
        
  
    }
}