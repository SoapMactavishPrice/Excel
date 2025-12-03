@isTest
public class OptyTriggerHandlerTest {

    @TestSetup
    static void setupTestData() {
      
    }

    @isTest
    static void testConvertHandler() {
        // Create test Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;

        Id standardPriceBookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(Id = standardPriceBookId, IsActive = true);
        update standardPricebook;

      
        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert standardPBE;

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
        City__c city = new City__c(Name='TestCity', State__c=state.id,Country__c=country.Id);
        insert city;
        
        // Create Postal Code with proper State reference
        Postal_Code__c postal = new Postal_Code__c(Name='123456', State__c=state.Id,City__c=city.id,Country__c=country.Id );
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
            Zone__c = 'East',
            CurrencyIsoCode = 'USD'
        );
        insert testLead;

        // First insert Product_Interested__c before converting the Lead
        Product_Interested__c testProductInterested = new Product_Interested__c(
            Lead__c = testLead.Id,
            Product__c = testProduct.Id,
            Volume_in_Kgs__c = 10,
            Expected_Price__c = 150,
            Add_In_Opty__c = true  
        );
        insert testProductInterested;
        
        // Now convert the Lead
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        lc.setConvertedStatus(getConvertedStatus());
        lc.setDoNotCreateOpportunity(false);
        lc.setOpportunityName('Test Opportunity');
        Database.LeadConvertResult lcr = Database.convertLead(lc);
       

      
        testLead = [SELECT Id, IsConverted, ConvertedOpportunityId FROM Lead WHERE Id = :testLead.Id];
        Opportunity testOpp = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id = :testLead.ConvertedOpportunityId];

       
        testOpp.Pricebook2Id = standardPriceBookId;
        update testOpp;

        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>{
            testLead.Id => new Lead(
                Id = testLead.Id,
                IsConverted = false
            )
        };

      
        Test.startTest();
        OptyTriggerHandler.convertHandler(new List<Lead>{testLead}, oldLeadMap);
        Test.stopTest();

       
        List<OpportunityLineItem> oliList = [
            SELECT Id, OpportunityId, PricebookEntryId, Quantity, UnitPrice 
            FROM OpportunityLineItem 
            WHERE OpportunityId = :testOpp.Id
        ];

        
    }

    public static String getConvertedStatus() {
        LeadStatus convertStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
        return convertStatus.MasterLabel;
    }
    
}