@IsTest
public class LwcEditProductInterestedControllerTest {
    
    @TestSetup
    static void setupTestData() {
       // Step 1: Create Test Data
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
        
        // Create test Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            Family = 'Electronics',
            ProductCode = 'TP001',
            IsActive = true
        );
        insert testProduct;
        
        // Create a Product_Interested__c record related to the Lead
        Product_Interested__c testPI = new Product_Interested__c(
            // Name = 'Test Product',
            Lead__c = testLead.Id
        );
        insert testPI;
      /*  
        // Create a test Product_Interested__c record
        Product_Interested__c testPI = new Product_Interested__c(
            Lead__c = testLead.Id,
            Product__c = testProduct.Id,
            Volume_in_Kgs__c = 100,
            Expected_Price__c = 500,
            Add_In_Opty__c = false,
            Product_Family__c = 'Electronics',
            Product_Code__c = 'TP001'
        );
        insert testPI;*/
    }
    
    @IsTest
    static void testGetProdInterest() {
        // Get test lead ID
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        // Call the method
        Test.startTest();
        List<Product_Interested__c> piList = LwcEditProductInterestedController.getProdInterest(testLead.Id);
        Test.stopTest();
   }

    @IsTest
    static void testUpdateData() {
        // Fetch an existing Product_Interested__c record
        Product_Interested__c existingPI = [SELECT Id, Volume_in_Kgs__c, Expected_Price__c FROM Product_Interested__c LIMIT 1];

        // Create JSON string to simulate LWC input
        String jsonInput = '[{"Id": "' + existingPI.Id + '", "Volume_in_Kgs": "200", "Expected_Price": "600", "Add_In_Opty": true}]';

        // Call updateData method
        Test.startTest();
        Map<String, String> result = LwcEditProductInterestedController.updateData(jsonInput);
        Test.stopTest();

        // Query updated record
        Product_Interested__c updatedPI = [SELECT Volume_in_Kgs__c, Expected_Price__c, Add_In_Opty__c FROM Product_Interested__c WHERE Id = :existingPI.Id];
}
}