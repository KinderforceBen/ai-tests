@isTest
private class CaseSyncServiceTest {
    
    @TestSetup
    static void setup() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        // Create test cases
        List<Case> testCases = new List<Case>();
        for (Integer i = 0; i < 5; i++) {
            testCases.add(new Case(
                Subject = 'Test Case ' + i,
                Description = 'Test Description ' + i,
                Priority = 'High',
                Status = 'New',
                Origin = 'Web',
                ContactId = testContact.Id,
                AccountId = testAccount.Id
            ));
        }
        insert testCases;
    }
    
    @isTest
    static void testSuccessfulSync() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, CaseSyncServiceMock.createSuccessMock('TKT-12345'));
        
        Test.startTest();
        CaseSyncService service = new CaseSyncService();
        ExternalTicketResponse response = service.syncCase(testCase);
        Test.stopTest();
        
        System.assert(response.isSuccess(), 'Response should be successful');
        System.assertEquals('TKT-12345', response.ticketId, 'Ticket ID should match');
        System.assertEquals('Created', response.status, 'Status should be Created');
    }
    
    @isTest
    static void testSyncWithError() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, CaseSyncServiceMock.createErrorMock('Invalid case data'));
        
        Test.startTest();
        CaseSyncService service = new CaseSyncService();
        ExternalTicketResponse response = service.syncCase(testCase);
        Test.stopTest();
        
        System.assert(!response.isSuccess(), 'Response should not be successful');
        System.assert(response.getErrorMessage().contains('Invalid case data'), 'Error message should contain expected text');
    }
    
    @isTest
    static void testSyncWithServerError() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, CaseSyncServiceMock.createServerErrorMock());
        
        Test.startTest();
        CaseSyncService service = new CaseSyncService();
        ExternalTicketResponse response = service.syncCase(testCase);
        Test.stopTest();
        
        System.assert(!response.isSuccess(), 'Response should not be successful');
        System.assertEquals('500', response.errorCode, 'Error code should be 500');
    }
    
    @isTest
    static void testSyncWithTimeout() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, CaseSyncServiceMock.createTimeoutMock());
        
        Test.startTest();
        CaseSyncService service = new CaseSyncService();
        ExternalTicketResponse response = service.syncCase(testCase);
        Test.stopTest();
        
        System.assert(!response.isSuccess(), 'Response should not be successful');
        System.assert(response.message.contains('Request Timeout'), 'Error should indicate timeout');
    }
    
    @isTest
    static void testSyncWithUnauthorized() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, CaseSyncServiceMock.createUnauthorizedMock());
        
        Test.startTest();
        CaseSyncService service = new CaseSyncService();
        ExternalTicketResponse response = service.syncCase(testCase);
        Test.stopTest();
        
        System.assert(!response.isSuccess(), 'Response should not be successful');
        System.assertEquals('AUTH001', response.errorCode, 'Error code should be AUTH001');
    }
    
    @isTest
    static void testBulkSync() {
        List<Case> testCases = [SELECT Id FROM Case LIMIT 3];
        
        // Set up different responses for different cases
        Test.setMock(HttpCalloutMock.class, new MultipleMockResponse());
        
        Test.startTest();
        CaseSyncService service = new CaseSyncService();
        List<CaseSyncResult> results = service.syncCases(testCases);
        Test.stopTest();
        
        System.assertEquals(3, results.size(), 'Should have 3 results');
        
        // Verify mixed results
        Integer successCount = 0;
        Integer failureCount = 0;
        
        for (CaseSyncResult result : results) {
            if (result.success) {
                successCount++;
                System.assertNotEquals(null, result.ticketId, 'Successful sync should have ticket ID');
            } else {
                failureCount++;
                System.assertNotEquals(null, result.errorMessage, 'Failed sync should have error message');
            }
        }
        
        System.assert(successCount > 0, 'Should have at least one success');
        System.assert(failureCount > 0, 'Should have at least one failure');
    }
    
    @isTest
    static void testRequestSerialization() {
        Case testCase = [
            SELECT Id, Subject, Description, Priority, Status, CaseNumber,
                   Origin, ContactId, Contact.Email, Contact.Name,
                   AccountId, Account.Name, CreatedDate
            FROM Case 
            LIMIT 1
        ];
        
        ExternalTicketRequest request = ExternalTicketRequest.fromCase(testCase);
        
        System.assertEquals(testCase.Subject, request.subject);
        System.assertEquals(testCase.Description, request.description);
        System.assertEquals(testCase.Priority, request.priority);
        System.assertEquals(testCase.CaseNumber, request.caseNumber);
        System.assertNotEquals(null, request.contactEmail);
        System.assertNotEquals(null, request.accountName);
        
        // Test JSON serialization
        String json = request.toJSON();
        System.assert(json.contains(testCase.Subject));
        System.assert(json.contains('"salesforceId":"' + testCase.Id + '"'));
    }
    
    @isTest
    static void testResponseDeserialization() {
        String successJson = '{"success":true,"ticketId":"TKT-99999","status":"Created","message":"Success"}';
        ExternalTicketResponse response = ExternalTicketResponse.parse(successJson);
        
        System.assert(response.isSuccess());
        System.assertEquals('TKT-99999', response.ticketId);
        System.assertEquals('Created', response.status);
        
        String errorJson = '{"success":false,"message":"Error occurred","errors":["Field validation failed","Invalid priority"]}';
        ExternalTicketResponse errorResponse = ExternalTicketResponse.parse(errorJson);
        
        System.assert(!errorResponse.isSuccess());
        System.assert(errorResponse.getErrorMessage().contains('Field validation failed'));
        System.assert(errorResponse.getErrorMessage().contains('Invalid priority'));
    }
    
    // Mock implementation for multiple responses
    public class MultipleMockResponse implements HttpCalloutMock {
        private Integer callCount = 0;
        
        public HTTPResponse respond(HTTPRequest req) {
            callCount++;
            
            if (callCount == 1) {
                return CaseSyncServiceMock.createSuccessMock('TKT-001').respond(req);
            } else if (callCount == 2) {
                return CaseSyncServiceMock.createErrorMock('Validation failed').respond(req);
            } else {
                return CaseSyncServiceMock.createSuccessMock('TKT-003').respond(req);
            }
        }
    }
}