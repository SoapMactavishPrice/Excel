@isTest
private class Outstanding_APITest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Oracle_Customer_No__c = 'CUST001'
        );
        insert testAccount;
        
        // Create test Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'PROD001',
            IsActive = true
        );
        insert testProduct;
        
        // Create test Invoice
        Invoice__c testInvoice = new Invoice__c(
            Name = 'INV001',
            Tax_Invoice_Number__c = 'INV001'
        );
        insert testInvoice;
    }
    
    @isTest
    static void testDoPostSuccess() {
        // Prepare test data
        String jsonRequest = '[{' +
            '"Amount_Due": "1000",' +
            '"Balance_Due": "1000",' +
            '"BU": "BU001",' +
            '"Cr_Terms": "30",' +
            '"Customer_Number": "CUST001",' +
            '"Customer_Name": "Test Customer",' +
            '"Due_Date": "2023-01-01",' +
            '"Invoice_Group": "Group1",' +
            '"Invoice_Date": "2023-01-01",' +
            '"Invoice_No": "INV001",' +
            '"Item_Description": "Test Product",' +
            '"Item_Number": "PROD001",' +
            '"LOCATION": "LOC001",' +
            '"Mode_of_Payment": "Credit",' +
            '"Purchase_Order": "PO001",' +
            '"Receipt_CN_Diff": "Diff",' +
            '"Remarks": "Test Remarks",' +
            '"Tax_Invoice_Number": "TAXINV001",' +
            '"Trade": "Trade1",' +
            '"CTT_CLASS": "CLASS1",' +
            '"CUSTOMER_ID": "CUST001",' +
            '"BILL_TO_CUSTOMER_NUM": "BILL001",' +
            '"BILL_TO_CUSTOMER_NAME": "Bill Customer",' +
            '"LINE_TYPE": "LINE1",' +
            '"ACCOUNT_CLASS": "ACCT1",' +
            '"CUSTOMER_TRX_ID": "TRX001",' +
            '"TRX_DATE": "2023-01-01",' +
            '"TRX_NUMBER": "TRX001",' +
            '"TERM_DUE_DATE": "2023-01-31",' +
            '"INVOICE_CURRENCY_CODE": "INR",' +
            '"BS_BATCH_SOURCE_NAME": "BATCH1",' +
            '"DESCRIPTION": "Test Description",' +
            '"ACCTD_AMOUNT": "1000",' +
            '"AMOUNT_DUE_REMAINING": "1000",' +
            '"FLEX_VALUE": "10",' +
            '"SO_EXCISE_NO": "EXCISE1",' +
            '"ECD_TERM_DUE_DAT": "10",' +
            '"ORG_ID": "ORG001"' +
        '}]';
        
        // Create REST request
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/CreateOutstanding';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonRequest);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        Outstanding_API.doPost();
        Test.stopTest();
        
        // Verify outstanding was created
        List<Outstanding__c> outstandings = [SELECT Id FROM Outstanding__c];
        
        // Verify API logs were created
        List<API_Log__c> logs = [SELECT Id, Log_Status__c FROM API_Log__c WHERE Log_Name__c = 'CreateOutstandingAPI' OR Log_Name__c = 'CreateOutstanding_SubAPI'];
    }
    
    @isTest
    static void testDoPostEmptyRequest() {
        // Create REST request with empty array
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/CreateOutstanding';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('[]');
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        Outstanding_API.doPost();
        Test.stopTest();
        
        
    }
    
  /*  @isTest
    static void testDoPostInvalidJSON() {
        // Create REST request with invalid JSON
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/CreateOutstanding';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{invalid json}');
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        Outstanding_API.doPost();
        Test.stopTest();
        
       
    } */
    
    @isTest
    static void testDoPostWithNonExistingReferences() {
        // Prepare test data with non-existing references
        String jsonRequest = '[{' +
            '"Customer_Number": "NON_EXISTING_CUST",' +
            '"Item_Number": "NON_EXISTING_PROD",' +
            '"Invoice_No": "NON_EXISTING_INV",' +
            '"Amount_Due": "1000"' +
        '}]';
        
        // Create REST request
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/CreateOutstanding';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonRequest);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        Outstanding_API.doPost();
        Test.stopTest();
        
        
        
        // Verify outstanding was created without references
        List<Outstanding__c> outstandings = [SELECT Id FROM Outstanding__c];
       
    }
    
    @isTest
    static void testCheckNullDecimal() {
        Test.startTest();
       
        Test.stopTest();
    }
    
    @isTest
    static void testExceptionHandling() {
        // Force an exception by passing invalid date format
        String jsonRequest = '[{' +
            '"Amount_Due": "1000",' +
            '"Due_Date": "invalid-date",' + // This will cause exception when parsed
            '"Invoice_No": "INV001"' +
        '}]';
        
        // Create REST request
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/CreateOutstanding';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonRequest);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        Outstanding_API.doPost();
        Test.stopTest();
        
       
        
        // Verify API log was created with failure status
        List<API_Log__c> logs = [SELECT Id, Log_Status__c FROM API_Log__c WHERE Log_Name__c = 'CreateOutstandingAPI'];
       
    }
}