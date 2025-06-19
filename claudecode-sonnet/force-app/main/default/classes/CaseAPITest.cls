@isTest
public class CaseAPITest {
    
    @testSetup
    static void setupTestData() {
        // Create test Account and Contact
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test.contact@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        // Create another contact for testing
        Contact testContact2 = new Contact(
            FirstName = 'Another',
            LastName = 'Contact',
            Email = 'another.contact@example.com',
            AccountId = testAccount.Id
        );
        insert testContact2;
    }
    
    @isTest
    static void testCreateCaseSuccess() {
        // Prepare request JSON with existing contact email
        String requestJson = '{"Subject": "Test Case Subject", "Description": "Test case description", "Priority": "High", "ContactEmail": "test.contact@example.com"}';
        
        // Set up REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestJson);
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        
        // Call the API method
        CaseAPI.ResponseWrapper response = CaseAPI.createCase();
        
        Test.stopTest();
        
        // Verify successful response
        System.assertEquals(true, response.success, 'Response should be successful');
        System.assertNotEquals(null, response.caseId, 'Case ID should be returned');
        System.assertEquals(0, response.errors.size(), 'No errors should be present');
        
        // Verify Case was created correctly
        Case createdCase = [SELECT Id, Subject, Description, Priority, ContactId FROM Case WHERE Id = :response.caseId];
        System.assertEquals('Test Case Subject', createdCase.Subject, 'Subject should match');
        System.assertEquals('Test case description', createdCase.Description, 'Description should match');
        System.assertEquals('High', createdCase.Priority, 'Priority should match');
        System.assertNotEquals(null, createdCase.ContactId, 'Contact should be linked');
        
        // Verify the correct contact was linked
        Contact linkedContact = [SELECT Email FROM Contact WHERE Id = :createdCase.ContactId];
        System.assertEquals('test.contact@example.com', linkedContact.Email, 'Correct contact should be linked');
    }
    
    @isTest
    static void testCreateCaseWithoutExistingContact() {
        // Prepare request JSON with non-existing contact email
        String requestJson = '{"Subject": "Test Case Subject", "Description": "Test case description", "Priority": "Low", "ContactEmail": "nonexistent@example.com"}';
        
        // Set up REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestJson);
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        
        // Call the API method
        CaseAPI.ResponseWrapper response = CaseAPI.createCase();
        
        Test.stopTest();
        
        // Verify successful response (case should still be created)
        System.assertEquals(true, response.success, 'Response should be successful');
        System.assertNotEquals(null, response.caseId, 'Case ID should be returned');
        System.assertEquals(0, response.errors.size(), 'No errors should be present');
        
        // Verify Case was created without ContactId
        Case createdCase = [SELECT Id, Subject, Description, Priority, ContactId FROM Case WHERE Id = :response.caseId];
        System.assertEquals('Test Case Subject', createdCase.Subject, 'Subject should match');
        System.assertEquals('Test case description', createdCase.Description, 'Description should match');
        System.assertEquals('Low', createdCase.Priority, 'Priority should match');
        System.assertEquals(null, createdCase.ContactId, 'Contact should not be linked');
    }
    
    @isTest
    static void testCreateCaseWithDefaultPriority() {
        // Prepare request JSON without Priority field
        String requestJson = '{"Subject": "Test Case Subject", "Description": "Test case description", "ContactEmail": "test.contact@example.com"}';
        
        // Set up REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestJson);
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        
        // Call the API method
        CaseAPI.ResponseWrapper response = CaseAPI.createCase();
        
        Test.stopTest();
        
        // Verify successful response
        System.assertEquals(true, response.success, 'Response should be successful');
        
        // Verify Case was created with default priority
        Case createdCase = [SELECT Priority FROM Case WHERE Id = :response.caseId];
        System.assertEquals('Medium', createdCase.Priority, 'Priority should default to Medium');
    }
    
    @isTest
    static void testCreateCaseMissingSubject() {
        // Prepare request JSON without required Subject field
        String requestJson = '{"Description": "Test case description", "Priority": "High", "ContactEmail": "test.contact@example.com"}';
        
        // Set up REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestJson);
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        
        // Call the API method
        CaseAPI.ResponseWrapper response = CaseAPI.createCase();
        
        Test.stopTest();
        
        // Verify error response
        System.assertEquals(false, response.success, 'Response should indicate failure');
        System.assertEquals(null, response.caseId, 'No case ID should be returned');
        System.assertEquals(1, response.errors.size(), 'One error should be present');
        System.assert(response.errors[0].contains('Subject is required'), 'Error should mention missing Subject');
        
        // Verify no Case was created
        List<Case> cases = [SELECT Id FROM Case];
        System.assertEquals(0, cases.size(), 'No cases should be created');
    }
    
