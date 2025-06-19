global with sharing class CaseAPI {
    @RestResource(urlMapping='/CaseAPI/v1/create')
    global class Service {
        @HttpPost
        global static void createCase() {
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;
            try {
                // Parse incoming JSON
                CaseRequest data = (CaseRequest) JSON.deserialize(req.requestBody.toString(), CaseRequest.class);
                // Query contact by email
                List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = :data.ContactEmail LIMIT 1];
                // Build case record
                Case c = new Case(
                    Subject = data.Subject,
                    Description = data.Description,
                    Priority = data.Priority
                );
                if (!contacts.isEmpty()) {
                    c.ContactId = contacts[0].Id;
                }
                insert c;
                // Success response
                res.statusCode = 200;
                res.responseBody = Blob.valueOf(JSON.serialize(new CaseResponse(true, c.Id, null)));
            } catch (Exception e) {
                // Error response
                List<String> errors = new List<String>{ e.getMessage() };
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(new CaseResponse(false, null, errors)));
            }
        }
    }

    global class CaseRequest {
        public String Subject;
        public String Description;
        public String Priority;
        public String ContactEmail;
    }

    global class CaseResponse {
        public Boolean success;
        public Id caseId;
        public List<String> errors;
        global CaseResponse(Boolean success, Id caseId, List<String> errors) {
            this.success = success;
            this.caseId = caseId;
            this.errors = errors;
        }
    }
} 