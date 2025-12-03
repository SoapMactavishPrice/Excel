@isTest
public class OpportunityTriggerHandlerTest {
    
    @isTest
    static void testHandleProposalOpportunities() {
        Country__c testCountry = new Country__c(Name = 'India');
        insert testCountry;
        State__c testState = new State__c(Name = 'Test State', Country__c = testCountry.Id);
        insert testState;
        City__c testCity = new City__c(Name = 'Test City', State__c = testState.Id, Country__c = testCountry.Id);
        insert testCity;
        Area__c testArea = new Area__c(Name = 'Test Area', City__c = testCity.Id, State__c = testState.Id, Country__c = testCountry.Id);
        insert testArea;
        Postal_Code__c testPostalCode = new Postal_Code__c(Name = '12345', Area__c = testArea.Id, City__c = testCity.Id, State__c = testState.Id, Country__c = testCountry.Id);
        insert testPostalCode;
        Id PID = Test.getStandardPricebookId();
        Product2 prod = new Product2();
        prod.name='Product A';
        prod.isActive=true;
        insert prod;

        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = PID, 
            Product2Id = prod.Id,
            UnitPrice = 1000,
            IsActive = true);
        insert standardPrice;
        Account acc = new Account();
        acc.Name = 'Finesse';
        insert acc;

 
        Contact con = new Contact();
        con.AccountId = acc.id;
        con.FirstName = 'Prashant';
        con.LastName = 'Padal';
        con.Email = 'Prashantpadal@finessedirect.com';
        con.Phone = '123-456-7890';
    /*    con.Contact_Country__c= testCountry.id;
        con.Contact_City__c=testCity.id;
        con.Contact_State__c=testState.id;
        con.Contact_Area__c=testArea.id;
        con.Street__c='MBP Road';
        con.Contact_Postal_Code__c=testPostalCode.id; */
        insert con;

        Opportunity opp = new Opportunity();
        opp.Name = 'Finesse';
        opp.StageName = 'Sampling';
        opp.CloseDate = Date.today();
        opp.AccountId = acc.Id;
     //   opp.Contact__c = con.Id;
        opp.Pricebook2Id=PID;
        insert opp;
 
        OpportunityLineItem oli = new OpportunityLineItem
            (OpportunityId = opp.Id,
             pricebookentryid=standardPrice.id, 
             product2Id= prod.Id,
             UnitPrice = 1000, 
             Quantity = 1, 
             Discount=10);
        insert oli;
        System.debug('oli' +oli);
        opp.StageName = 'Proposal';
        update opp;
        opp.StageName='Closed Won';
        update opp;

        Map<Id, Opportunity> oldOpportunityMap = new Map<Id, Opportunity>();
        oldOpportunityMap.put(opp.Id, new Opportunity(StageName = 'Sampling')); 
        List<Opportunity> newOpportunities = new List<Opportunity>{opp};
        Test.startTest();
          OpportunityTriggerHandler.handleProposalOpportunities(newOpportunities, oldOpportunityMap);
          OpportunityTriggerHandler.handleClosedWonOpportunities(newOpportunities, oldOpportunityMap);
        Test.stopTest();

    }

}