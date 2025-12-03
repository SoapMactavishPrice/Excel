trigger CampaignTrigger on Campaign (after update) {
    
    Set<Id> campaignIds = new Set<Id>();
    Map<Id, Id> campaignIdToNewOwnerId = new Map<Id, Id>();
    
    for (Campaign c : Trigger.new) {
        Campaign oldC = Trigger.oldMap.get(c.Id);
        if (c.OwnerId != oldC.OwnerId) {
            campaignIds.add(c.Id);
            campaignIdToNewOwnerId.put(c.Id, c.OwnerId);
        }
    }
    
    if (!campaignIds.isEmpty()) {
        CampaignTriggerHandler.shareLeadsWithNewOwner(campaignIds, campaignIdToNewOwnerId);
    }
}