public with sharing class VisitController {

    @AuraEnabled
    public static Map<String, Object> createVisits(String events) {
        List<VisitWrapper> visitWrapperList = parseJsonData(events);
        List<Event> eventList = new List<Event>();
        List<String> createdEventIds = new List<String>();
        List<EventRelation> eventAttendees = new List<EventRelation>();
        Map<String, Object> result = new Map<String, Object>();

        try {
            System.debug('Received Events Payload: ' + events);

            // Step 1: Create Event records
            for (VisitWrapper vw : visitWrapperList) {
                System.debug('Processing VisitWrapper: ' + JSON.serialize(vw));

                Event e = new Event();
                e.Subject = vw.purpose;
                e.Description = vw.description;

                // Set WhoId or WhatId
                if (vw.objectType == 'Lead') {
                    e.WhoId = vw.accountId;
                } else if (vw.objectType == 'Account') {
                    e.WhatId = vw.accountId;
                }
                else if (vw.objectType == 'Contact' && String.isNotBlank(vw.contactId)) {
    e.WhoId = vw.contactId;
}

                if (vw.startDateTime != null) {
                    e.StartDateTime = DateTime.valueOfGMT(String.valueOf(vw.startDateTime).replace('T', ' '));
                }

                if (vw.endDateTime != null) {
                    e.EndDateTime = DateTime.valueOfGMT(String.valueOf(vw.endDateTime).replace('T', ' '));
                }

                if (e.StartDateTime == null) {
                    e.StartDateTime = DateTime.now();
                }

                if (e.EndDateTime == null) {
                    e.EndDateTime = e.StartDateTime.addMinutes(30);
                }

                Long durationMillis = e.EndDateTime.getTime() - e.StartDateTime.getTime();
                e.DurationInMinutes = (Integer)(durationMillis / (1000 * 60));
                e.ActivityDateTime = e.StartDateTime;

                eventList.add(e);
            }

            // Step 2: Insert Events
            if (!eventList.isEmpty()) {
                insert eventList;
                for (Event createdEvent : eventList) {
                    createdEventIds.add(createdEvent.Id);
                    System.debug('Inserted Event ID: ' + createdEvent.Id);
                }
            }

            // Step 3: Create EventRelations for attendees and external contacts
            Integer index = 0;
            for (VisitWrapper vw : visitWrapperList) {
                Event insertedEvent = eventList[index++];
                System.debug('Processing Event ID for EventRelations: ' + insertedEvent.Id);

                // Internal attendees
                if (vw.attendees != null) {
                    for (attendees attee : vw.attendees) {
                        if (attee != null && String.isNotBlank(attee.id)) {
                            System.debug('Adding internal attendee: ' + attee.id);
                            EventRelation er = new EventRelation();
                            er.EventId = insertedEvent.Id;
                            er.RelationId = attee.id;
                            er.IsParent = false;
                            er.Status = 'Accepted';
                            eventAttendees.add(er);
                        } else {
                            System.debug('Skipping invalid internal attendee: ' + JSON.serialize(attee));
                        }
                    }
                }

                // External contacts
                if (vw.externalContacts != null) {
                    for (attendees external : vw.externalContacts) {
                        if (external != null && String.isNotBlank(external.id)) {
                            System.debug('Adding external contact: ' + external.id);
                            EventRelation er = new EventRelation();
                            er.EventId = insertedEvent.Id;
                            er.RelationId = external.id;
                            er.IsParent = false;
                            er.Status = 'Accepted';
                            eventAttendees.add(er);
                        } else {
                            System.debug('Skipping invalid external contact: ' + JSON.serialize(external));
                        }
                    }
                }
            }

            // Step 4: Insert EventRelations
            if (!eventAttendees.isEmpty()) {
                insert eventAttendees;
                System.debug('Inserted ' + eventAttendees.size() + ' EventRelations');
            }

            result.put('Message', 'Success');
        } catch (Exception e) {
            System.debug('Exception during event creation: ' + e.getMessage());
            result.put('Message', 'Exception: ' + e.getMessage());
        }

        return result;
    }

    public class VisitWrapper {
        @AuraEnabled public String purpose;
        @AuraEnabled public String description;
        @AuraEnabled public String startDateTime;
        @AuraEnabled public String endDateTime;
        @AuraEnabled public String accountId;
        @AuraEnabled public String contactId;
        @AuraEnabled public String objectType;
        @AuraEnabled public List<attendees> attendees;
        @AuraEnabled public List<attendees> externalContacts;
    }

    public class attendees {
        public String id;
    }

    public static List<VisitWrapper> parseJsonData(String json) {
        return (List<VisitWrapper>) System.JSON.deserialize(json, List<VisitWrapper>.class);
    }
}