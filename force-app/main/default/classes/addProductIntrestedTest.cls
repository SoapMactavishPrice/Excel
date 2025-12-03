@isTest
public class addProductIntrestedTest {
    
    private static Lead createTestLead(Id cityId, Id stateId, Id countryId, Id postalId) {
        return new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Street = '123 Test St',
            City__c = cityId,          
            State__c = stateId,       
            Country__c = countryId,    
            Postal_Code__c = postalId, 
            Status = 'Open - Not Contacted',
            Lead_Type__c = 'Domestic', 
            Zone__c = 'East',
            Email = 'test@example.com',
            Phone = '1234567890'
        );
    }
    
    private static Map<String, Id> setupLocationData() {
        Map<String, Id> locationIds = new Map<String, Id>();
        
        Country__c country = new Country__c(Name='TestCountry');
        insert country;
        locationIds.put('countryId', country.Id);
        
        State__c state = new State__c(Name='TestState', Country__c=country.Id, Zone__c='East');
        insert state;
        locationIds.put('stateId', state.Id);
        
        City__c city = new City__c(Name='TestCity', State__c=state.Id,Country__c=country.Id);
        insert city;
        locationIds.put('cityId', city.Id);
        
        Postal_Code__c postal = new Postal_Code__c(Name='123456', State__c=state.Id, City__c=city.Id,Country__c=country.Id);
        insert postal;
        locationIds.put('postalId', postal.Id);
        
        return locationIds;
    }
    
    @isTest
    static void testHandleLeadConversion() {
        Map<String, Id> locationIds = setupLocationData();
        Lead testLead = createTestLead(
            locationIds.get('cityId'),
            locationIds.get('stateId'),
            locationIds.get('countryId'),
            locationIds.get('postalId')
        );
        insert testLead;
        
        String validPicklistValue = getValidPicklistValue('Product_Interested__c', 'Product_Family__c');
        
        Product_Interested__c prodInt = new Product_Interested__c(
            Lead__c = testLead.Id,
            Volume_in_Kgs__c = 100,
            Expected_Price__c = 5000,
            Product_Family__c = validPicklistValue,
            Add_In_Opty__c = true
        );
        insert prodInt;
    }
    
    @isTest
    static void testDeleteProductInterested() {
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;
        
        Product_Interested__c prodInt = new Product_Interested__c(
            Product__c = testProduct.Id,
            Volume_in_Kgs__c = 10,
            Expected_Price__c = 100,
            Add_In_Opty__c = false
        );
        insert prodInt;
        
        Test.startTest();
        String result = addProductIntrested.deleteProductInterested(prodInt.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetExistingProducts() {
        Map<String, Id> locationIds = setupLocationData();
        Lead lead = createTestLead(
            locationIds.get('cityId'),
            locationIds.get('stateId'),
            locationIds.get('countryId'),
            locationIds.get('postalId')
        );
        insert lead;
        
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;
        
        Product_Interested__c prodInt = new Product_Interested__c(
            Lead__c = lead.Id,
            Product__c = testProduct.Id,
            Volume_in_Kgs__c = 10,
            Expected_Price__c = 200,
            Add_In_Opty__c = false
        );
        insert prodInt;
        
        Test.startTest();
        List<Id> productIds = addProductIntrested.getExistingProducts(lead.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetPicklistValues() {
        Test.startTest();
        Map<String, List<Map<String, String>>> picklistValues = addProductIntrested.getPicklistValues();
        Test.stopTest();
    }
    
    @isTest
    static void testSaveProductInterested() {
        Map<String, Id> locationIds = setupLocationData();
        Lead lead = createTestLead(
            locationIds.get('cityId'),
            locationIds.get('stateId'),
            locationIds.get('countryId'),
            locationIds.get('postalId')
        );
        insert lead;
        
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;
        
        String validPicklistValue = getValidPicklistValue('Product_Interested__c', 'Product_Family__c');
        String validFrequencyValue = getValidPicklistValue('Product_Interested__c', 'Volume_Frequency__c');
        
        String jsonString = '[{' +
            '"prodId":"' + testProduct.Id + '", ' +
            '"volume":"200", ' +
            '"price":"1500", ' +
            '"prodFamily":"' + validPicklistValue + '", ' +
            '"frequency":"' + validFrequencyValue + '", ' +
            '"Add_In_Opty":true, ' +
            '"New_Product":false, ' +
            '"New_Product_Name":"", ' +
            '"unitPrice":"100", ' +
            '"pbeId":""' +
            '}]';
        
        Test.startTest();
        Map<String, String> result = addProductIntrested.saveProductInterested(lead.Id, jsonString);
        Test.stopTest();
    }
    
    @isTest
    static void testGetProdInterest() {
        Map<String, Id> locationIds = setupLocationData();
        Lead testLead = createTestLead(
            locationIds.get('cityId'),
            locationIds.get('stateId'),
            locationIds.get('countryId'),
            locationIds.get('postalId')
        );
        insert testLead;
        
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;
        
        Product_Interested__c prodInt = new Product_Interested__c(
            Lead__c = testLead.Id,
            Volume_in_Kgs__c = 100,
            Expected_Price__c = 5000,
            Product_Family__c = getValidPicklistValue('Product_Interested__c', 'Product_Family__c'),
            Add_In_Opty__c = true
        );
        insert prodInt;
        
        Test.startTest();
        Map<String, Object> result = addProductIntrested.getProdInterest(testLead.Id);
        Test.stopTest();
    }

    private static String getValidPicklistValue(String objectName, String fieldName) {
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe()
            .get(objectName)
            .getDescribe()
            .fields
            .getMap()
            .get(fieldName)
            .getDescribe();
        
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        return picklistValues.isEmpty() ? '' : picklistValues[0].getValue();
    }
}