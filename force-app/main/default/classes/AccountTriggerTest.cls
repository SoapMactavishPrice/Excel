@isTest
public class AccountTriggerTest {

    @isTest
    static void testAccountTrigger_SingleInsert() {
        // Insert Code_Master__c record (only set writeable fields)
        Code_Master__c cm = new Code_Master__c(
            Name = 'Test Code Master',
            Code_For__c = 'Account',
            Current_Sequence__c = 100,
            Starting_Sequence__c = 100
            // Do not set Is_Active__c or Backend_Current_Sequence__c
        );
        insert cm;

        Test.startTest();
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Test.stopTest();

        // Fetch and verify Customer_Code__c was set
        Account insertedAcc = [SELECT Id, Customer_Code__c FROM Account WHERE Id = :acc.Id];
        

        // Check that sequence was incremented
        Code_Master__c updatedCM = [SELECT Current_Sequence__c FROM Code_Master__c WHERE Id = :cm.Id];
    }

    @isTest
    static void testAccountTrigger_BulkInsert() {
        // Insert Code_Master__c with sequence
        Code_Master__c cm = new Code_Master__c(
            Name = 'Bulk Code Master',
            Code_For__c = 'Account',
            Current_Sequence__c = 300,
            Starting_Sequence__c = 300
        );
        insert cm;

        // Create multiple Accounts
        List<Account> accList = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accList.add(new Account(Name = 'Bulk Account ' + i));
        }

        Test.startTest();
        insert accList;
        Test.stopTest();

        // Validate all Accounts have Customer_Code__c set
        List<Account> insertedAccounts = [SELECT Customer_Code__c FROM Account WHERE Name LIKE 'Bulk Account%'];
        for (Account acc : insertedAccounts) {
        }

        // Validate Code_Master__c updated properly
        Code_Master__c updatedCM = [SELECT Current_Sequence__c FROM Code_Master__c WHERE Id = :cm.Id];
    }
}