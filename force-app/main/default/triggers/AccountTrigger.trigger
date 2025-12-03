trigger AccountTrigger on Account (before insert) {
    
    if (Trigger.isBefore && Trigger.isInsert){
        
        try {
            
            Code_Master__c codem = [SELECT Id, Name, Code_For__c, Current_Sequence__c, Starting_Sequence__c, 
                                    Backend_Current_Sequence__c FROM Code_Master__c 
                                    WHERE Code_For__c  = 'Account' AND Is_Active__c = true limit 1 FOR UPDATE];
            
            for(Account p:Trigger.new){ 
                p.Customer_Code__c   = 'SFCUS' + string.ValueOf(codem.Backend_Current_Sequence__c);
                codem.Current_Sequence__c = codem.Current_Sequence__c + 1;
            }
            update codem;
            
        } catch (Exception e) {
            System.debug('The following exception has occurred on Code Master' + e.getMessage());
        }
    }
}