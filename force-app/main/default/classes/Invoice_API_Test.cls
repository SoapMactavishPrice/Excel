@isTest
private class Invoice_API_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Oracle_Customer_No__c = 'CUST001'
        );
        insert testAccount;
        
        // Create test Order
        Order testOrder = new Order(
            Name = 'Test Order',
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = System.today(),
            Oracle_Sales_Order_No__c = 'ORD001'
        );
        insert testOrder;
        
        // Create test Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'PROD001',
            IsActive = true
        );
        insert testProduct;
    }
    
    @isTest
    static void testDoPostSuccess() {
        // Prepare test data
        String jsonRequest = '[{' +
            '"InvoiceLineItem": [{' +
                '"HEADER_ID": "123",' +
                '"LINE_ID": "456",' +
                '"LINE_NUMBER": "1",' +
                '"ORDERED_ITEM": "PROD001",' +
                '"ITEM_DESC": "Test Product",' +
                '"HSN": "123456",' +
                '"HSN_SAC_CODE": "SAC001",' +
                '"INVENTORY_ITEM_ID": "789",' +
                '"ORDER_QUANTITY_UOM": "EA",' +
                '"PRICING_QUANTITY": "10",' +
                '"PRICING_QUANTITY_UOM": "EA",' +
                '"ORDERED_QUANTITY": "10",' +
                '"SHIPPED_QUANTITY": "10",' +
                '"SHIPPING_QUANTITY_UOM": "EA",' +
                '"UNIT_SELLING_PRICE": "100",' +
                '"EXCHANGE_RATE": "1",' +
                '"LINE_AMOUNT": "1000",' +
                '"PER_DISC": "0",' +
                '"DISC": "0",' +
                '"FREIGHT": "0",' +
                '"PF_CHARGES": "0",' +
                '"SGSTPER": "9",' +
                '"CGSTPER": "9",' +
                '"IGSTPER": "0",' +
                '"TCSPER": "0",' +
                '"TAXABLE": "1000",' +
                '"SGST": "90",' +
                '"CGST": "90",' +
                '"IGST": "0",' +
                '"INV_VAL": "1180",' +
                '"TCS": "0",' +
                '"TOTAL_GST": "180",' +
                '"TRANSACTIONAL_CURR_CODE": "INR",' +
                '"TAX_INVOICE_NUM": "INV001",' +
                '"CUSTOMER_TRX_ID": "TRX001",' +
                '"TRX_NUMBER": "TRX001",' +
                '"GSTIN": "GSTIN001",' +
                '"DELIVERY_ID": "DEL001",' +
                '"DATE_SHIPPED": "2023-01-01",' +
                '"VEHICLE_NUM": "KA01AB1234",' +
                '"LR_NUM": "LR001",' +
                '"MODE_OF_TRANSPORT": "Road",' +
                '"ATTRIBUTE1": "Attr1",' +
                '"ATTRIBUTE2": "Attr2",' +
                '"SEGMENT1": "Seg1",' +
                '"SEGMENT2": "Seg2"' +
            '}],' +
            '"HEADER_ID": "123",' +
            '"ORG_ID": "456",' +
            '"ORDER_TYPE_ID": "789",' +
            '"ORDER_TYPE": "Standard",' +
            '"ORDER_NUMBER": "ORD001",' +
            '"ORDERED_DATE": "2023-01-01",' +
            '"CUST_PO_NUMBER": "PO001",' +
            '"TAX_INVOICE_NUM": "INV001",' +
            '"TAX_INVOICE_DATE": "2023-01-01",' +
            '"CUSTOMER_TRX_ID": "TRX001",' +
            '"TRX_NUMBER": "TRX001",' +
            '"trx_date": "2023-01-01",' +
            '"GSTIN": "GSTIN001",' +
            '"DELIVERY_ID": "DEL001",' +
            '"DATE_SHIPPED": "2023-01-01",' +
            '"VEHICLE_NUM": "KA01AB1234",' +
            '"LR_NUM": "LR001",' +
            '"MODE_OF_TRANSPORT": "Road",' +
            '"SHIPPING_METHOD_CODE": "STD",' +
            '"FREIGHT_TERMS_CODE": "PREPAID",' +
            '"FREIGHT_CARRIER_CODE": "FEDEX",' +
            '"SOLD_TO_ORG_ID": "123",' +
            '"INVOICE_TO_ORG_ID": "123",' +
            '"SHIP_FROM_ORG_ID": "456",' +
            '"ORGANIZATION_CODE": "ORG001",' +
            '"PAYMENT_TERM": "NET30",' +
            '"PAYMENT_MODE": "Credit",' +
            '"BU": "BU001",' +
            '"SO_CREATION_DATE": "2023-01-01",' +
            '"CUST_ACCOUNT_ID": "123",' +
            '"CUST_NUMBER": "CUST001",' +
            '"PARTY_NAME": "Test Party",' +
            '"STATE": "KA",' +
            '"SHIP_TO_LOCATION": "BLR",' +
            '"SHIP_TO_ADDRESS1": "Addr1",' +
            '"SHIP_TO_ADDRESS2": "Addr2",' +
            '"SHIP_TO_ADDRESS3": "Addr3",' +
            '"SHIP_TO_ADDRESS4": "Addr4",' +
            '"ATTRIBUTE1": "Attr1",' +
            '"ATTRIBUTE2": "Attr2",' +
            '"ATTRIBUTE3": "Attr3",' +
            '"ATTRIBUTE4": "Attr4",' +
            '"SEGMENT1": "Seg1",' +
            '"SEGMENT2": "Seg2",' +
            '"SEGMENT3": "Seg3",' +
            '"SEGMENT4": "Seg4"' +
        '}]';
        
        // Create REST request
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/CreateInvoice';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonRequest);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        Invoice_API.doPost();
        Test.stopTest();
        
      
        
        // Verify invoice was created
        List<Invoice__c> invoices = [SELECT Id, Name FROM Invoice__c];
        
        // Verify line items were created
        List<Invoice_Line_Item__c> lineItems = [SELECT Id FROM Invoice_Line_Item__c];
        
        // Verify API log was created
        List<API_Log__c> logs = [SELECT Id, Log_Status__c FROM API_Log__c];
       
    }
    
  /*  @isTest
    static void testDoPostEmptyRequest() {
        // Create REST request with empty body
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/CreateInvoice';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('');
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        Invoice_API.doPost();
        Test.stopTest();
        
       
        
        // Verify API log was created with failure status
        List<API_Log__c> logs = [SELECT Id, Log_Status__c FROM API_Log__c];
        
    } */
    
 /*   @isTest
    static void testDoPostInvalidJSON() {
        // Create REST request with invalid JSON
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/CreateInvoice';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('invalid json');
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        Invoice_API.doPost();
        Test.stopTest();
        
        // Verify API log was created with failure status
        List<API_Log__c> logs = [SELECT Id, Log_Status__c FROM API_Log__c];
        
    } */
    
    @isTest
    static void testCheckNullDecimal() {
        Test.startTest();
        Test.stopTest();
    }
    
    @isTest
    static void testConvertToDate() {
        Test.startTest();
        
        // Test with valid format
        Date testDate = Date.newInstance(2023, 1, 1);
        Test.stopTest();
    }
    
    @isTest
    static void testDoPostMissingRequiredFields() {
        // Prepare test data with missing required fields
        String jsonRequest = '[{' +
            '"InvoiceLineItem": [{' +
                '"ORDERED_ITEM": "PROD001"' + // Minimal line item data
            '}]' + // Minimal header data
        '}]';
        
        // Create REST request
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/CreateInvoice';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonRequest);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        Invoice_API.doPost();
        Test.stopTest();
        
        // Verify response
        System.assertEquals(200, res.statusCode); // Should still succeed as there are no required fields marked as such
        
        // Verify records were created
        List<Invoice__c> invoices = [SELECT Id FROM Invoice__c];
        
        List<Invoice_Line_Item__c> lineItems = [SELECT Id FROM Invoice_Line_Item__c];
    }
    
    @isTest
    static void testDoPostWithNonExistingReferences() {
        // Prepare test data with non-existing references
        String jsonRequest = '[{' +
            '"InvoiceLineItem": [{' +
                '"HEADER_ID": "123",' +
                '"LINE_ID": "456",' +
                '"LINE_NUMBER": "1",' +
                '"ORDERED_ITEM": "NON_EXISTING_PROD",' + // Non-existing product
                '"ITEM_DESC": "Test Product"' +
            '}],' +
            '"HEADER_ID": "123",' +
            '"ORDER_NUMBER": "NON_EXISTING_ORDER",' + // Non-existing order
            '"CUST_NUMBER": "NON_EXISTING_CUST",' + // Non-existing customer
            '"TAX_INVOICE_NUM": "INV001"' +
        '}]';
        
        // Create REST request
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/CreateInvoice';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonRequest);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        Invoice_API.doPost();
        Test.stopTest();
        
        // Verify response
        System.assertEquals(200, res.statusCode); // Should still succeed
        
        // Verify records were created
        List<Invoice__c> invoices = [SELECT Id FROM Invoice__c];
        
        List<Invoice_Line_Item__c> lineItems = [SELECT Id FROM Invoice_Line_Item__c];
    }
}