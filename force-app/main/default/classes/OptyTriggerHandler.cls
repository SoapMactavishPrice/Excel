public class OptyTriggerHandler {
    public static void convertHandler(List<Lead> newRecords,Map<Id, Lead> oldLeadMap){
        
        Set<Id> oppIds = new Set<Id>();
        Map<Id, Id> leadIdMap = new Map<Id, Id>(); // Store lead ID for each opportunity

        for (Lead lead : newRecords) {
            Lead oldLead = oldLeadMap.get(lead.Id);
            if (lead.IsConverted && !oldLead.isConverted && string.isNotBlank(lead.ConvertedOpportunityId)) {
                leadIdMap.put(lead.Id, lead.ConvertedOpportunityId); // Map opportunity to its lead
            }
        }
        system.debug('leadIdMap-->'+leadIdMap);
        if(leadIdMap.size() > 0){
          List<Product_Interested__c> piList= [Select Id,Product__c,Lead__c,Product__r.Name,Volume_in_Kgs__c,Expected_Price__c,Product_Family__c,Add_In_Opty__c,
                                               Product_Code__c,Volume_Frequency__c, Name from Product_Interested__c where Lead__c IN :leadIdMap.keyset() and Add_In_Opty__c=:true order by CreatedDate];
           
          system.debug('piList-->'+piList.size());
            if(piList.size() > 0){
                set<Id> prodId = new set<Id>();
                for(Product_Interested__c pi : piList){
                    if(string.isNotBlank(pi.Product__c)){
                        prodId.add(pi.Product__c);
                    }
                }
            }
            List<PricebookEntry> pbeEntry = [Select Product2.Id from PricebookEntry where Pricebook2.Name =:'Standard Price Book' and IsActive =:True];
            map<Id,Id> pbeMap = new map<Id,Id>(); 
            for(PricebookEntry pbe: pbeEntry){
                pbeMap.put(pbe.Product2.Id,pbe.Id);
            }
            

			List<OpportunityLineItem> optl = new List<OpportunityLineItem>();            
            for(Product_Interested__c pi : piList){
                    if(pbeMap.containsKey(pi.Product__c) && leadIdMap.containsKey(pi.Lead__c)){
                        OpportunityLineItem opty = new OpportunityLineItem();
                        opty.OpportunityId =leadIdMap.get(pi.Lead__c);
                        opty.PricebookEntryId = pbeMap.get(pi.Product__c);
                        opty.Product2Id = pi.Product__c;
                        opty.UnitPrice = pi.Expected_Price__c;
                        opty.Quantity = pi.Volume_in_Kgs__c;
                        opty.Quantity_Frequency__c = pi.Volume_Frequency__c;
                     	optl.add(opty);   
                    }
                }
            
            if(optl.size() > 0)
                insert optl;
        }
        
    }
    
}