public class CampaignTriggerHandler {
    public static void shareLeadsWithNewOwner(Set<Id> campaignIds, Map<Id, Id> campaignIdToNewOwnerId) {
        Map<Id, Id> leadIdToNewOwnerId = new Map<Id, Id>();

        List<CampaignMember> members = [
            SELECT LeadId, CampaignId
            FROM CampaignMember
            WHERE CampaignId IN :campaignIds AND LeadId != null
        ];

        for (CampaignMember member : members) {
            Id newOwnerId = campaignIdToNewOwnerId.get(member.CampaignId);
            if (newOwnerId != null) {
                leadIdToNewOwnerId.put(member.LeadId, newOwnerId);
            }
        }

        List<LeadShare> sharesToInsert = new List<LeadShare>();

        for (Id leadId : leadIdToNewOwnerId.keySet()) {
            LeadShare share = new LeadShare();
            share.LeadId = leadId;
            share.UserOrGroupId = leadIdToNewOwnerId.get(leadId);
            share.LeadAccessLevel = 'Edit'; // ✅ Corrected context: belongs to share object
            share.RowCause = Schema.LeadShare.RowCause.Manual;
            sharesToInsert.add(share);
        }

        if (!sharesToInsert.isEmpty()) {
            try {
                insert sharesToInsert;
            } catch (DmlException e) {
                System.debug('Error inserting LeadShare records: ' + e.getMessage());
            }
        }
    }
}