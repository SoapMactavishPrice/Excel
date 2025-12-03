@isTest
public with sharing class ProductionSalesControllerTest {

    // Helper method to create a Fiscal Year record
    public static Fiscal_Year__c createFiscalYear(Boolean isActive, Boolean isPlanning) {
        Fiscal_Year__c fy = new Fiscal_Year__c(
            Name = 'FY 2025',
            isActive__c = isActive,
            Is_Planning__c = isPlanning,
            FY_Start_Date__c = Date.today().toStartOfMonth()
        );
        insert fy;
        return fy;
    }

    // Helper method to create test Product Group and Category
    private static Product_Category__c createProductCategory(Boolean isActive) {
        Product_Group__c pg = new Product_Group__c(Name = 'Group A');
        insert pg;

        Product_Category__c pc = new Product_Category__c(
            Name = 'Category A',
            Product_Group__c = pg.Id,
            Is_Active__c = isActive,
            Index__c = 1
        );
        insert pc;
        return pc;
    }

    // Helper method to create Production and related Line Item
    private static Production__c createProductionWithLineItem(Id fyId, Id categoryId) {
        Production__c production = new Production__c(
            Fiscal_Year__c = fyId,
            Product_Category__c = categoryId
        );
        insert production;

        Production_Line_Item__c lineItem = new Production_Line_Item__c(
            Production__c = production.Id,
            Start_Date__c = Date.today().addDays(-1),
            End_Date__c = Date.today().addDays(5),
            Month_Name__c = 'April',
            Opening_Stock__c = 100,
            Domestic_Sales__c = 20,
            Export_Sales__c = 30,
            CC_Sales__c = 10,
            production_Stock__c = 100,
            Actual_Opening_Stock__c = 110,
            Actual_Domestic_Sales__c = 25,
            Actual_Export_Sales__c = 35,
            Actual_CC__c = 12,
            Rate__c = 1.0,
            Actual_Rate__c = 1.1
        );
        insert lineItem;
        return production;
    }

    @isTest
    static void testGetDefaultFilterValues() {
        Fiscal_Year__c fy = createFiscalYear(true, false);
        Test.startTest();
        String result = ProductionSalesController.getDefaultFilterValues();
        System.assertNotEquals(null, result);
        Test.stopTest();
    }

    @isTest
    static void testGetSelectedFiscalYear() {
        Fiscal_Year__c fy = createFiscalYear(false, true);
        Test.startTest();
        String result = ProductionSalesController.getSelectedFiscalYear(fy.Id);
        System.assert(result.contains(fy.Id));
        Test.stopTest();
    }

    @isTest
    static void testGetProductsData() {
        Product_Category__c pc = createProductCategory(true);
        Test.startTest();
        String result = ProductionSalesController.getProductsData();
        System.assert(result.contains(pc.Id));
        Test.stopTest();
    }

    @isTest
    static void testGetProductionDetail() {
        Fiscal_Year__c fy = createFiscalYear(true, false);
        Product_Category__c pc = createProductCategory(true);
        Production__c prod = createProductionWithLineItem(fy.Id, pc.Id);
        Test.startTest();
        String result = ProductionSalesController.getProductionDetail(fy.Id);
        System.assertNotEquals(null, result);
        Test.stopTest();
    }

    @isTest
    static void testStartDateConditionCoverage() {
        Fiscal_Year__c fy = createFiscalYear(true, false);
        Product_Category__c pc = createProductCategory(true);

        // Create production record
        Production__c prod = new Production__c(
            Fiscal_Year__c = fy.Id,
            Product_Category__c = pc.Id
        );
        insert prod;

        // Line item where Start_Date__c >= Today (cover the IF condition)
        Production_Line_Item__c pli = new Production_Line_Item__c(
            Production__c = prod.Id,
            Start_Date__c = System.today(),
            End_Date__c = System.today().addDays(5),
            Month_Name__c = 'April',
            Opening_Stock__c = 100,
           // Closing_Stock__c = 50,
         //   Total_Stock__c = 150,
          //  Total_Sales__c = 60,
            Domestic_Sales__c = 20,
            Export_Sales__c = 30,
            CC_Sales__c = 10,
            production_Stock__c = 100,
            Rate__c = 1.0
        );
        insert pli;

        Test.startTest();
        String result = ProductionSalesController.getProductionDetail(fy.Id);
        System.assertNotEquals(null, result);
        System.assert(result.containsIgnoreCase('CLOSING_STOCK'));
        Test.stopTest();
    }

    @isTest
    static void testSaveMethod() {
        Fiscal_Year__c fy = createFiscalYear(true, false);
        Product_Category__c pc = createProductCategory(true);
        Production__c prod = createProductionWithLineItem(fy.Id, pc.Id);

        List<ProductionSalesController.Production> productionList = new List<ProductionSalesController.Production>();
        ProductionSalesController.Production parent = new ProductionSalesController.Production();
        parent.Id = prod.Id;
        parent.parameterId = pc.Id;

        ProductionSalesController.ProductionLineItem child = new ProductionSalesController.ProductionLineItem();
        child.Id = [SELECT Id FROM Production_Line_Item__c WHERE Production__c = :prod.Id LIMIT 1].Id;
        child.monthName = 'PLAN April';

        parent.childData = new List<ProductionSalesController.ProductionLineItem>{ child };
        productionList.add(parent);

        String jsonData = JSON.serialize(productionList);

        Test.startTest();
        String response = ProductionSalesController.save(jsonData, fy.Id);
        System.assertNotEquals(null, response);
        Test.stopTest();
    }

    @isTest
    static void testSaveMethod_FullCoverage() {
        Fiscal_Year__c fy = createFiscalYear(true, false);
        Product_Category__c pc = createProductCategory(true);
        Production__c prod = createProductionWithLineItem(fy.Id, pc.Id);

        Production_Line_Item__c existingLineItem = [
            SELECT Id FROM Production_Line_Item__c WHERE Production__c = :prod.Id LIMIT 1
        ];

        // PLAN month data
        ProductionSalesController.Production planProduction = new ProductionSalesController.Production();
        planProduction.Id = prod.Id;
        planProduction.parameterId = pc.Id;

        ProductionSalesController.ProductionLineItem planItem = new ProductionSalesController.ProductionLineItem();
        planItem.Id = existingLineItem.Id;
        planItem.monthName = 'PLAN April';
        planItem.Opening_Stock = 100;
        planItem.production_Stock = 50;
        planItem.Domestic_Sales = 20;
        planItem.Export_Sales = 30;
        planItem.CC_Sales = 10;
        planItem.Actual_Opening_Stock = 110;
        planItem.Actual_production_Stock = 55;
        planItem.Actual_Domestic_Sales = 25;
        planItem.Actual_Export_Sales = 35;
        planItem.Actual_CC_Sales = 15;
        planItem.isCurrentMonth = true;
        planItem.ParameterId = pc.Id;

        planProduction.childData = new List<ProductionSalesController.ProductionLineItem>{ planItem };

        // ACTUAL month data
        ProductionSalesController.Production actualProduction = new ProductionSalesController.Production();
        actualProduction.Id = prod.Id;
        actualProduction.parameterId = pc.Id;

        ProductionSalesController.ProductionLineItem actualItem = new ProductionSalesController.ProductionLineItem();
        actualItem.monthName = 'ACTUAL April';
        actualItem.ParameterId = pc.Id;
        actualItem.Actual_Opening_Stock = 90;
        actualItem.Actual_production_Stock = 45;
        actualItem.Actual_Domestic_Sales = 22;
        actualItem.Actual_Export_Sales = 33;
        actualItem.Actual_CC_Sales = 12;
        actualItem.isCurrentMonth = true;

        actualProduction.childData = new List<ProductionSalesController.ProductionLineItem>{ actualItem };

        List<ProductionSalesController.Production> allProductions = new List<ProductionSalesController.Production>{ planProduction, actualProduction };
        String jsonData = JSON.serialize(allProductions);

        Test.startTest();
        String result = ProductionSalesController.save(jsonData, fy.Id);
        System.assertNotEquals(null, result);
        Test.stopTest();
    }
}