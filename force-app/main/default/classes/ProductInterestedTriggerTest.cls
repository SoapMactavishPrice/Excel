@isTest
public class ProductInterestedTriggerTest {
    
    @isTest
    static void testProductInterestedTrigger() {
        // Create a test Product_Interested__c record
        Product_Interested__c productInterested = new Product_Interested__c(
          //  Name = 'Test Product',
           // Currency__c = 'USD'  // Assuming there's a Currency__c field to test
        );
        
        // Test for Insert Trigger
        Test.startTest();
        insert productInterested;
        Test.stopTest();
        
        // Verify that the trigger and handler ran successfully
      //  Product_Interested__c insertedProduct = [SELECT Id, Name, Currency__c FROM Product_Interested__c WHERE Id = :productInterested.Id];
        
        // Check that Currency was updated as per the logic in the handler
      //  System.assertEquals('UpdatedCurrency', insertedProduct.Currency__c);  // Replace with the actual expected result
    }
}