public class EventTriggerHandler {
    public static void updateAddresses(List<Event> newList, Map<Id, Event> oldMap) {
        List<Event> toUpdate = new List<Event>();
        String apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

        for (Event e : newList) {
            Event old = oldMap != null ? oldMap.get(e.Id) : null;

            // Check-In logic
            Boolean checkInNew = (old == null || old.Check_In_GeoLocation__c == null) &&
                                 e.Check_In_GeoLocation__c != null &&
                                 String.isBlank(e.Check_In_Address__c);
            if (checkInNew) {
                String addr = GoogleMapsService.reverseGeocode(
                    e.Check_In_GeoLocation__Latitude__s,
                    e.Check_In_GeoLocation__Longitude__s,
                    apiKey
                );
                if (addr != null) e.Check_In_Address__c = addr;
            }

            // Check-Out logic
            Boolean checkOutNew = (old == null || old.Check_Out_GeoLocation__c == null) &&
                                  e.Check_Out_GeoLocation__c != null &&
                                  String.isBlank(e.Check_Out_Address__c);
            if (checkOutNew) {
                String addr = GoogleMapsService.reverseGeocode(
                    e.Check_Out_GeoLocation__Latitude__s,
                    e.Check_Out_GeoLocation__Longitude__s,
                    apiKey
                );
                if (addr != null) e.Check_Out_Address__c = addr;
            }

            if (checkInNew || checkOutNew) {
                toUpdate.add(e);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}