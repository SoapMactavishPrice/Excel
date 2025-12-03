@isTest
public class OpportunityTriggerTest {

    @isTest
    static void testOpportunityTrigger() {
        // Create test data for Account and Product
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Create Opportunities
        Opportunity testOpp1 = new Opportunity(
            Name = 'Test Opportunity 1',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = testAccount.Id,
            Pricebook2Id = standardPricebook.Id
        );

        Opportunity testOpp2 = new Opportunity(
            Name = 'Test Opportunity 2',
            StageName = 'Proposal',
            CloseDate = Date.today(),
            AccountId = testAccount.Id,
            Pricebook2Id = standardPricebook.Id
        );

        insert new List<Opportunity> { testOpp1, testOpp2 };

        // Add OpportunityLineItem to testOpp1
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = testOpp1.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pbe.Id
        );
        insert oli;

        // Now update stages
        testOpp1.StageName = 'Closed Won';
        testOpp2.StageName = 'Proposal';

        Test.startTest();
        update new List<Opportunity> { testOpp1, testOpp2 };
        Test.stopTest();

        // Assert stage changes
        Opportunity updatedOpp1 = [SELECT StageName FROM Opportunity WHERE Id = :testOpp1.Id];
        Opportunity updatedOpp2 = [SELECT StageName FROM Opportunity WHERE Id = :testOpp2.Id];

        
    }
}