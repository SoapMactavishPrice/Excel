trigger OpportunityTrigger on Opportunity (After Update) {
    // Calls the handler methods to handle the stage change logic
    OpportunityTriggerHandler.handleClosedWonOpportunities(trigger.new, trigger.oldMap);
    OpportunityTriggerHandler.handleProposalOpportunities(trigger.new, trigger.oldMap);
}