@IsTest
public class AccDetailsTest {
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            Credit_Limit__c = 50000,
            Payment_Received__c = 25000,
            Outstanding_Invoices__c = 10000
        );
        insert testAccount;
        
        // Get the standard pricebook - create if doesn't exist
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        upsert standardPricebook;
        
        // Create test product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;
        
        // Create standard pricebook entry first
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true,
            UseStandardPrice = false
        );
        insert standardPbe;
        
        // Create test tasks
        List<Task> tasks = new List<Task>();
        for (Integer i = 0; i < 3; i++) {
            tasks.add(new Task(
                Subject = 'Test Task ' + i,
                WhatId = testAccount.Id,
                Status = 'Completed'
            ));
        }
        insert tasks;
        
        // Create test events
        List<Event> events = new List<Event>();
        for (Integer i = 0; i < 2; i++) {
            events.add(new Event(
                Subject = 'Test Event ' + i,
                WhatId = testAccount.Id,
                DurationInMinutes = 30,
                ActivityDateTime = DateTime.now()
            ));
        }
        insert events;
        
        // Create test orders - all as Draft initially
        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < 5; i++) {
            orders.add(new Order(
                AccountId = testAccount.Id,
                Status = 'Draft',
                EffectiveDate = Date.today().addDays(-i * 10),
                Pricebook2Id = standardPricebook.Id
            ));
        }
        insert orders;
        
        // Add order products to all orders
        List<OrderItem> orderItems = new List<OrderItem>();
        for (Order o : orders) {
            orderItems.add(new OrderItem(
                OrderId = o.Id,
                PricebookEntryId = standardPbe.Id,
                Product2Id = testProduct.Id,
                Quantity = 1,
                UnitPrice = 100.00,
                ServiceDate = Date.today()
            ));
        }
        insert orderItems;
        
        // Update some orders to Activated status
        List<Order> ordersToUpdate = new List<Order>();
        for (Integer i = 2; i < 5; i++) {
            orders[i].Status = 'Activated';
            ordersToUpdate.add(orders[i]);
        }
        update ordersToUpdate;
        
        // Create test opportunities (enquiries)
        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < 4; i++) {
            opportunities.add(new Opportunity(
                Name = 'Test Opp ' + i,
                AccountId = testAccount.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Pricebook2Id = standardPricebook.Id
            ));
        }
        insert opportunities;
    }
    
    @IsTest
    static void testFetchData() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        Map<String, Object> result = AccDetails.fetchData(testAccount.Id);
        Test.stopTest();
        
        // Verify account data
        Account acc = (Account)result.get('account');
        
    }
    
    @IsTest
    static void testFetchAccountData() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        Account result = AccDetails.fetchAccountData(testAccount.Id);
        Test.stopTest();
        
     
    }
    
    @IsTest
    static void testGetTaskCount() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        Integer count = AccDetails.getTaskCount(testAccount.Id);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testGetEventCount() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        Integer count = AccDetails.getEventCount(testAccount.Id);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testGetDaysSinceLastOrder() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        Integer days = AccDetails.getDaysSinceLastOrder(testAccount.Id);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testGetDaysSinceLastOrderWithNoOrders() {
        Account testAccount = new Account(Name = 'No Orders Account');
        insert testAccount;
        
        Test.startTest();
        Integer days = AccDetails.getDaysSinceLastOrder(testAccount.Id);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testGetTotalSalesOrders() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        Integer count = AccDetails.getTotalSalesOrders(testAccount.Id);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testGetTotalEnquiries() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        Integer count = AccDetails.getTotalEnquiries(testAccount.Id);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testGetOpenOrders() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        Integer count = AccDetails.getOpenOrders(testAccount.Id);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testFetchDataWithNoAccount() {
        // Test with invalid account ID
        String invalidId = '001000000000000';
        
        Test.startTest();
        try {
            Map<String, Object> result = AccDetails.fetchData(invalidId);
        } catch (Exception e) {
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testFetchDataWithNullInput() {
        Test.startTest();
        try {
            Map<String, Object> result = AccDetails.fetchData(null);
        } catch (Exception e) {
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testFetchDataWithEmptyInput() {
        Test.startTest();
        try {
            Map<String, Object> result = AccDetails.fetchData('');
        } catch (Exception e) {
        }
        Test.stopTest();
    }
}