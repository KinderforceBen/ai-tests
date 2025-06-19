public with sharing class CaseSyncService implements ICaseSyncService {
    
    // Named Credential should be configured in Setup
    private static final String NAMED_CREDENTIAL = 'callout:External_Ticketing_System';
    private static final String ENDPOINT = '/api/v1/tickets';
    
    public ExternalTicketResponse syncCase(Case caseRecord) {
        ExternalTicketResponse response = new ExternalTicketResponse();
        
        try {
            // Query case with related fields
            Case caseWithDetails = queryCaseWithDetails(caseRecord.Id);
            
            // Create request
            ExternalTicketRequest request = ExternalTicketRequest.fromCase(caseWithDetails);
            
            // Make callout
            HttpRequest httpReq = new HttpRequest();
            httpReq.setEndpoint(NAMED_CREDENTIAL + ENDPOINT);
            httpReq.setMethod('POST');
            httpReq.setHeader('Content-Type', 'application/json');
            httpReq.setHeader('Accept', 'application/json');
            httpReq.setBody(request.toJSON());
            httpReq.setTimeout(60000); // 60 seconds
            
            Http http = new Http();
            HttpResponse httpRes = http.send(httpReq);
            
            // Process response
            if (httpRes.getStatusCode() == 200 || httpRes.getStatusCode() == 201) {
                response = ExternalTicketResponse.parse(httpRes.getBody());
            } else {
                response.success = false;
                response.errorCode = String.valueOf(httpRes.getStatusCode());
                response.message = 'HTTP Error: ' + httpRes.getStatus();
                
                // Try to parse error response if available
                try {
                    ExternalTicketResponse errorResponse = ExternalTicketResponse.parse(httpRes.getBody());
                    if (errorResponse.errors != null && !errorResponse.errors.isEmpty()) {
                        response.errors = errorResponse.errors;
                    } else if (String.isNotBlank(errorResponse.message)) {
                        response.message = errorResponse.message;
                    }
                } catch (Exception parseEx) {
                    // If parsing fails, keep the original error message
                }
            }
            
        } catch (Exception e) {
            response.success = false;
            response.message = 'Exception: ' + e.getMessage();
            response.errors.add(e.getStackTraceString());
            System.debug('Error syncing case: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
        
        return response;
    }
    
    public List<CaseSyncResult> syncCases(List<Case> cases) {
        List<CaseSyncResult> results = new List<CaseSyncResult>();
        
        for (Case c : cases) {
            CaseSyncResult result = new CaseSyncResult(c.Id);
            
            try {
                ExternalTicketResponse response = syncCase(c);
                result.success = response.isSuccess();
                result.ticketId = response.ticketId;
                
                if (!result.success) {
                    result.errorMessage = response.getErrorMessage();
                }
            } catch (Exception e) {
                result.success = false;
                result.errorMessage = 'Exception: ' + e.getMessage();
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    private Case queryCaseWithDetails(Id caseId) {
        return [
            SELECT Id, Subject, Description, Priority, Status, CaseNumber, 
                   Origin, ContactId, Contact.Email, Contact.Name,
                   AccountId, Account.Name, CreatedDate,
                   External_Ticket_ID__c, Sync_Status__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
    }
}