    @isTest
    static void testCreateCaseMissingContactEmail() {
        // Prepare request JSON without required ContactEmail field
        String requestJson = '{"Subject": "Test Case Subject", "Description": "Test case description", "Priority": "High"}';
        
        // Set up REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestJson);
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        
        // Call the API method
        CaseAPI.ResponseWrapper response = CaseAPI.createCase();
        
        Test.stopTest();
        
        // Verify error response
        System.assertEquals(false, response.success, 'Response should indicate failure');
        System.assertEquals(null, response.caseId, 'No case ID should be returned');
        System.assertEquals(1, response.errors.size(), 'One error should be present');
        System.assert(response.errors[0].contains('ContactEmail is required'), 'Error should mention missing ContactEmail');
        
        // Verify no Case was created
        List<Case> cases = [SELECT Id FROM Case];
        System.assertEquals(0, cases.size(), 'No cases should be created');
    }
    
    @isTest
    static void testCreateCaseMultipleValidationErrors() {
        // Prepare request JSON missing both required fields
        String requestJson = '{"Description": "Test case description", "Priority": "High"}';
        
        // Set up REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestJson);
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        
        // Call the API method
        CaseAPI.ResponseWrapper response = CaseAPI.createCase();
        
        Test.stopTest();
        
        // Verify error response
        System.assertEquals(false, response.success, 'Response should indicate failure');
        System.assertEquals(null, response.caseId, 'No case ID should be returned');
        System.assertEquals(2, response.errors.size(), 'Two errors should be present');
        
        // Verify both error messages are present
        String allErrors = String.join(response.errors, ' ');
        System.assert(allErrors.contains('Subject is required'), 'Error should mention missing Subject');
        System.assert(allErrors.contains('ContactEmail is required'), 'Error should mention missing ContactEmail');
    }
    
    @isTest
    static void testCreateCaseInvalidJSON() {
        // Prepare invalid JSON
        String requestJson = '{"Subject": "Test Case Subject", "Description": "Test case description", "Priority": "High", "ContactEmail": "test.contact@example.com"'; // Missing closing brace
        
        // Set up REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestJson);
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        
        // Call the API method
        CaseAPI.ResponseWrapper response = CaseAPI.createCase();
        
        Test.stopTest();
        
        // Verify error response
        System.assertEquals(false, response.success, 'Response should indicate failure');
        System.assertEquals(null, response.caseId, 'No case ID should be returned');
        System.assertEquals(1, response.errors.size(), 'One error should be present');
        System.assert(response.errors[0].contains('Invalid JSON format'), 'Error should mention invalid JSON');
        
        // Verify no Case was created
        List<Case> cases = [SELECT Id FROM Case];
        System.assertEquals(0, cases.size(), 'No cases should be created');
    }
    
    @isTest
    static void testCreateCaseMinimalValidRequest() {
        // Prepare request JSON with only required fields
        String requestJson = '{"Subject": "Minimal Test Case", "ContactEmail": "another.contact@example.com"}';
        
        // Set up REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestJson);
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        
        // Call the API method
        CaseAPI.ResponseWrapper response = CaseAPI.createCase();
        
        Test.stopTest();
        
        // Verify successful response
        System.assertEquals(true, response.success, 'Response should be successful');
        System.assertNotEquals(null, response.caseId, 'Case ID should be returned');
        
        // Verify Case was created with minimal data
        Case createdCase = [SELECT Subject, Description, Priority, ContactId FROM Case WHERE Id = :response.caseId];
        System.assertEquals('Minimal Test Case', createdCase.Subject, 'Subject should match');
        System.assertEquals(null, createdCase.Description, 'Description should be null');
        System.assertEquals('Medium', createdCase.Priority, 'Priority should default to Medium');
        System.assertNotEquals(null, createdCase.ContactId, 'Contact should be linked');
        
        // Verify the correct contact was linked
        Contact linkedContact = [SELECT Email FROM Contact WHERE Id = :createdCase.ContactId];
        System.assertEquals('another.contact@example.com', linkedContact.Email, 'Correct contact should be linked');
    }
}