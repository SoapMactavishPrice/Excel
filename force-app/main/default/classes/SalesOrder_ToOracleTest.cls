@isTest
public class SalesOrder_ToOracleTest {
    
    // Mock HTTP Callout Class
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success","message":"Order Created Successfully"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    // Mock HTTP Failure Class
    public class MockHttpFailureGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"error","message":"Failed to create order"}');
            res.setStatusCode(500);
            return res;
        }
    }
    
    @testSetup
    static void setup() {
        
    }
    
    @isTest
    static void testCreateSalesOrderData_Success() {
        // Register mock response for successful callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        String result = SalesOrder_ToOracle.createSalesOrderData('SO123');
        Test.stopTest();
        
        
        List<API_Log__c> logs = [SELECT Id, Log_Status__c, Response_Code__c FROM API_Log__c WHERE Log_Name__c = 'SalesOrder_ToOracle'];
        
    }
    
    @isTest
    static void testCreateSalesOrderData_Failure() {
        // Register mock response for failed callout
        Test.setMock(HttpCalloutMock.class, new MockHttpFailureGenerator());
        
        Test.startTest();
        String result = SalesOrder_ToOracle.createSalesOrderData('SO124');
        Test.stopTest();
        
        
        List<API_Log__c> logs = [SELECT Id, Log_Status__c, Response_Code__c FROM API_Log__c WHERE Log_Name__c = 'SalesOrder_ToOracle'];
        
    }
    
    @isTest
    static void testCreateSalesOrderData_Exception() {
        
        
        Test.startTest();
        String result = SalesOrder_ToOracle.createSalesOrderData('SO125');
        Test.stopTest();
        
        
        List<API_Log__c> logs = [SELECT Id, Log_Status__c, Response_Code__c, Exception_Description__c FROM API_Log__c WHERE Log_Name__c = 'SalesOrder_ToOracle'];
        
    }
    @isTest
    static void testCreateJSONrequestHardCode() {
        // Create a test Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create a test Contract (needed to create Order)
        Contract contract = new Contract(AccountId = acc.Id, StartDate = Date.today());
        insert contract;
        
        // Create a test Order
        Order ord = new Order(
            Name = 'Test Order',
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            ContractId = contract.Id
        );
        insert ord;
        
        // Create a test Product
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;
        
        // Create a Pricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook; 
        
        // Create PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        
        // Create OrderItem
        OrderItem ordItem = new OrderItem(
            OrderId = ord.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pbe.Id
        );
        //  insert ordItem;
        
        // Call the method
        Test.startTest();
        String jsonResult = SalesOrder_ToOracle.createJSONrequestHardCode(ord.Id);
        Test.stopTest();
        
        
    }
    @isTest
    static void testCreateJSONrequest() {
        // Create related city and postal code
        Country__c country = new Country__c(Name = 'India');
        insert country;
        State__c state = new State__c(Name = 'Maharashtra', Country__c = country.Id);
        insert state;
        City__c city = new City__c(Name = 'New York',State__c = state.Id);
        insert city;
        
        Postal_Code__c postalCode = new Postal_Code__c(Name = '10001', Country__c = country.Id , State__c = state.Id , City__c = city.Id);
        insert postalCode;
        
        // Create Account
        Account acc = new Account(
            Name = 'Test Account',
            Type = 'Business',
            Customer_Code__c = 'CUST123'
        );
        insert acc;
        
        // Create Bill To & Ship To Parties
        Address_Information__c billTo = new Address_Information__c(
            Name = 'Bill To Party',
            Address_1__c = '123 Main St',
            Address_2__c = 'Suite 100',
            City__c = city.Id,
            Postal_Code__c = postalCode.Id,
            Oracle_Site_Code__c = 'BILL123',
            GST__c = 'GJ1234'
        );
        insert billTo;
        
        Address_Information__c shipTo = new Address_Information__c(
            Name = 'Ship To Party',
            Address_1__c = '456 Side St',
            Address_2__c = 'Suite 200',
            City__c = city.Id,
            Postal_Code__c = postalCode.Id,
            Oracle_Site_Code__c = 'SHIP123',
            GST__c = 'GJ5678'
        );
        insert shipTo;
        
        // Create Operating Unit
      //  Operating_Unit__c ou = new Operating_Unit__c(Name = 'Test OU', Operating_Unit_ID__c = 'OU123');
      //  insert ou;
        
        // Create Payment Term
        Payment_Term__c pt = new Payment_Term__c(Name = '30 Days', Payment_Term_Id__c = 'PT001');
        insert pt;
        
        // Create Organization Name
     //   Organization_Name__c org = new Organization_Name__c(Name = 'Test Org', Organization_Id__c = 'WH001');
     //   insert org;
        
        // Create Order Type
        Order_Type__c ot = new Order_Type__c(Name = 'Standard', Order_Type_Id__c = 'OT001');
        insert ot;
        
        // Create Order
        Order ord = new Order(
            Name = 'SO-001',
            AccountId = acc.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Payment_Term__c = pt.Id,
           // Warehouse__c = org.Id,
           // Operating_Unit__c = ou.Id,
            CurrencyIsoCode = 'USD',
            PoNumber = 'PO1234',
            Dispatcher_Information__c = 'Dispatch Info',
            Requested_Delivery_Date__c = Date.today().addDays(5),
            Promised_Delivery_Date__c = Date.today().addDays(10),
            External_Document_No__c = 'EXTDOC123',
            Your_Reference__c = 'REF001',
            Po_Received_Date__c = Date.today(),
            Bill_to_Party__c = billTo.Id,
            Ship_to_Party__c = shipTo.Id,
            Bill_To_Name__c = 'Bill To Name',
            Bill_To_Contact__c = 'John Doe',
            Ship_To_Name__c = 'Ship To Name',
            Ship_To_Contact__c = 'Jane Doe',
            Sell_To_Contact__c = 'Sales Rep',
            Sell_To_Email__c = 'sales@example.com',
            Sell_To_Phone_No__c = '1234567890',
            Payment_Term_Code__c = 'PTC001',
            Short_Closed__c = false,
            Order_Type__c = ot.Id,
            Description = 'Order description',
            Comment__c = 'Urgent order',
            Status='Draft',
            EffectiveDate= Date.today()
        );
        insert ord;
        
        // Create Product
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            IsActive = true,
            Inventory_Item_Id__c = 'INV001',
            Primary_UOM_Code__c = 'FT',
            Secondary_UOM_Code__c = 'FT'
          //  Organization_Name__c = org.Id
          //  Product_Type__c = 'Equipment'
        );
        insert prod;
        
        // Create PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            UnitPrice = 100,
            CurrencyIsoCode='USD',
            IsActive = true
        );
        insert pbe;
        
        // Create OrderItem
        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            Quantity = 2,
            UnitPrice = 100,
            PricebookEntryId = pbe.Id,
            Product2Id = prod.Id,
            Quantity_2__c = 1.5,
            Unit_Selling_Price__c = 95,
            Pricing_Quantity__c = 2,
            Requested_Delivery_Date__c = Date.today().addDays(6),
            Promised_Delivery_Date__c = Date.today().addDays(11),
            Type__c = 'Standard',
            FOC__c = false,
            Product_Type__c = 'Equipment',
            Remarks__c = 'Handle with care',
            Comment__c = 'Deliver before noon',
            Short_Closed__c = false
           
           
        );
        insert oi;
        
        Test.startTest();
        String jsonOutput = SalesOrder_ToOracle.createJSONrequest(ord.Id); // Replace 'YourClassName' with actual class name
       
        Test.stopTest();
    }
}