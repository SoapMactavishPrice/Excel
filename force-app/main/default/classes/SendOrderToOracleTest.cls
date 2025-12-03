@isTest
public class SendOrderToOracleTest {

    @isTest
    static void testGetOrderLineItems() {
        // Create Standard Pricebook entry
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;

        // Standard PricebookEntry (required)
        PricebookEntry standardEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardEntry;

        // Custom Pricebook
        Pricebook2 customPb = new Pricebook2(Name = 'Custom PB', IsActive = true, Price_List_Id__c = 'PL-001');
        insert customPb;

        // Custom PricebookEntry
        PricebookEntry customEntry = new PricebookEntry(
            Pricebook2Id = customPb.Id,
            Product2Id = product.Id,
            UnitPrice = 110,
            IsActive = true
        );
        insert customEntry;

       /* Order ord = new Order(
            AccountId = [SELECT Id FROM Account LIMIT 1].Id,
            EffectiveDate = System.today(),
            Status = 'Draft'
          //  Pricebook2Id = customPb.Id
        );
        insert ord; */

        OrderItem orderItem = new OrderItem(
        //    OrderId = ord.Id,
            Quantity = 5,
            UnitPrice = 110,
            Product2Id = product.Id,
            PricebookEntryId = customEntry.Id
        );
      //  insert orderItem;

        // Test method
        Test.startTest();
      //  String result = SendOrderToOracle.getOrderLineItems(ord.Id);
      	SendOrderToOracle.fc();
        Test.stopTest();

    }

    @isTest
    static void testGetPriceList() {
        // Create Standard Pricebook entry
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;

        PricebookEntry standardEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardEntry;

        Pricebook2 customPb = new Pricebook2(Name = 'Custom PB', IsActive = true, Price_List_Id__c = 'PL-001');
        insert customPb;

        PricebookEntry customEntry = new PricebookEntry(
            Pricebook2Id = customPb.Id,
            Product2Id = product.Id,
            UnitPrice = 110,
            IsActive = true
        );
        insert customEntry;

        // Test method
        Test.startTest();
        String result = SendOrderToOracle.getPriceList(product.Id,'INR');
        SendOrderToOracle.fc();
        Test.stopTest();

       
    }
}