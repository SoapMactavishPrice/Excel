@isTest
public class ContactTriggerHandlerTest {

    @isTest
    static void testUpdateContactAddresses_withPostalCode() {
        // Create Country record
        Country__c country = new Country__c(Name = 'India');
        insert country;

        // Create hierarchy
        State__c state = new State__c(Name = 'Gujarat', Country__c = country.Id);
        insert state;

        City__c city = new City__c(Name = 'Ahmedabad', State__c = state.Id, Country__c = country.Id);
        insert city;

        Area__c area = new Area__c(Name = 'Satellite', City__c = city.Id, State__c = state.Id, Country__c = country.Id);
        insert area;

        Postal_Code__c postal = new Postal_Code__c(Name = '380015', Area__c = area.Id, City__c = city.Id, State__c = state.Id, Country__c = country.Id);
        insert postal;

        // Create Contact
        Contact con = new Contact(LastName = 'Test Postal', Mailing_Zip_Code__c = postal.Id);
        insert con;

        Test.startTest();
        ContactTriggerHandler.updateContactAddresses(new List<Contact>{con});
        Test.stopTest();

       
    }

    @isTest
    static void testUpdateContactAddresses_withArea() {
        Country__c country = new Country__c(Name = 'India');
        insert country;

        State__c state = new State__c(Name = 'Maharashtra', Country__c = country.Id);
        insert state;

        City__c city = new City__c(Name = 'Mumbai', State__c = state.Id, Country__c = country.Id);
        insert city;

        Area__c area = new Area__c(Name = 'Andheri', City__c = city.Id, State__c = state.Id, Country__c = country.Id);
        insert area;

        Contact con = new Contact(LastName = 'Test Area', Mailing_Area__c = area.Id);
        insert con;

        Test.startTest();
        ContactTriggerHandler.updateContactAddresses(new List<Contact>{con});
        Test.stopTest();

      
    }

    @isTest
    static void testUpdateContactAddresses_withCity() {
        Country__c country = new Country__c(Name = 'India');
        insert country;

        State__c state = new State__c(Name = 'Rajasthan', Country__c = country.Id);
        insert state;

        City__c city = new City__c(Name = 'Jaipur', State__c = state.Id, Country__c = country.Id);
        insert city;

        Contact con = new Contact(LastName = 'Test City', Mailing_City__c = city.Id);
        insert con;

        Test.startTest();
        ContactTriggerHandler.updateContactAddresses(new List<Contact>{con});
        Test.stopTest();

       
    }

    @isTest
    static void testUpdateContactAddresses_withState() {
        Country__c country = new Country__c(Name = 'India');
        insert country;

        State__c state = new State__c(Name = 'Karnataka', Country__c = country.Id);
        insert state;

        Contact con = new Contact(LastName = 'Test State', Mailing_State__c = state.Id);
        insert con;

        Test.startTest();
        ContactTriggerHandler.updateContactAddresses(new List<Contact>{con});
        Test.stopTest();

        
    }
}