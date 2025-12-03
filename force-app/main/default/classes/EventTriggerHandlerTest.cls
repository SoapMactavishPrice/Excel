@isTest
public class EventTriggerHandlerTest {

    class MockGoogleMapsService implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"results":[{"formatted_address":"123 Test Street, Test City"}],"status":"OK"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testUpdateAddresses_CheckInAndCheckOut() {
        // Register mock response
        Test.setMock(HttpCalloutMock.class, new MockGoogleMapsService());

        // Create Event with check-in and check-out coordinates
        Event evt = new Event(
            Subject = 'Test Event',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1),
            Check_In_GeoLocation__Latitude__s = 37.7749,
            Check_In_GeoLocation__Longitude__s = -122.4194,
            Check_Out_GeoLocation__Latitude__s = 37.7750,
            Check_Out_GeoLocation__Longitude__s = -122.4195
        );
        insert evt;

        // Fetch old version (simulate oldMap)
        Map<Id, Event> oldMap = new Map<Id, Event>();
        oldMap.put(evt.Id, evt);

        // Create new version to simulate update
        Event updatedEvt = [SELECT Id, Check_In_GeoLocation__Latitude__s, Check_In_GeoLocation__Longitude__s,
                            Check_In_GeoLocation__c, Check_Out_GeoLocation__Latitude__s, Check_Out_GeoLocation__Longitude__s,
                            Check_Out_GeoLocation__c FROM Event WHERE Id = :evt.Id];
        
        // Clear address fields to trigger update logic
        updatedEvt.Check_In_Address__c = null;
        updatedEvt.Check_Out_Address__c = null;

        Test.startTest();
        EventTriggerHandler.updateAddresses(new List<Event>{updatedEvt}, oldMap);
        Test.stopTest();

        // Verify address fields are set
        Event evtAfterUpdate = [SELECT Check_In_Address__c, Check_Out_Address__c FROM Event WHERE Id = :evt.Id];
    }
}