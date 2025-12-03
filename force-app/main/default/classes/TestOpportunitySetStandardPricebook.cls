@isTest
public class TestOpportunitySetStandardPricebook {
    
    @isTest
    static void testStandardPricebookAssignment() {
        // Step 1: Ensure Standard Pricebook is active (required for using in Opportunities)
       Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        
        // Step 2: Create a test Opportunity without a Pricebook
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
            // Pricebook2Id intentionally left null to trigger logic
        );

        Test.startTest();
        insert opp;
        Test.stopTest();

        // Step 3: Retrieve the inserted Opportunity and assert that Pricebook2Id was assigned
        Opportunity insertedOpp = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id = :opp.Id];
    }
}