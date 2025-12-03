public class LeadTriggerHandler {
    
    public static void validateActivityForStatusChange(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        Set<Id> leadIdsToValidate = new Set<Id>();
        
        for (Lead ld : newLeads) {
            Lead oldLd = oldLeadMap.get(ld.Id);
            if (oldLd.Status == 'New' && ld.Status != 'New') {
                leadIdsToValidate.add(ld.Id);
            }
        }
        
        if (leadIdsToValidate.isEmpty()) return;
        
        Date today = Date.today();
        Set<Id> validActivityLeadIds = new Set<Id>();
        
        // Fetch Tasks with today's ActivityDate
        for (Task t : [
            SELECT WhoId 
            FROM Task 
            WHERE WhoId IN :leadIdsToValidate 
            AND ActivityDate = :today
        ]) {
            validActivityLeadIds.add(t.WhoId);
        }
        
        DateTime startOfDay = DateTime.newInstance(today, Time.newInstance(0, 0, 0, 0));
        DateTime endOfDay   = DateTime.newInstance(today, Time.newInstance(23, 59, 59, 999));
        
        // Fetch Events with today's StartDateTime
        for (Event e : [
            SELECT WhoId 
            FROM Event 
            WHERE WhoId IN :leadIdsToValidate 
            AND StartDateTime >= :startOfDay AND StartDateTime <= :endOfDay
            
        ]) {
            validActivityLeadIds.add(e.WhoId);
        }
        
        // Add error to Leads that don’t have activity logged for today
        for (Lead ld : newLeads) {
            if (leadIdsToValidate.contains(ld.Id) && !validActivityLeadIds.contains(ld.Id)) {
                ld.addError('You must log a Task or Event for today before changing the status from New.');
            }
        }
    }
    
    public static void validateData(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        Set<Id> leadIdsToCheck = new Set<Id>();
        
        // Identify leads whose status has changed to 'New'
        for (Lead leadRec : newLeads) {
            Lead oldLead = oldLeadMap.get(leadRec.Id);
            if (oldLead != null /*&& leadRec.Status == 'New' &&*/ && leadRec.Status != oldLead.Status) {
                leadIdsToCheck.add(leadRec.Id);
            }
        }
        
        if (!leadIdsToCheck.isEmpty()) {
            // Query related Product_Interested__c records
            Set<Id> leadsWithProducts = new Set<Id>();
            for (Product_Interested__c pi : [
                SELECT Id, Lead__c 
                FROM Product_Interested__c 
                WHERE Lead__c IN :leadIdsToCheck
            ]) {
                leadsWithProducts.add(pi.Lead__c);
            }
            
            // Add validation errors if no products are found
            for (Lead leadRec : newLeads) {
                if (leadIdsToCheck.contains(leadRec.Id) && !leadsWithProducts.contains(leadRec.Id)) {
                    leadRec.addError('Before changing the lead status, add atleast one related product.');
                }
            }
        }
    }
    
    public static void updateLeadAddresses(List<Lead> newLeads) {
        Set<Id> postalCodeIds = new Set<Id>();
        Set<Id> areaIds = new Set<Id>();
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        
        // Collect all relevant IDs from the leads being processed
        for (Lead lead : newLeads) {
            if (lead.Postal_Code__c != null) {
                postalCodeIds.add(lead.Postal_Code__c);
            }
            //if (lead.Area__c != null) {
            //areaIds.add(lead.Area__c);
            //}
            if (lead.City__c != null) {
                cityIds.add(lead.City__c);
            }
            if (lead.State__c != null) {
                stateIds.add(lead.State__c);
            }
        }
        
        // Query the related records
        Map<Id, Postal_Code__c> postalCodeMap = new Map<Id, Postal_Code__c>(
            [SELECT Id, Area__c, City__c, State__c, Country__c FROM Postal_Code__c WHERE Id IN :postalCodeIds]
        );
        //Map<Id, Area__c> areaMap = new Map<Id, Area__c>(
        //[SELECT Id, City__c, State__c, Country__c FROM Area__c WHERE Id IN :areaIds]
        //);
        Map<Id, City__c> cityMap = new Map<Id, City__c>(
            [SELECT Id, State__c, Country__c FROM City__c WHERE Id IN :cityIds]
        );
        Map<Id, State__c> stateMap = new Map<Id, State__c>(
            [SELECT Id, Country__c FROM State__c WHERE Id IN :stateIds]
        );
        
        // Update the lead fields based on the selected values
        for (Lead lead : newLeads) {
            if (lead.Postal_Code__c != null && postalCodeMap.containsKey(lead.Postal_Code__c)) {
                Postal_Code__c postalCode = postalCodeMap.get(lead.Postal_Code__c);
                //lead.Area__c = postalCode.Area__c;
                lead.City__c = postalCode.City__c;
                lead.State__c = postalCode.State__c;
                lead.Country__c = postalCode.Country__c;
            } 
            /*else if (lead.Area__c != null && areaMap.containsKey(lead.Area__c)) {
Area__c area = areaMap.get(lead.Area__c);
lead.City__c = area.City__c;
lead.State__c = area.State__c;
lead.Country__c = area.Country__c;
}*/ 
            else if (lead.City__c != null && cityMap.containsKey(lead.City__c)) {
                City__c city = cityMap.get(lead.City__c);
                lead.State__c = city.State__c;
                lead.Country__c = city.Country__c;
            } else if (lead.State__c != null && stateMap.containsKey(lead.State__c)) {
                State__c state = stateMap.get(lead.State__c);
                lead.Country__c = state.Country__c;
            }
        }
    }
    
    public static void handleLeadConversion(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        // Fetch Bill To RecordTypeId
        Id billToRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Address_Information__c' AND DeveloperName = 'Bill_To' LIMIT 1].Id;
        
        // Fetch related City__c records
        Set<Id> cityIds = new Set<Id>();
        Map<Id, Lead> convertedLeadsMap = new Map<Id, Lead>();
        
        for (Lead leadRec : newLeads) {
            if (leadRec.City__c != null) {
                cityIds.add(leadRec.City__c);
            }
        }
        
        Map<Id, City__c> cityMap = new Map<Id, City__c>([SELECT Id, Name FROM City__c WHERE Id IN :cityIds]);
        
        List<Address_Information__c> addressInfoList = new List<Address_Information__c>();
        
        for (Lead leadRec : newLeads) {
            Lead oldLead = oldLeadMap.get(leadRec.Id);
            
            // Check if the lead was converted
            if (!oldLead.isConverted && leadRec.isConverted && leadRec.ConvertedAccountId != null) {
                Address_Information__c addressInfo = new Address_Information__c();
                convertedLeadsMap.put(leadRec.Id, leadRec);
                
                // Map fields from Lead to Address_Information__c
                String cityName = cityMap.containsKey(leadRec.City__c) ? cityMap.get(leadRec.City__c).Name : '';
                addressInfo.Name = 'Bill To - ' + cityName;
                addressInfo.Account__c = leadRec.ConvertedAccountId;
                addressInfo.Address_1__c  = leadRec.Street__c;
                addressInfo.City__c = leadRec.City__c;
                addressInfo.State__c = leadRec.State__c;
                addressInfo.Country__c = leadRec.Country__c;
                addressInfo.Postal_Code__c = leadRec.Postal_Code__c;
                //addressInfo.Area__c = leadRec.Area__c;
                
                // Assign Bill To RecordTypeId
                addressInfo.RecordTypeId = billToRecordTypeId;
                addressInfoList.add(addressInfo);
            }
        }
        
        // Insert Address_Information__c records
        if (!addressInfoList.isEmpty()) {
            insert addressInfoList;
        }
        
        //Step 2: Contact Creation from Additional_Contact__c
        List<Additional_Contact__c > relatedInfos = [
            SELECT  Last_Name__c,Name, Email__c, Mobile_Number__c , Designation__c, Lead__c
            FROM Additional_Contact__c 
            WHERE Lead__c IN :convertedLeadsMap.keySet()
        ];
        
        List<Contact> contactsToInsert = new List<Contact>();
        for (Additional_Contact__c  info : relatedInfos) {
            Lead convertedLead = convertedLeadsMap.get(info.Lead__c);
            Contact con = new Contact();
            con.FirstName     = info.Name;
            con.LastName      = info.Last_Name__c;
            con.Email         = info.Email__c;
            con.Title         = info.Designation__c;
            con.MobilePhone   = info.Mobile_Number__c;
            con.AccountId     = convertedLead.ConvertedAccountId;
            contactsToInsert.add(con);
        }
        
        if (!contactsToInsert.isEmpty()) {
            try {
                insert contactsToInsert;
                System.debug('Inserted Contact records: ' + contactsToInsert.size());
            } catch (Exception e) {
                System.debug('Contact insert error: ' + e.getMessage());
            }
        }
    }  
    
    public static void handleProductIntrestedConversion(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        // Collect Leads that have been converted
        List<Lead> convertedLeads = new List<Lead>();
        for (Lead lead : newLeads) {
            Lead oldLead = oldLeadMap.get(lead.Id);
            if (lead.IsConverted && oldLead.IsConverted == false) {
                convertedLeads.add(lead);
            }
        }
        
        if (convertedLeads.isEmpty()) {
            return;
        }
        
        // Map Lead to their converted Account IDs
        Map<Id, Id> leadToAccountMap = new Map<Id, Id>();
        for (Lead lead : convertedLeads) {
            if (lead.ConvertedAccountId != null) {
                leadToAccountMap.put(lead.Id, lead.ConvertedAccountId);
            }
        }
        
        
        
        
        
        // Fetch Product_Interested__c records related to the converting Leads
        List<Product_Interested__c> leadProducts = [
            SELECT Id, Account__c, Lead__c
            FROM Product_Interested__c
            WHERE Lead__c IN :leadToAccountMap.keySet()
        ];
        
        // Update the Account__c field on the fetched Product_Interested__c records
        for (Product_Interested__c leadProduct : leadProducts) {
            leadProduct.Account__c = leadToAccountMap.get(leadProduct.Lead__c);
        }
        
        if (!leadProducts.isEmpty()) {
            try {
                update leadProducts;
            } catch (Exception e) {
                System.debug('Error while updating Product_Interested__c: ' + e.getMessage());
            }
        }
    }
    
    public static void handleSampleBookingConversion(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        // Collect Leads that have been converted
        List<Lead> convertedLeads = new List<Lead>();
        for (Lead lead : newLeads) {
            Lead oldLead = oldLeadMap.get(lead.Id);
            if (lead.IsConverted && oldLead.IsConverted == false) {
                convertedLeads.add(lead);
            }
        }
        
        if (convertedLeads.isEmpty()) {
            return;
        }
        
        // Map Lead to their converted Account and Opportunity IDs
        Map<Id, Id> leadToAccountMap = new Map<Id, Id>();
        Map<Id, Id> leadToOpportunityMap = new Map<Id, Id>();
        
        Map<Id, Id> ProdGroupleadToAccountMap = new Map<Id, Id>();
        Map<Id, Id> ProdGroupleadToOpportunityMap = new Map<Id, Id>();
        for (Lead lead : convertedLeads) {
            if (lead.ConvertedAccountId != null) {
                leadToAccountMap.put(lead.Id, lead.ConvertedAccountId);
                ProdGroupleadToAccountMap.put(lead.ConvertedAccountId,lead.Product_Group_New__c);
            }
            if (lead.ConvertedOpportunityId != null) {
                leadToOpportunityMap.put(lead.Id, lead.ConvertedOpportunityId);
                ProdGroupleadToOpportunityMap.put(lead.ConvertedAccountId, lead.ConvertedOpportunityId);
                
            }
        }
        
        map<Id,Account> accNew = new map<Id,Account>();
        for(Account ac : [select Id,Product_Group__c from Account where Id IN :ProdGroupleadToAccountMap.keyset()]){
            if(ProdGroupleadToAccountMap.containsKey(ac.Id)){
                ac.Product_Group__c = ProdGroupleadToAccountMap.get(ac.Id);
                accNew.put(ac.Id,ac);
            }
        }
        
        if(accNew.size() > 0){
            update accNew.values();
        }
        
        
        map<Id,Opportunity> oppNew = new map<Id,Opportunity>();
        for(Opportunity ac : [select Id,Product_Group__c from Opportunity where Id IN :ProdGroupleadToOpportunityMap.keyset()]){
            if(ProdGroupleadToOpportunityMap.containsKey(ac.Id)){
                ac.Product_Group__c = ProdGroupleadToOpportunityMap.get(ac.Id);
                oppNew.put(ac.Id,ac);
            }
        }
        
        if(oppNew.size() > 0){
            update oppNew.values();
        }
        
        
        
        // Fetch Sample_Booking__c records related to the converting Leads
        List<Sample_Booking__c> leadSampleBookings = [
            SELECT Name, Lead__c, Account__c, Opportunity__c
            FROM Sample_Booking__c
            WHERE Lead__c IN :leadToAccountMap.keySet()
        ];
        
        // Update Sample_Booking__c records with Account and Opportunity
        for (Sample_Booking__c sampleBooking : leadSampleBookings) {
            sampleBooking.Account__c = leadToAccountMap.get(sampleBooking.Lead__c);
            sampleBooking.Opportunity__c = leadToOpportunityMap.get(sampleBooking.Lead__c);
        }
        
        if (!leadSampleBookings.isEmpty()) {
            try {
                update leadSampleBookings;
            } catch (Exception e) {
                System.debug('Error while updating Sample_Booking__c: ' + e.getMessage());
            }
        }
    }
}