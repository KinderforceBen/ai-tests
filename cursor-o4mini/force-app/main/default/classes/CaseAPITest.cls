@isTest
private class CaseAPITest {
    @isTest static void testSuccessfulCreation() {
        // Create a contact
        Contact con = new Contact(LastName = 'Test', Email = 'test@example.com');
        insert con;
        // Setup REST request
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CaseAPI/v1/create';
        req.httpMethod = 'POST';
        Map<String, Object> payload = new Map<String, Object>{
            'Subject' => 'Test Subject',
            'Description' => 'Test Description',
            'Priority' => 'High',
            'ContactEmail' => con.Email
        };
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = new RestResponse();
        // Invoke REST method
        CaseAPI.Service.createCase();
        // Verify response
        RestResponse res = RestContext.response;
        System.assertEquals(200, res.statusCode);
        CaseAPI.CaseResponse resp = (CaseAPI.CaseResponse) JSON.deserialize(res.responseBody.toString(), CaseAPI.CaseResponse.class);
        System.assert(resp.success);
        System.assertNotEquals(null, resp.caseId);
        System.assertEquals(null, resp.errors);
        // Verify case was created correctly
        Case c = [SELECT Subject, Description, Priority, ContactId FROM Case WHERE Id = :resp.caseId];
        System.assertEquals(payload.get('Subject'), c.Subject);
        System.assertEquals(payload.get('Description'), c.Description);
        System.assertEquals(payload.get('Priority'), c.Priority);
        System.assertEquals(con.Id, c.ContactId);
    }

    @isTest static void testErrorPath() {
        // Missing required Subject field to trigger error
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CaseAPI/v1/create';
        req.httpMethod = 'POST';
        Map<String, Object> payload = new Map<String, Object>{
            'Description' => 'Test Description',
            'Priority' => 'Low',
            'ContactEmail' => 'nonexistent@example.com'
        };
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = new RestResponse();
        // Invoke REST method
        CaseAPI.Service.createCase();
        // Verify error response
        RestResponse res = RestContext.response;
        System.assertEquals(400, res.statusCode);
        CaseAPI.CaseResponse resp = (CaseAPI.CaseResponse) JSON.deserialize(res.responseBody.toString(), CaseAPI.CaseResponse.class);
        System.assert(!resp.success);
        System.assertEquals(null, resp.caseId);
        System.assert(resp.errors != null && !resp.errors.isEmpty());
    }
} 