@isTest
public class UpdateProductInterestedTest {

    static Id productAId;
    static Id productBId;
    
    @testSetup
    static void setupData() {
        //  Corrected Object Name
        Product2 productA = new Product2(Name = 'Product A');
        Product2 productB = new Product2(Name = 'Product B');
        insert new List<Product2>{ productA, productB };

        productAId = productA.Id;
        productBId = productB.Id;

        // Create Lead
        Lead lead = new Lead(
            FirstName = 'John', 
            LastName = 'Doe', 
            Company = 'Test Company', 
            Lead_Type__c= 'Domestic', 
            Zone__c = 'East'
        );
        insert lead;

        // Insert Product_Interested__c record
        Product_Interested__c pi = new Product_Interested__c(
            Lead__c = lead.Id, 
            Product__c = productAId
        );
        insert pi;
    }
    
    @isTest
    static void testInsertTrigger() {
        Lead lead = [SELECT Id, Product_Interested__c FROM Lead LIMIT 1];

        Product_Interested__c pi2 = new Product_Interested__c(
            Lead__c = lead.Id, 
            Product__c = productBId
        );
        
        Test.startTest();
        insert pi2;
        Test.stopTest();

        Lead updatedLead = [SELECT Product_Interested__c FROM Lead WHERE Id = :lead.Id];
        System.debug('Updated Product_Interested__c: ' + updatedLead.Product_Interested__c);
       
    }

    @isTest
    static void testDeleteTrigger() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        List<Product_Interested__c> allProducts = [SELECT Id FROM Product_Interested__c WHERE Lead__c = :lead.Id];

        Test.startTest();
        delete allProducts;
        Test.stopTest();

        Lead updatedLead = [SELECT Product_Interested__c FROM Lead WHERE Id = :lead.Id];
        System.debug('After Delete: ' + updatedLead.Product_Interested__c);
    }

    @isTest
    static void testUpdateTrigger() {
        Product_Interested__c pi = [SELECT Id FROM Product_Interested__c LIMIT 1];
        Test.startTest();
        update pi;
        Test.stopTest();
    }
}