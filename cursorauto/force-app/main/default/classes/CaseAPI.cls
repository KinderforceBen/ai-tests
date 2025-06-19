@RestResource(urlMapping='/CaseAPI/v1/create')
global with sharing class CaseAPI {
    
    /**
     * Wrapper class for incoming JSON payload
     */
    global class CaseRequest {
        public String subject;
        public String description;
        public String priority;
        public String contactEmail;
    }
    
    /**
     * Response wrapper class
     */
    global class CaseResponse {
        public Boolean success;
        public String caseId;
        public List<String> errors;
        
        public CaseResponse(Boolean success, String caseId) {
            this.success = success;
            this.caseId = caseId;
            this.errors = new List<String>();
        }
        
        public CaseResponse(Boolean success, List<String> errors) {
            this.success = success;
            this.caseId = null;
            this.errors = errors;
        }
    }
    
    /**
     * POST handler for creating cases from external systems
     * @return CaseResponse JSON with success status and case ID or errors
     */
    @HttpPost
    global static CaseResponse createCase() {
        try {
            // Get the request body
            RestRequest request = RestContext.request;
            String requestBody = request.requestBody.toString();
            
            // Parse JSON into wrapper class
            CaseRequest caseRequest = (CaseRequest) JSON.deserialize(requestBody, CaseRequest.class);
            
            // Validate required fields
            List<String> validationErrors = validateRequest(caseRequest);
            if (!validationErrors.isEmpty()) {
                return new CaseResponse(false, validationErrors);
            }
            
            // Query for Contact by email
            Id contactId = null;
            if (String.isNotBlank(caseRequest.contactEmail)) {
                List<Contact> contacts = [
                    SELECT Id 
                    FROM Contact 
                    WHERE Email = :caseRequest.contactEmail 
                    LIMIT 1
                ];
                if (!contacts.isEmpty()) {
                    contactId = contacts[0].Id;
                }
            }
            
            // Create the Case
            Case newCase = new Case(
                Subject = caseRequest.subject,
                Description = caseRequest.description,
                Priority = caseRequest.priority,
                ContactId = contactId
            );
            
            // Insert the case
            insert newCase;
            
            // Return success response
            return new CaseResponse(true, newCase.Id);
            
        } catch (JSONException e) {
            // Handle JSON parsing errors
            return new CaseResponse(false, new List<String>{'Invalid JSON format: ' + e.getMessage()});
        } catch (DmlException e) {
            // Handle database errors
            List<String> errors = new List<String>();
            for (Database.Error error : e.getDmlErrors()) {
                errors.add(error.getMessage());
            }
            return new CaseResponse(false, errors);
        } catch (Exception e) {
            // Handle any other unexpected errors
            return new CaseResponse(false, new List<String>{'Unexpected error: ' + e.getMessage()});
        }
    }
    
    /**
     * Validates the incoming request
     * @param caseRequest The parsed request object
     * @return List of validation error messages
     */
    private static List<String> validateRequest(CaseRequest caseRequest) {
        List<String> errors = new List<String>();
        
        if (caseRequest == null) {
            errors.add('Request body is required');
            return errors;
        }
        
        if (String.isBlank(caseRequest.subject)) {
            errors.add('Subject is required');
        }
        
        if (String.isBlank(caseRequest.description)) {
            errors.add('Description is required');
        }
        
        if (String.isBlank(caseRequest.priority)) {
            errors.add('Priority is required');
        } else {
            // Validate priority values
            Set<String> validPriorities = new Set<String>{'Low', 'Medium', 'High', 'Critical'};
            if (!validPriorities.contains(caseRequest.priority)) {
                errors.add('Priority must be one of: Low, Medium, High, Critical');
            }
        }
        
        if (String.isNotBlank(caseRequest.contactEmail)) {
            // Basic email validation
            String emailRegex = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
            Pattern emailPattern = Pattern.compile(emailRegex);
            if (!emailPattern.matcher(caseRequest.contactEmail).matches()) {
                errors.add('Invalid email format');
            }
        }
        
        return errors;
    }
} 