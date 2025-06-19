@isTest
public class CaseSyncServiceMock implements HttpCalloutMock {
    
    private Integer statusCode;
    private String status;
    private String responseBody;
    
    public CaseSyncServiceMock(Integer statusCode, String status, String responseBody) {
        this.statusCode = statusCode;
        this.status = status;
        this.responseBody = responseBody;
    }
    
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(statusCode);
        res.setStatus(status);
        res.setBody(responseBody);
        return res;
    }
    
    // Helper methods to create common mock scenarios
    public static CaseSyncServiceMock createSuccessMock(String ticketId) {
        ExternalTicketResponse response = new ExternalTicketResponse();
        response.success = true;
        response.ticketId = ticketId;
        response.status = 'Created';
        response.message = 'Ticket created successfully';
        
        return new CaseSyncServiceMock(201, 'Created', JSON.serialize(response));
    }
    
    public static CaseSyncServiceMock createErrorMock(String errorMessage) {
        ExternalTicketResponse response = new ExternalTicketResponse();
        response.success = false;
        response.message = errorMessage;
        response.errorCode = 'ERR001';
        response.errors = new List<String>{ errorMessage };
        
        return new CaseSyncServiceMock(400, 'Bad Request', JSON.serialize(response));
    }
    
    public static CaseSyncServiceMock createServerErrorMock() {
        return new CaseSyncServiceMock(500, 'Internal Server Error', 
            '{"error": "Internal server error", "message": "The server encountered an unexpected condition"}');
    }
    
    public static CaseSyncServiceMock createTimeoutMock() {
        return new CaseSyncServiceMock(408, 'Request Timeout', '');
    }
    
    public static CaseSyncServiceMock createUnauthorizedMock() {
        ExternalTicketResponse response = new ExternalTicketResponse();
        response.success = false;
        response.message = 'Unauthorized access';
        response.errorCode = 'AUTH001';
        
        return new CaseSyncServiceMock(401, 'Unauthorized', JSON.serialize(response));
    }
}