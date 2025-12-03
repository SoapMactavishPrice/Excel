@isTest
public class QuoteLineItemHistoryControllerTest {

    @isTest
    static void testGetLatestQuoteLineItems() {
        // Create test Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create test Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(15)
        );
        insert opp;

        // Get standard Pricebook ID
        Id stdPricebookId = Test.getStandardPricebookId();

        // Create Product
        Product2 prod = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert prod;

        // Create PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = stdPricebookId,
            UnitPrice = 200,
            IsActive = true
        );
        insert pbe;

        // Create Quote
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = stdPricebookId,
            Status = 'Draft'
        );
        insert quote;

        // Create QuoteLineItem
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 10,
            UnitPrice = 200
        );
        insert qli;

        // Run test
        Test.startTest();
        List<QuoteLineItemHistoryController.QuoteLineItemWrapper> result =
            QuoteLineItemHistoryController.getLatestQuoteLineItems(quote.Id);
        Test.stopTest();

        
    }
}