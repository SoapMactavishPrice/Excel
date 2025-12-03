@IsTest
public class EnhancedCustomLookupTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create test contacts
        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 1; i <= 5; i++) {
            testContacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                AccountId = testAccount.Id,
                Email = 'test' + i + '@example.com'
            ));
        }
        insert testContacts;
        
        // Create test cases
        List<Case> testCases = new List<Case>();
        for (Integer i = 1; i <= 3; i++) {
            testCases.add(new Case(
                Subject = 'Test Case ' + i,
                Status = 'New'
            ));
        }
        insert testCases;
    }
    
    @IsTest
    static void testFindRecordsForContact() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        List<sObject> results = EnhancedCustomLookup.findRecords(
            'Test Contact',  // searchKey
            'Contact',       // objectName
            null,           // recdataid
            'Email',        // returnFields
            new List<String>{'LastName'}, // queryFields
            'FirstName',    // displayFields
            '',             // filter
            'LastName',     // sortColumn
            '5',            // maxResults
            testAccount.Id  // parentAccountId
        );
        Test.stopTest();
        
        
    }
    
    @IsTest
    static void testFindRecordsForCase() {
        Test.startTest();
        List<sObject> results = EnhancedCustomLookup.findRecords(
            'Test Case',    // searchKey
            'Case',         // objectName
            null,           // recdataid
            'Subject',      // returnFields
            new List<String>{'CaseNumber'}, // queryFields
            'Status',       // displayFields
            '',             // filter
            'CaseNumber',   // sortColumn
            '3',            // maxResults
            null            // parentAccountId
        );
        Test.stopTest();
        
        
    }
    
    @IsTest
    static void testFindRecordsWithFilter() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        List<sObject> results = EnhancedCustomLookup.findRecords(
            'Test Contact',  // searchKey
            'Contact',       // objectName
            null,           // recdataid
            'Email',        // returnFields
            new List<String>{'LastName'}, // queryFields
            'FirstName',    // displayFields
            'FirstName != null', // filter
            'LastName',     // sortColumn
            '5',            // maxResults
            testAccount.Id  // parentAccountId
        );
        Test.stopTest();
        
        
    }
    
    @IsTest
    static void testFindRecordsWithoutAccountFilter() {
        Test.startTest();
        List<sObject> results = EnhancedCustomLookup.findRecords(
            'Test Contact',  // searchKey
            'Contact',       // objectName
            null,           // recdataid
            'Email',        // returnFields
            new List<String>{'LastName'}, // queryFields
            'FirstName',    // displayFields
            '',             // filter
            'LastName',     // sortColumn
            '5',            // maxResults
            null            // parentAccountId
        );
        Test.stopTest();
        
       
    }
    
    @IsTest
    static void testFetchDefaultRecordForContact() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        sObject result = EnhancedCustomLookup.fetchDefaultRecord(
            testContact.Id, // recordId
            'Contact',      // sObjectApiName
            'Email'         // returnFields
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return the contact record');
        System.assertEquals(testContact.Id, result.Id, 'Should return the correct contact');
    }
    
    @IsTest
    static void testFetchDefaultRecordForCase() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        Test.startTest();
        sObject result = EnhancedCustomLookup.fetchDefaultRecord(
            testCase.Id,    // recordId
            'Case',         // sObjectApiName
            'Subject'       // returnFields
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return the case record');
        System.assertEquals(testCase.Id, result.Id, 'Should return the correct case');
    }
    
    @IsTest
    static void testFetchDefaultRecordWithInvalidId() {
        Test.startTest();
        sObject result = EnhancedCustomLookup.fetchDefaultRecord(
            '001000000000000', // invalid recordId
            'Contact',         // sObjectApiName
            'Email'            // returnFields
        );
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should return null for invalid record ID');
    }
    
    @IsTest
    static void testFindRecordsWithEmptySearchKey() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        List<sObject> results = EnhancedCustomLookup.findRecords(
            '',             // empty searchKey
            'Contact',      // objectName
            null,          // recdataid
            'Email',       // returnFields
            new List<String>{'LastName'}, // queryFields
            'FirstName',   // displayFields
            '',            // filter
            'LastName',    // sortColumn
            '5',           // maxResults
            testAccount.Id // parentAccountId
        );
        Test.stopTest();
        
        System.assert(!results.isEmpty(), 'Should return records even with empty search key');
    }
    
    @IsTest
    static void testFindRecordsWithSpecialCharacters() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        List<sObject> results = EnhancedCustomLookup.findRecords(
            'Test\'s Contact', // searchKey with special character
            'Contact',         // objectName
            null,             // recdataid
            'Email',          // returnFields
            new List<String>{'LastName'}, // queryFields
            'FirstName',      // displayFields
            '',               // filter
            'LastName',       // sortColumn
            '5',              // maxResults
            testAccount.Id    // parentAccountId
        );
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should safely handle special characters in search');
    }
}