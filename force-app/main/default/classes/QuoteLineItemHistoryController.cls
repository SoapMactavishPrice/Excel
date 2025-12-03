public with sharing class QuoteLineItemHistoryController {

    @AuraEnabled(cacheable=true)
    public static List<QuoteLineItemWrapper> getLatestQuoteLineItems(Id quoteId) {
        List<QuoteLineItemWrapper> result = new List<QuoteLineItemWrapper>();

        for (QuoteLineItem qli : [
            SELECT Id, Product2.Name, Quantity, UnitPrice, LastModifiedDate
            FROM QuoteLineItem
            WHERE QuoteId = :quoteId
        ]) {
            result.add(new QuoteLineItemWrapper(
                qli.Id,
                qli.Product2.Name,
                qli.Quantity,
                qli.UnitPrice,
                qli.LastModifiedDate
            ));
        }

        return result;
    }

    public class QuoteLineItemWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String productName;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal salesPrice;
        @AuraEnabled public Datetime modifiedDate;

        public QuoteLineItemWrapper(Id id, String productName, Decimal quantity, Decimal salesPrice, Datetime modifiedDate) {
            this.id = id;
            this.productName = productName;
            this.quantity = quantity;
            this.salesPrice = salesPrice;
            this.modifiedDate = modifiedDate;
        }
    }
}