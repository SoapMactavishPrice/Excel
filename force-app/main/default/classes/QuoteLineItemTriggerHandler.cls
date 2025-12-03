public class QuoteLineItemTriggerHandler {
    public static Map<Id, Decimal> oldPurchasePriceMap = new Map<Id, Decimal>();
    public static void storeOldValues(Map<Id, QuoteLineItem> oldMap) {
        for (QuoteLineItem oli : oldMap.values()) {
            oldPurchasePriceMap.put(oli.Id, oli.Purchase_Price_in_INR__c);
        }
    }
    
    public static void updatePreviousValues(Map<Id, QuoteLineItem> newMap) {
        List<QuoteLineItem> itemsToUpdate = new List<QuoteLineItem>();
        
        for (QuoteLineItem oli : newMap.values()) {
            Decimal oldPurchasePrice = oldPurchasePriceMap.get(oli.Id);

            if (oldPurchasePrice != null && oldPurchasePrice != oli.Purchase_Price_in_INR__c) {
                QuoteLineItem oliToUpdate = new QuoteLineItem(
                    Id = oli.Id,
                    Previous_Purchase_Price__c = oldPurchasePrice
                );
                itemsToUpdate.add(oliToUpdate);
            }
        }

        if (!itemsToUpdate.isEmpty()) {
            update itemsToUpdate;
        }
    }

}