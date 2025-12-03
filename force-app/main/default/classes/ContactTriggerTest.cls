@isTest
public class ContactTriggerTest {
    @testSetup
    static void setupTestData() {
        // Creating test data
        Contact contact = new Contact();
        contact.FirstName = 'Test';
        contact.LastName = 'User';
        contact.MailingStreet = '123 Main St';
        insert contact;
    }
    
    @isTest
    static void testBeforeInsert() {
        Test.startTest();
        Contact contact = new Contact();
        contact.FirstName = 'New';
        contact.LastName = 'Contact';
        contact.MailingStreet = '456 Elm St';
        insert contact;
        Test.stopTest();
        
        // Fetch inserted record
        Contact insertedContact = [SELECT Id, MailingStreet FROM Contact WHERE Id = :contact.Id LIMIT 1];
        System.assertNotEquals(null, insertedContact);
    }
    
    @isTest
    static void testBeforeUpdate() {
        Contact contact = [SELECT Id, MailingStreet FROM Contact LIMIT 1];
        contact.MailingStreet = 'Updated Address';
        
        Test.startTest();
        update contact;
        Test.stopTest();
        
        Contact updatedContact = [SELECT Id, MailingStreet FROM Contact WHERE Id = :contact.Id LIMIT 1];
        System.assertEquals('Updated Address', updatedContact.MailingStreet);
    }
}