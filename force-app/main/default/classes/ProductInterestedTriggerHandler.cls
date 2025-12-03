public class ProductInterestedTriggerHandler {
    public static void updateCurrency(List<Product_Interested__c> products) {
        Set<Id> leadIds = new Set<Id>();
        
        // Collect Lead Ids from Product_Interested__c records
        for (Product_Interested__c product : products) {
            if (product.Lead__c != null) {
                leadIds.add(product.Lead__c);
            }
        }
        
        // Query Lead records
        Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT Id, CurrencyIsoCode FROM Lead WHERE Id IN :leadIds]);
        
        // Collect records to update
        List<Product_Interested__c> productsToUpdate = new List<Product_Interested__c>();
        for (Product_Interested__c product : products) {
            if (product.Lead__c != null && leadMap.containsKey(product.Lead__c)) {
                Product_Interested__c productToUpdate = new Product_Interested__c(Id = product.Id);
                productToUpdate.CurrencyIsoCode = leadMap.get(product.Lead__c).CurrencyIsoCode;
                productsToUpdate.add(productToUpdate);
            }
        }
        
        // Perform DML update
        if (!productsToUpdate.isEmpty()) {
            update productsToUpdate;
        }
    }
}