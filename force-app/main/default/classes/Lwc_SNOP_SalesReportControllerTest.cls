@isTest
public class Lwc_SNOP_SalesReportControllerTest {

    // Common setup method
    private static Production__c createTestProductionData() {
        Product_Group__c productGroup = new Product_Group__c(Name = 'Test Product Group');
        insert productGroup;

        Product_Category__c productCategory = new Product_Category__c(
            Name = 'Test Category', 
            Product_Group__c = productGroup.Id
        );
        insert productCategory;

        Production__c production = new Production__c(
            Product_Category__c = productCategory.Id
        );
        insert production;

        return production;
    }

    @isTest
    public static void testGetProductsData() {
        Product_Group__c productGroup = new Product_Group__c(Name = 'Test Product Group');
        insert productGroup;

        Test.startTest();
        String result = Lwc_SNOP_SalesReportController.getProductsData();
        Test.stopTest();

        System.assertNotEquals(null, result, 'The result should not be null');
    }

    @isTest
    public static void testGetSalesDetail() {
        Production__c production = createTestProductionData();

        List<Production_Line_Item__c> lineItems = new List<Production_Line_Item__c>{
            new Production_Line_Item__c(
                Production__c = production.Id,
                Start_Date__c = System.today().addDays(1), // Future month
                End_Date__c = System.today().addDays(30),
                Domestic_Sales__c = 100,
                Production_Stock__c = 200,
                Rate__c = 50,
              //  Sales_Value__c = 5000,
                Month_Name__c = 'March'
            ),
            new Production_Line_Item__c(
                Production__c = production.Id,
                Start_Date__c = System.today().addDays(-1), // Current month
                End_Date__c = System.today().addDays(30),
                Domestic_Sales__c = 150,
                Production_Stock__c = 250,
                Actual_Domestic_Sales__c = 120,
                Actual_Production__c = 220,
                Rate__c = 60,
              //  Sales_Value__c = 6000,
                Actual_Rate__c = 55,
              //  Actual_Sales_Value__c = 6600,
                Month_Name__c = 'April'
            )
        };
        insert lineItems;

        Test.startTest();
        String result = Lwc_SNOP_SalesReportController.getSalesDetail(String.valueOf(production.Id));
        Test.stopTest();

        System.assertNotEquals(null, result, 'The result should not be null');

        // Deserialize the response into a list of maps
        List<Object> responseList = (List<Object>) JSON.deserializeUntyped(result);
        System.assert(responseList.size() > 0, 'There should be production data');

        Map<String, Object> firstItem = (Map<String, Object>) responseList[0];
        System.assert(firstItem.containsKey('childData'), 'Should contain child data');

        List<Object> childData = (List<Object>) firstItem.get('childData');
        System.assert(childData.size() == 3, 'There should be 3 child maps (1 future, 1 plan, 1 actual)');

        Map<String, Object> child1 = (Map<String, Object>) childData[0];
       

        Map<String, Object> child2 = (Map<String, Object>) childData[1];
     

        Map<String, Object> child3 = (Map<String, Object>) childData[2];
       
    }

    @isTest
    public static void testGetSaleSave() {
        Production__c production = createTestProductionData();

        Production_Line_Item__c lineItem = new Production_Line_Item__c(
            Production__c = production.Id,
            Start_Date__c = System.today().addDays(-1),
            End_Date__c = System.today().addDays(30),
            Domestic_Sales__c = 100,
            Production_Stock__c = 200,
            Actual_Domestic_Sales__c = 90,
            Actual_Production__c = 190,
            Rate__c = 50,
            Actual_Rate__c = 45,
            Month_Name__c = 'March'
        );
        insert lineItem;

        String jsonData = '[{' +
            '"ParameterId":"' + lineItem.Id + '", ' +
            '"monthName":"ACTUAL March", ' +
            '"Domestic_Sales":100, ' +
            '"Production":200, ' +
            '"rate":55, ' +
            '"salesValue":5500' +
        '}]';

        Test.startTest();
        String result = Lwc_SNOP_SalesReportController.getSaleSave(jsonData);
        Test.stopTest();

        System.assertEquals('Success', result, 'The save operation should return Success');

        Production_Line_Item__c updatedLineItem = [
            SELECT Actual_Rate__c, Actual_Sales_Value__c 
            FROM Production_Line_Item__c 
            WHERE Id = :lineItem.Id
        ];
        System.assertEquals(55, updatedLineItem.Actual_Rate__c, 'Actual rate should be updated');
    }

    @isTest
    public static void testGetSaleSaveForPlanRecords() {
        Production__c production = createTestProductionData();

        Production_Line_Item__c lineItem = new Production_Line_Item__c(
            Production__c = production.Id,
            Start_Date__c = System.today().addDays(1),
            End_Date__c = System.today().addDays(30),
            Domestic_Sales__c = 100,
            Production_Stock__c = 200,
            Rate__c = 50,
            Month_Name__c = 'March'
        );
        insert lineItem;

        String jsonData = '[{' +
            '"ParameterId":"' + lineItem.Id + '", ' +
            '"monthName":"March", ' +
            '"Domestic_Sales":100, ' +
            '"Production":200, ' +
            '"rate":55, ' +
            '"salesValue":5500' +
        '}]';

        Test.startTest();
        String result = Lwc_SNOP_SalesReportController.getSaleSave(jsonData);
        Test.stopTest();

        System.assertEquals('Success', result, 'The save operation should return Success');

        Production_Line_Item__c updatedLineItem = [
            SELECT Rate__c, Sales_Value__c 
            FROM Production_Line_Item__c 
            WHERE Id = :lineItem.Id
        ];
        System.assertEquals(55, updatedLineItem.Rate__c, 'Plan rate should be updated');
    }

    @isTest
    public static void testErrorHandlingInGetSaleSave() {
        String invalidData = '[{"ParameterId":"INVALID_ID", "monthName":"ACTUAL March", "Domestic_Sales":100, "Production":200, "Rate":50, "SalesValue":5000}]';

        Test.startTest();
        try {
            String result = Lwc_SNOP_SalesReportController.getSaleSave(invalidData);
            System.assertNotEquals('Success', result, 'Should not return Success for invalid data');
        } catch (Exception e) {
            System.assert(false, 'Should handle invalid data gracefully without throwing exception');
        }
        Test.stopTest();
    }

    @isTest
    public static void testEmptyInputForGetSaleSave() {
        Test.startTest();
        try {
            String result = Lwc_SNOP_SalesReportController.getSaleSave('');
            System.assertNotEquals('Success', result, 'Should not return Success for empty input');
        } catch (Exception e) {
            System.assert(false, 'Should handle empty input gracefully without throwing exception');
        }
        Test.stopTest();
    }
}