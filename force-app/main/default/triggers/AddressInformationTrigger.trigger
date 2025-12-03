trigger AddressInformationTrigger on Address_Information__c (before insert, before update, after insert, after update) {
    
    if (Trigger.isAfter) {
        AddressInformationTriggerHandler.handleCopyBillToShipTo(Trigger.new);
        if(Trigger.isInsert) {
            AddressInformationTriggerHandler.handleInfoCorrection(Trigger.new);
        }
    }
    
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        AddressInformationTriggerHandler.updateAddressInformation(Trigger.new);
    }
    
    if (Trigger.isBefore && Trigger.isInsert){
        
        try {
            
            Code_Master__c BillTocodem = [SELECT Id, Name, Code_For__c, Current_Sequence__c, Starting_Sequence__c, 
                                          Backend_Current_Sequence__c FROM Code_Master__c 
                                          WHERE Code_For__c  = 'Bill To' AND Is_Active__c = true limit 1 FOR UPDATE];
            
            Code_Master__c ShipTocodem = [SELECT Id, Name, Code_For__c, Current_Sequence__c, Starting_Sequence__c, 
                                          Backend_Current_Sequence__c FROM Code_Master__c 
                                          WHERE Code_For__c  = 'Ship To' AND Is_Active__c = true limit 1 FOR UPDATE];
            
            for(Address_Information__c p:Trigger.new){
                if (p.RecordtypeId   == '012Hz000001yQs3'){//BILL TO 
                    p.SF_Address_Code__c = string.ValueOf(BillTocodem.Backend_Current_Sequence__c);
                    BillTocodem.Current_Sequence__c = BillTocodem.Current_Sequence__c + 1;
                } else if (p.RecordtypeId == '012Hz000001yQs8'){//SHIP TO 
                    p.SF_Address_Code__c = string.ValueOf(ShipTocodem.Backend_Current_Sequence__c);
                    ShipTocodem.Current_Sequence__c = ShipTocodem.Current_Sequence__c + 1;
                }
            }
            update BillTocodem;
            update ShipTocodem;
            
        } catch (Exception e) {
            System.debug('The following exception has occurred on Code Master' + e.getMessage());
        }
    }
}