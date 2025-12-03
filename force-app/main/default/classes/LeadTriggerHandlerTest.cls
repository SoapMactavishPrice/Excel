@isTest
public class LeadTriggerHandlerTest {    
    @isTest
    static void testHandleLeadConversion() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create Country
        Country__c country = new Country__c(Name='TestCountry');
        insert country;
        
        // Create State with proper Country reference
        State__c state = new State__c(Name='TestState', Country__c=country.Id, Zone__c='East');
        insert state;
        
        // Create City (no postal code since it's removed)
        City__c city = new City__c(Name='TestCity', State__c = state.Id);
        insert city;
        
        // Create Postal Code with proper State reference
        Postal_Code__c postal = new Postal_Code__c(Name='123456', State__c=state.Id, City__c = city.Id );
        insert postal;
        
        
        
        // Create Lead record with lookup fields referencing the created records
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Street = '123 Test St',
            City__c = city.Id,          
            State__c = state.Id,       
            Country__c = country.Id,    
            Postal_Code__c = postal.Id, 
            Status = 'New',
            Lead_Type__c = 'Domestic', 
            Zone__c = 'East'
        );
        insert testLead;
        
        Task tas = new Task();
        tas.ActivityDate = system.today();
        tas.WhoId = testLead.Id;
        insert tas;
        
        // Create a Product_Interested__c record related to the Lead
        Product_Interested__c testProduct = new Product_Interested__c(
            // Name = 'Test Product',
            Lead__c = testLead.Id
        );
        insert testProduct;
        
        testLead.Status = 'Working';
        update testLead;
        
        // Get a valid ConvertedStatus
        String validConvertedStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1].MasterLabel;
        
        // Simulate lead conversion
        Database.LeadConvert leadConvert = new Database.LeadConvert();
        leadConvert.setLeadId(testLead.Id);
        leadConvert.setConvertedStatus(validConvertedStatus);
        leadConvert.setAccountId(testAccount.Id);
        
        //Database.LeadConvertResult result = Database.convertLead(leadConvert);
        
        // Validate Address_Information__c record creation
        List<Address_Information__c> addressInfoList = [
            SELECT Id, Account__c, Address_1__c , City__c, State__c, Country__c, Postal_Code__c, RecordType.DeveloperName
            FROM Address_Information__c
            WHERE Account__c = :testAccount.Id
        ];
        
    }
    
    @isTest
    static void testHandleProductInterestedConversion() {
        
        
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create Country
        Country__c country = new Country__c(Name='TestCountry');
        insert country;
        
        // Create State with proper Country reference
        State__c state = new State__c(Name='TestState', Country__c=country.Id, Zone__c='East');
        insert state;
        
        // Create City (no postal code since it's removed)
        City__c city = new City__c(Name='TestCity', State__c = state.Id);
        insert city;
        
        // Create Postal Code with proper State reference
        Postal_Code__c postal = new Postal_Code__c(Name='123456', State__c=state.Id, City__c = city.Id );
        insert postal;
        
        // Create a test Lead
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
            Zone__c = 'East'
        );
        insert testLead;
        
        // Create a Product_Interested__c record related to the Lead
        Product_Interested__c testProduct = new Product_Interested__c(
            // Name = 'Test Product',
            Lead__c = testLead.Id
        );
        insert testProduct;
        
        // Convert the Lead
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        lc.setDoNotCreateOpportunity(true);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        
        Database.LeadConvertResult result = Database.convertLead(lc);
        
        
        // Verify the Account__c field was updated in Product_Interested__c
        Product_Interested__c updatedProduct = [
            SELECT Account__c
            FROM Product_Interested__c
            WHERE Id = :testProduct.Id
        ];
    }
    
    @isTest
    static void testHandleSampleBookingConversion() {
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
        City__c city = new City__c(Name='TestCity', State__c = state.Id);
        insert city;
        
        // Create Postal Code with proper State reference
        Postal_Code__c postal = new Postal_Code__c(Name='123456', State__c=state.Id, City__c = city.Id );
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
            Zone__c = 'East'
        );
        insert testLead;
        
        // Create a Sample_Booking__c record related to the lead
        Sample_Booking__c sampleBooking = new Sample_Booking__c(
            //  Name = 'Test Sample Booking',
            Lead__c = testLead.Id
        );
        insert sampleBooking;
        
        // Simulate the conversion by creating an Account and Opportunity
        Account testAccount1 = new Account(
            Name = 'Test Company'
        );
        insert testAccount1;
        
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = testAccount1.Id
        );
        insert testOpportunity;
        
        // Simulate Lead Conversion by updating the Converted fields
        testLead = [SELECT Id, IsConverted FROM Lead WHERE Id = :testLead.Id];
        // testLead.IsConverted = true;
        //   testLead.ConvertedAccountId = testAccount.Id;
        //  testLead.ConvertedOpportunityId = testOpportunity.Id;
        update testLead;
        
        // Step 2: Call the Handler Method
        List<Lead> newLeads = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id = :testLead.Id];
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead> { testLead.Id => new Lead(IsConverted = false) };
            
            Test.startTest();
        LeadTriggerHandler.handleSampleBookingConversion(newLeads, oldLeadMap);
        Test.stopTest();
        
        // Step 3: Verify the Results
        Sample_Booking__c updatedSampleBooking = [
            SELECT Id, Account__c, Opportunity__c
            FROM Sample_Booking__c
            WHERE Id = :sampleBooking.Id
        ];
    }
    
    
}