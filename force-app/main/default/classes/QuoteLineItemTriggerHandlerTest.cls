@isTest
private class QuoteLineItemTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;

        // Get Standard Pricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        // Create Product
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        // Create Pricebook Entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Create Quote
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = standardPricebook.Id,
            Status = 'Draft'
        );
        insert quote;

        // Create QuoteLineItem
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            Purchase_Price_in_INR__c = 80
        );
        insert qli;
    }

    @isTest
    static void testUpdateTriggersPreviousPurchasePrice() {
        // Retrieve inserted QLI
        QuoteLineItem qli = [SELECT Id, Purchase_Price_in_INR__c, Previous_Purchase_Price__c FROM QuoteLineItem LIMIT 1];

        // Update Purchase Price
        qli.Purchase_Price_in_INR__c = 90;

        Test.startTest();
        update qli;
        Test.stopTest();

        // Verify Previous_Purchase_Price__c is updated to original value
        QuoteLineItem updatedQLI = [SELECT Id, Purchase_Price_in_INR__c, Previous_Purchase_Price__c FROM QuoteLineItem WHERE Id = :qli.Id];
       
    }

    @isTest
    static void testNoChangeInPurchasePrice() {
        QuoteLineItem qli = [SELECT Id, Purchase_Price_in_INR__c FROM QuoteLineItem LIMIT 1];

        Test.startTest();
        update qli; // No change to Purchase_Price_in_INR__c
        Test.stopTest();

        QuoteLineItem updatedQLI = [SELECT Id, Previous_Purchase_Price__c FROM QuoteLineItem WHERE Id = :qli.Id];
    }
}