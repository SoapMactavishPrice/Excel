trigger OrderTrigger on Order (before insert, after insert) {
    
    if (Trigger.isBefore && Trigger.isInsert){
        
        try {
            
            Code_Master__c codem = [SELECT Id, Name, Code_For__c, Current_Sequence__c, Starting_Sequence__c, 
                                    Backend_Current_Sequence__c FROM Code_Master__c 
                                    WHERE Code_For__c  = 'Order' AND Is_Active__c = true limit 1 FOR UPDATE];
            
            for(Order p:Trigger.new){ 
                p.Name  = 'SFORD' + string.ValueOf(codem.Backend_Current_Sequence__c);
                codem.Current_Sequence__c = codem.Current_Sequence__c + 1;
            }
            update codem;
            
        } catch (Exception e) {
            System.debug('The following exception has occurred on Code Master' + e.getMessage());
        }
    }
    
    if (Trigger.isAfter && Trigger.isInsert){
        
        Set<Id> accountIds = new Set<Id>();
        
        for (Order ord : Trigger.new) {
            if (ord.AccountId != null) {
                accountIds.add(ord.AccountId);
            }
        }
        
        // Get Address_Information__c records grouped by AccountId
        Map<Id, Address_Information__c> accountToAddressMap = new Map<Id, Address_Information__c>();
        
        for (Address_Information__c addr : [
            SELECT Id, Account__c, Address_1__c, Address_2__c 
            FROM Address_Information__c
            WHERE Account__c IN :accountIds
            ORDER BY CreatedDate DESC
        ]) {
            // Only take the first (latest) address per Account
            if (!accountToAddressMap.containsKey(addr.Account__c)) {
                accountToAddressMap.put(addr.Account__c, addr);
            }
        }
        
        List<Order> ordersToUpdate = new List<Order>();
        
        for (Order ord : Trigger.new) {
            Address_Information__c address = accountToAddressMap.get(ord.AccountId);
            if (address != null) {
                ordersToUpdate.add(new Order(
                    Id = ord.Id
                    
                    
                ));
            }
        }
        
        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }
    }
}