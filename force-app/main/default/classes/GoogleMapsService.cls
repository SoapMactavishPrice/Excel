public class GoogleMapsService {
    public static String reverseGeocode(Decimal latitude, Decimal longitude, String apiKey) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        
        String endpoint = 'callout:GoogleMapsAPI/maps/api/geocode/json?latlng=' 
            + latitude + ',' + longitude + '&key=' + apiKey;
        
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> json = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> results = (List<Object>) json.get('results');
            if (!results.isEmpty()) {
                Map<String, Object> first = (Map<String, Object>) results[0];
                return (String) first.get('formatted_address');
            }
        }
        System.debug('Google API Call Failed: ' + res.getBody());
        return null;
    }
}