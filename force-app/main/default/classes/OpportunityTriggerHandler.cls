public class OpportunityTriggerHandler {
    
    
    public static void handleClosedWonOpportunities(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        
        Set<Id> opportunityIds = new Set<Id>();
        for (Opportunity opp : newList) {
            opportunityIds.add(opp.Id);
        }
        
        Map<Id, List<OpportunityLineItem>> opportunityLineItemsMap = new Map<Id, List<OpportunityLineItem>>();
        for (OpportunityLineItem oli : [
            SELECT OpportunityId, Product2Id, Quantity, UnitPrice, PricebookEntryId
            FROM OpportunityLineItem
            WHERE OpportunityId IN :opportunityIds
        ]) {
            if (!opportunityLineItemsMap.containsKey(oli.OpportunityId)) {
                opportunityLineItemsMap.put(oli.OpportunityId, new List<OpportunityLineItem>());
            }
            opportunityLineItemsMap.get(oli.OpportunityId).add(oli);
        }
        
        
        List<Order> ordersToInsert = new List<Order>();
        List<OrderItem> orderItemsToInsert = new List<OrderItem>();
        
        for (Opportunity opp : newList) {
            
            if (opp.StageName == 'Closed Won'
                && oldMap.containsKey(opp.Id)
                && opp.StageName != oldMap.get(opp.Id).StageName
                && opportunityLineItemsMap.containsKey(opp.Id)) {
                    
                    for (OpportunityLineItem oli : opportunityLineItemsMap.get(opp.Id)) {
                        
                        Order newOrder = new Order(
                            OpportunityId = opp.Id,
                            AccountId = opp.AccountId,
                            Pricebook2Id = opp.Pricebook2Id, 
                            EffectiveDate = Date.today(),
                            Status = 'Draft' 
                        );
                        ordersToInsert.add(newOrder);
                        
                        OrderItem newOrderItem = new OrderItem(
                            Product2Id = oli.Product2Id,  
                            Quantity = oli.Quantity,  
                            UnitPrice = oli.UnitPrice,  
                            PricebookEntryId = oli.PricebookEntryId  
                        );
                        orderItemsToInsert.add(newOrderItem);
                    }
                }
        }
        
        if (!ordersToInsert.isEmpty()) {
            insert ordersToInsert;
            
            List<OrderItem> orderItemsToInsertAfter = new List<OrderItem>();
            Integer i = 0;
            for (Order order : ordersToInsert) {
                
                OpportunityLineItem oli = opportunityLineItemsMap.get(order.OpportunityId)[i];
                
                OrderItem newOrderItem = new OrderItem(
                    OrderId = order.Id,  
                    Product2Id = oli.Product2Id,  
                    Quantity = oli.Quantity,  
                    UnitPrice = oli.UnitPrice,  
                    PricebookEntryId = oli.PricebookEntryId  
                );
                orderItemsToInsertAfter.add(newOrderItem);
                i++;
            }
            
            
            if (!orderItemsToInsertAfter.isEmpty()) {
                insert orderItemsToInsertAfter;
            }
        }
    }
    
    
    public static void handleProposalOpportunities(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        
        Set<Id> opportunityIds = new Set<Id>();
        for (Opportunity opp : newList) {
            opportunityIds.add(opp.Id);
        }
        
        
        Map<Id, Quote> existingQuotesMap = new Map<Id, Quote>(
            [SELECT Id, OpportunityId FROM Quote WHERE OpportunityId IN :opportunityIds]
        );
        
        Map<Id, List<OpportunityLineItem>> opportunityLineItemsMap = new Map<Id, List<OpportunityLineItem>>();
        for (OpportunityLineItem oli : [
            SELECT OpportunityId, Product2Id, Quantity, UnitPrice, PricebookEntryId
            FROM OpportunityLineItem
            WHERE OpportunityId IN :opportunityIds
        ]) {
            if (!opportunityLineItemsMap.containsKey(oli.OpportunityId)) {
                opportunityLineItemsMap.put(oli.OpportunityId, new List<OpportunityLineItem>());
            }
            opportunityLineItemsMap.get(oli.OpportunityId).add(oli);
        }
        
        // Prepare lists for bulk DML operations
        List<Quote> quotesToInsert = new List<Quote>();
        List<QuoteLineItem> quoteLineItemsToInsert = new List<QuoteLineItem>();
        
        // Loop through the new opportunities
        for (Opportunity opp : newList) {
            // Validate stage change and ensure no existing quotes
            if (opp.StageName == 'Proposal'
                && oldMap.containsKey(opp.Id)
                && opp.StageName != oldMap.get(opp.Id).StageName
                && !existingQuotesMap.containsKey(opp.Id)) {
                    
                    // Ensure Opportunity has products
                    if (!opp.HasOpportunityLineItem) {
                        opp.addError('Please add at least one product before changing stage to Proposal.');
                        continue;
                    }
                    
                    // Create a new Quote
                    Quote newQuote = new Quote(
                        OpportunityId = opp.Id,
                        Name = opp.Name + ' - Proposal',
                        Pricebook2Id = opp.Pricebook2Id,
                        Status = 'Draft',
                        ExpirationDate = Date.today().addDays(30)
                    );
                    quotesToInsert.add(newQuote);
                }
        }
        
        // Insert Quotes in bulk
        if (!quotesToInsert.isEmpty()) {
            insert quotesToInsert;
            
            // Map OpportunityId to newly created Quotes
            Map<Id, Id> oppToQuoteMap = new Map<Id, Id>();
            for (Quote quote : quotesToInsert) {
                oppToQuoteMap.put(quote.OpportunityId, quote.Id);
            }
            
            // Create Quote Line Items for each Opportunity with products
            for (Id oppId : oppToQuoteMap.keySet()) {
                if (opportunityLineItemsMap.containsKey(oppId)) {
                    Id quoteId = oppToQuoteMap.get(oppId);
                    for (OpportunityLineItem oli : opportunityLineItemsMap.get(oppId)) {
                        QuoteLineItem newQuoteLineItem = new QuoteLineItem(
                            QuoteId = quoteId,
                            Product2Id = oli.Product2Id,
                            Quantity = oli.Quantity,
                            UnitPrice = oli.UnitPrice,
                            PricebookEntryId = oli.PricebookEntryId
                        );
                        quoteLineItemsToInsert.add(newQuoteLineItem);
                    }
                }
            }
            
            // Insert Quote Line Items in bulk
            if (!quoteLineItemsToInsert.isEmpty()) {
                insert quoteLineItemsToInsert;
            }
        }
    }
}