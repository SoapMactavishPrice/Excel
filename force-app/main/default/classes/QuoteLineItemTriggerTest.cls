@isTest
private class QuoteLineItemTriggerTest {
    
    @testSetup
    static void setupData() {
        // Create a test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create an Opportunity (required for Quote)
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testOpportunity;

        // Create a Product
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        // Create Pricebook and PricebookEntry
       Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbe;

        // Create a Quote linked to the Opportunity
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpportunity.Id,
            Pricebook2Id = standardPricebook.Id,
            Status = 'Draft'
        );
        insert testQuote;

        // Create a QuoteLineItem linked to the Quote and Product
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100.00
        );
        insert qli;
    }

    @isTest
    static void testUpdateQuoteLineItem() {
        QuoteLineItem qli = [SELECT Id, Quantity, UnitPrice FROM QuoteLineItem LIMIT 1];
        qli.Quantity = 2;
        qli.UnitPrice = 150.00;

        Test.startTest();
        update qli;
        Test.stopTest();

        QuoteLineItem updatedQLI = [SELECT Quantity, UnitPrice FROM QuoteLineItem WHERE Id = :qli.Id];
       
    }
}