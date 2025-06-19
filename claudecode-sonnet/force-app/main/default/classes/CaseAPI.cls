@RestResource(urlMapping='/CaseAPI/v1/create')
global class CaseAPI {
    
    @HttpPost
    global static ResponseWrapper createCase() {
        ResponseWrapper response = new ResponseWrapper();
        
        try {
            // Get the request body
            RestRequest req = RestContext.request;
            String requestBody = req.requestBody.toString();
            
            // Parse the JSON request
            RequestWrapper requestData = (RequestWrapper) JSON.deserialize(requestBody, RequestWrapper.class);
            
            // Validate required fields
            if (String.isBlank(requestData.Subject)) {
                response.success = false;
                response.errors.add('Subject is required');
            }
            
            if (String.isBlank(requestData.ContactEmail)) {
                response.success = false;
                response.errors.add('ContactEmail is required');
            }
            
            if (!response.errors.isEmpty()) {
                return response;
            }
            
            // Create the new Case
            Case newCase = new Case();
            newCase.Subject = requestData.Subject;
            newCase.Description = requestData.Description;
            newCase.Priority = String.isNotBlank(requestData.Priority) ? requestData.Priority : 'Medium';
            
            // Look up Contact by email
            List<Contact> contacts = [
                SELECT Id 
                FROM Contact 
                WHERE Email = :requestData.ContactEmail 
                LIMIT 1
            ];
            
            if (!contacts.isEmpty()) {
                newCase.ContactId = contacts[0].Id;
            }
            
            // Insert the Case
            insert newCase;
            
            // Return success response
            response.success = true;
            response.caseId = newCase.Id;
            
        } catch (JSONException e) {
            response.success = false;
            response.errors.add('Invalid JSON format: ' + e.getMessage());
        } catch (DMLException e) {
            response.success = false;
            response.errors.add('Database error: ' + e.getMessage());
        } catch (Exception e) {
            response.success = false;
            response.errors.add('Unexpected error: ' + e.getMessage());
        }
        
        return response;
    }
    
    global class RequestWrapper {
        global String Subject { get; set; }
        global String Description { get; set; }
        global String Priority { get; set; }
        global String ContactEmail { get; set; }
    }
    
    global class ResponseWrapper {
        global Boolean success { get; set; }
        global String caseId { get; set; }
        global List<String> errors { get; set; }
        
        global ResponseWrapper() {
            this.success = false;
            this.errors = new List<String>();
        }
    }
}