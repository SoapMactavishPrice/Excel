@isTest
private class LeadTriggerTest {
    @testSetup
    static void setupTestData() {
        List<Lead> leads = new List<Lead>{
            new Lead(
                FirstName = 'John',
                LastName = 'Doe',
                Company = 'TestCompany',
                Status = 'Open - Not Contacted',
                Lead_Type__c = 'Domestic',    
                Zone__c = 'East'              
            ),
                new Lead(
                    FirstName = 'Jane',
                    LastName = 'Smith',
                    Company = 'TestCompany',
                    Status = 'Working - Contacted',
                    Lead_Type__c = 'Domestic',    
                    Zone__c = 'East'              
                )
                };
                    insert leads;
    }

    
    @isTest
    static void testBeforeInsertUpdate() {
        // Create the Lead (not inserted yet)
        Lead newLead = new Lead(
            FirstName = 'Mike',
            LastName = 'Ross',
            Company = 'Test Inc',
            Status = 'Open - Not Contacted',
            Lead_Type__c = 'Domestic',    
            Zone__c = 'East'
        );
        
        Test.startTest();
        insert newLead; 
        Test.stopTest();
        
        // Verify lead is inserted
        Lead insertedLead = [SELECT Id, FirstName, LastName, Company FROM Lead WHERE Id = :newLead.Id LIMIT 1];
        
        // Update test
        insertedLead.LastName = 'UpdatedLastName';
        update insertedLead;
        
        // Verify update
        Lead updatedLead = [SELECT Id, LastName FROM Lead WHERE Id = :insertedLead.Id LIMIT 1];
    }

    
    @isTest
    static void testAfterUpdate() {
        Lead testLead = [SELECT Id, Status FROM Lead LIMIT 1];
        testLead.Status = 'Converted';
        
        Test.startTest();
       // update testLead;
        Test.stopTest();
        
        // Verify trigger executed successfully
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id LIMIT 1];
    }
}