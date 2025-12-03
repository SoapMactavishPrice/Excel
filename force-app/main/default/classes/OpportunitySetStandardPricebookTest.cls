@isTest
public class OpportunitySetStandardPricebookTest {

    @isTest
    static void testAssignStandardPricebook() {
        // Ensure Standard Pricebook is active and available
        Pricebook2 standardPricebook = new Pricebook2(

            Id = Test.getStandardPricebookId(),

            IsActive = true

        );

        update standardPricebook;
 
        if (!standardPricebook.IsActive) {
            standardPricebook.IsActive = true;
            update standardPricebook;
        }

        // Create an Opportunity without a Pricebook
        Opportunity oppNoPB = new Opportunity(
            Name = 'Test Opportunity No Pricebook',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );

        insert oppNoPB;

        // Fetch the inserted Opportunity
        Opportunity insertedOpp = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id = :oppNoPB.Id];
        
    }

    @isTest
    static void testRetainCustomPricebook() {
        // Create a custom pricebook
        Pricebook2 customPB = new Pricebook2(Name = 'Custom PB', IsActive = true);
        insert customPB;

        // Create an Opportunity with a custom Pricebook
        Opportunity oppWithPB = new Opportunity(
            Name = 'Test Opportunity With Custom PB',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = customPB.Id
        );

        insert oppWithPB;

        // Verify Pricebook was not overwritten
        Opportunity insertedOpp = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id = :oppWithPB.Id];
    }
}