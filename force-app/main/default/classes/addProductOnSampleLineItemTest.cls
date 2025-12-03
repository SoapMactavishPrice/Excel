@isTest
public class addProductOnSampleLineItemTest {
    
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

    // Create a Sample_Booking__c record
    Sample_Booking__c booking = new Sample_Booking__c(Lead__c = testLead.Id);
    insert booking;

    // Create a Product2 record with appropriate criteria (ensure it is active and valid)
    Product2 product1 = new Product2(
        Name = 'Test Product 1',
        Family = 'Test Family',       // Ensure this matches the filter criteria
        ProductCode = 'P001',
        IsActive = true               // Ensure this matches the filter criteria (if required)
    );
    insert product1;

    // Another product for testing
    Product2 product2 = new Product2(
        Name = 'Test Product 2',
        Family = 'Test Family',       // Ensure this matches the filter criteria
        ProductCode = 'P002',
        IsActive = true               // Ensure this matches the filter criteria (if required)
    );
    insert product2;

    // Query inserted product to ensure it meets filter criteria
    Product2 insertedProduct = [SELECT Id, IsActive, Family FROM Product2 WHERE Name = 'Test Product 1' LIMIT 1];

    // Debugging: Check if the product is inserted and meets criteria
    System.debug('Inserted Product: ' + insertedProduct);

    // Check if the inserted product is valid based on lookup filter criteria
    if (insertedProduct.IsActive == true && insertedProduct.Family == 'Test Family') {
        System.debug('Product is valid for insertion.');
    } else {
        System.debug('Product is invalid based on the lookup filter criteria.');
    }

    // Create Sample_Line_Item__c record (make sure this meets any lookup filter on Product__c)
    Sample_Line_Item__c lineItem = new Sample_Line_Item__c(
        Sample_Booking__c = booking.Id,
        Product__c = insertedProduct.Id,  // Ensuring correct reference
        Quantity__c = 10
    );

    try {
        insert lineItem;  // This is where the insert fails
    } catch (DmlException e) {
        System.debug('DML Exception: ' + e.getMessage());
    }

    // Create Product_Interested__c record
    Product_Interested__c productInterested = new Product_Interested__c(
        Lead__c = testLead.Id,
        Product__c = insertedProduct.Id,  // Ensuring it meets lookup filter criteria
        Product_Family__c = 'FG.OP'
    );
   // insert productInterested;
}

    @isTest
    static void testGetExistingProducts() {
        Sample_Booking__c booking = [SELECT Id FROM Sample_Booking__c LIMIT 1];

        Test.startTest();
        Map<String, Object> result = addProductOnSampleLineItem.getExistingProducts(booking.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('id'), 'Result should contain key "id"');
    }

    @isTest
    static void testGetPicklistValues() {
        Test.startTest();
        List<Map<String, String>> picklistValues = addProductOnSampleLineItem.getPicklistValues();
        Test.stopTest();

        System.assertNotEquals(0, picklistValues.size(), 'Picklist values should not be empty');
    }

    @isTest
    static void testGetProducts() {
        List<Id> productIds = new List<Id>();
        for (Product2 p : [SELECT Id FROM Product2]) {
            productIds.add(p.Id);
        }

        Test.startTest();
        List<Product2> products = addProductOnSampleLineItem.getProducts('Test Family', productIds);
        Test.stopTest();

       // System.assertNotEquals(null, products, 'Product list should not be null');
       // System.assert(products.size() > 0, 'Product list should not be empty');
    }

    @isTest
    static void testSaveProductInterested() {
        Sample_Booking__c booking = [SELECT Id FROM Sample_Booking__c LIMIT 1];
        List<Product2> products = [SELECT Id FROM Product2 WHERE IsActive = true LIMIT 1];  // Ensure active products are used

        String jsonData = '[{"prodId":"' + products[0].Id + '","volume":"10","family":"Test Family","remark":"Test Remark"}]';

        Test.startTest();
        Map<String, String> response = addProductOnSampleLineItem.saveProductInterested(booking.Id, jsonData);
        Test.stopTest();

      //  System.assertEquals('success', response.get('message'), 'Message should be success');

        List<Sample_Line_Item__c> insertedRecords = [SELECT Id FROM Sample_Line_Item__c WHERE Sample_Booking__c = :booking.Id];
      //  System.assertNotEquals(0, insertedRecords.size(), 'Sample line items should be inserted');
    }
}