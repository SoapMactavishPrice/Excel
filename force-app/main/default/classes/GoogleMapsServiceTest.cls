@isTest
private class GoogleMapsServiceTest {

    // Mock class that simulates a successful Google Maps API response
    private class MockGoogleMapsCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"results":[{"formatted_address":"123 Mock Street, Mock City"}],"status":"OK"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testReverseGeocode_Success() {
        // Set the mock response
        Test.setMock(HttpCalloutMock.class, new MockGoogleMapsCallout());

        // Call the method with test values
        Test.startTest();
        String address = GoogleMapsService.reverseGeocode(37.7749, -122.4194, 'dummy_key');
        Test.stopTest();

        // Assert expected address
        System.assertEquals('123 Mock Street, Mock City', address);
    }

    // Optional: Add a test case for failed callout
    private class MockGoogleMapsErrorCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500); // Simulate failure
            res.setBody('{"error_message":"Invalid request"}');
            return res;
        }
    }

    @isTest
    static void testReverseGeocode_Failure() {
        Test.setMock(HttpCalloutMock.class, new MockGoogleMapsErrorCallout());

        Test.startTest();
        String address = GoogleMapsService.reverseGeocode(0.0, 0.0, 'dummy_key');
        Test.stopTest();

        System.assertEquals(null, address, 'Expected null on failed callout');
    }
}