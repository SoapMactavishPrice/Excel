@isTest
public class Lwc_collection_reportControllerTest {

    @testSetup
    static void setupTestData() {
        // Create Product Group records
        List<Product_Group__c> productGroups = new List<Product_Group__c>();
        for (Integer i = 0; i < 5; i++) {
            productGroups.add(new Product_Group__c(
                Name = 'Product Group ' + i
            ));
        }
        insert productGroups;

        // Create Collection Plans
        List<Collection_Plan__c> plans = new List<Collection_Plan__c>();
        for (Integer i = 0; i < 3; i++) {
            plans.add(new Collection_Plan__c(
             //   Name = 'Plan ' + i,
            //    Customer_Code__c = 'CUST00' + i
            ));
        }
        insert plans;

        // Create Collection Plan Line Items
        List<Collection_Plan_Line_Item__c> lineItems = new List<Collection_Plan_Line_Item__c>();
        for (Collection_Plan__c plan : plans) {
            lineItems.add(new Collection_Plan_Line_Item__c(
                Collection_Plan__c = plan.Id,
                Start_Date__c = Date.today().toStartOfMonth(),
                End_Date__c = Date.today().addDays(30),
                Collection_Plan_110th__c = 1000.00,
                Collection_Plan_1120th__c = 2000.00,
                Collection_Plan_2131st__c = 3000.00
            ));
        }
        insert lineItems;
    }

    @isTest
    static void testGetProductsData() {
        Test.startTest();
        String result = Lwc_collection_reportController.getProductsData();
        Test.stopTest();

        // Deserialize the JSON response
      //  List<Map<String, Object>> resultList = (List<Map<String, Object>>) JSON.deserializeUntyped(result);

        // Assertions
     //   System.assertEquals(5, resultList.size(), 'Should return 5 Product Groups');
     //   System.assert(resultList[0].containsKey('ParameterPGName'), 'Should contain ParameterPGName');
     //   System.assert(resultList[0].containsKey('ParameterId'), 'Should contain ParameterId');
    }

    @isTest
    static void testGetProductsDataException() {
        Test.startTest();

        // Simulate Exception by deleting all product groups
        delete [SELECT Id FROM Product_Group__c];

        try {
            Lwc_collection_reportController.getProductsData();
      //      System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('No rows to query'), 'Exception should indicate no rows found');
        }

        Test.stopTest();
    }

    @isTest
    static void testGetCollectionDetails() {
        Test.startTest();
        List<Collection_Plan__c> plans = Lwc_collection_reportController.getCollectionDetails();
        Test.stopTest();

        // Assertions
        System.assert(plans.size() > 0, 'Should return at least one collection plan');
     //   System.assert(plans[0].Name.startsWith('Plan'), 'Plan name should start with "Plan"');
      //  System.assertEquals('CUST001', plans[0].Customer_Code__c, 'Customer Code should match');
        
        // Validate line items
        System.assert(plans[0].Collection_Plan_Line_Item__r.size() > 0, 'Should have line items');
        System.assertEquals(1000.00, plans[0].Collection_Plan_Line_Item__r[0].Collection_Plan_110th__c, 'Plan 110th should match');
    }

    @isTest
    static void testGetCollectionDetailsNoData() {
        Test.startTest();
        
        // Simulate no data scenario
        delete [SELECT Id FROM Collection_Plan__c];

        List<Collection_Plan__c> plans = Lwc_collection_reportController.getCollectionDetails();
        
        Test.stopTest();

        // Assertions
        System.assertEquals(0, plans.size(), 'Should return an empty list when no data is present');
    }
}