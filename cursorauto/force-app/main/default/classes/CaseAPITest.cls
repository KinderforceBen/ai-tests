@IsTest
private class CaseAPITest {
    
    /**
     * Test successful case creation with existing contact
     */
    @IsTest
    static void testSuccessfulCaseCreationWithContact() {
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com'
        );
        insert testContact;
        
        // Prepare test data
        String validJson = JSON.serialize(new Map<String, Object>{
            'subject' => 'Test Case Subject',
            'description' => 'Test case description',
            'priority' => 'High',
            'contactEmail' => 'john.doe@example.com'
        });
        
        // Mock RestContext
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(validJson);
        RestContext.request.httpMethod = 'POST';
        
        // Execute the API
        Test.startTest();
        CaseAPI.CaseResponse response = CaseAPI.createCase();
        Test.stopTest();
        
        // Verify response
        System.assert(response.success, 'Response should be successful');
        System.assertNotEquals(null, response.caseId, 'Case ID should be returned');
        System.assertEquals(0, response.errors.size(), 'No errors should be returned');
        
        // Verify case was created
        Case createdCase = [SELECT Id, Subject, Description, Priority, ContactId 
                           FROM Case 
                           WHERE Id = :response.caseId];
        System.assertEquals('Test Case Subject', createdCase.Subject);
        System.assertEquals('Test case description', createdCase.Description);
        System.assertEquals('High', createdCase.Priority);
        System.assertEquals(testContact.Id, createdCase.ContactId);
    }
    
    /**
     * Test successful case creation without contact
     */
    @IsTest
    static void testSuccessfulCaseCreationWithoutContact() {
        // Prepare test data
        String validJson = JSON.serialize(new Map<String, Object>{
            'subject' => 'Test Case Subject',
            'description' => 'Test case description',
            'priority' => 'Medium',
            'contactEmail' => 'nonexistent@example.com'
        });
        
        // Mock RestContext
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(validJson);
        RestContext.request.httpMethod = 'POST';
        
        // Execute the API
        Test.startTest();
        CaseAPI.CaseResponse response = CaseAPI.createCase();
        Test.stopTest();
        
        // Verify response
        System.assert(response.success, 'Response should be successful');
        System.assertNotEquals(null, response.caseId, 'Case ID should be returned');
        System.assertEquals(0, response.errors.size(), 'No errors should be returned');
        
        // Verify case was created without contact
        Case createdCase = [SELECT Id, Subject, Description, Priority, ContactId 
                           FROM Case 
                           WHERE Id = :response.caseId];
        System.assertEquals('Test Case Subject', createdCase.Subject);
        System.assertEquals('Test case description', createdCase.Description);
        System.assertEquals('Medium', createdCase.Priority);
        System.assertEquals(null, createdCase.ContactId);
    }
    
    /**
     * Test validation error - missing subject
     */
    @IsTest
    static void testValidationErrorMissingSubject() {
        // Prepare test data with missing subject
        String invalidJson = JSON.serialize(new Map<String, Object>{
            'description' => 'Test case description',
            'priority' => 'High',
            'contactEmail' => 'test@example.com'
        });
        
        // Mock RestContext
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(invalidJson);
        RestContext.request.httpMethod = 'POST';
        
        // Execute the API
        Test.startTest();
        CaseAPI.CaseResponse response = CaseAPI.createCase();
        Test.stopTest();
        
        // Verify response
        System.assert(!response.success, 'Response should not be successful');
        System.assertEquals(null, response.caseId, 'Case ID should be null');
        System.assertEquals(1, response.errors.size(), 'One error should be returned');
        System.assertEquals('Subject is required', response.errors[0]);
    }
    
    /**
     * Test validation error - missing description
     */
    @IsTest
    static void testValidationErrorMissingDescription() {
        // Prepare test data with missing description
        String invalidJson = JSON.serialize(new Map<String, Object>{
            'subject' => 'Test Case Subject',
            'priority' => 'High',
            'contactEmail' => 'test@example.com'
        });
        
        // Mock RestContext
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(invalidJson);
        RestContext.request.httpMethod = 'POST';
        
        // Execute the API
        Test.startTest();
        CaseAPI.CaseResponse response = CaseAPI.createCase();
        Test.stopTest();
        
        // Verify response
        System.assert(!response.success, 'Response should not be successful');
        System.assertEquals(null, response.caseId, 'Case ID should be null');
        System.assertEquals(1, response.errors.size(), 'One error should be returned');
        System.assertEquals('Description is required', response.errors[0]);
    }
    
    /**
     * Test validation error - missing priority
     */
    @IsTest
    static void testValidationErrorMissingPriority() {
        // Prepare test data with missing priority
        String invalidJson = JSON.serialize(new Map<String, Object>{
            'subject' => 'Test Case Subject',
            'description' => 'Test case description',
            'contactEmail' => 'test@example.com'
        });
        
        // Mock RestContext
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(invalidJson);
        RestContext.request.httpMethod = 'POST';
        
        // Execute the API
        Test.startTest();
        CaseAPI.CaseResponse response = CaseAPI.createCase();
        Test.stopTest();
        
        // Verify response
        System.assert(!response.success, 'Response should not be successful');
        System.assertEquals(null, response.caseId, 'Case ID should be null');
        System.assertEquals(1, response.errors.size(), 'One error should be returned');
        System.assertEquals('Priority is required', response.errors[0]);
    }
    
    /**
     * Test validation error - invalid priority
     */
    @IsTest
    static void testValidationErrorInvalidPriority() {
        // Prepare test data with invalid priority
        String invalidJson = JSON.serialize(new Map<String, Object>{
            'subject' => 'Test Case Subject',
            'description' => 'Test case description',
            'priority' => 'InvalidPriority',
            'contactEmail' => 'test@example.com'
        });
        
        // Mock RestContext
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(invalidJson);
        RestContext.request.httpMethod = 'POST';
        
        // Execute the API
        Test.startTest();
        CaseAPI.CaseResponse response = CaseAPI.createCase();
        Test.stopTest();
        
        // Verify response
        System.assert(!response.success, 'Response should not be successful');
        System.assertEquals(null, response.caseId, 'Case ID should be null');
        System.assertEquals(1, response.errors.size(), 'One error should be returned');
        System.assertEquals('Priority must be one of: Low, Medium, High, Critical', response.errors[0]);
    }
    
    /**
     * Test validation error - invalid email format
     */
    @IsTest
    static void testValidationErrorInvalidEmail() {
        // Prepare test data with invalid email
        String invalidJson = JSON.serialize(new Map<String, Object>{
            'subject' => 'Test Case Subject',
            'description' => 'Test case description',
            'priority' => 'High',
            'contactEmail' => 'invalid-email'
        });
        
        // Mock RestContext
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(invalidJson);
        RestContext.request.httpMethod = 'POST';
        
        // Execute the API
        Test.startTest();
        CaseAPI.CaseResponse response = CaseAPI.createCase();
        Test.stopTest();
        
        // Verify response
        System.assert(!response.success, 'Response should not be successful');
        System.assertEquals(null, response.caseId, 'Case ID should be null');
        System.assertEquals(1, response.errors.size(), 'One error should be returned');
        System.assertEquals('Invalid email format', response.errors[0]);
    }
    
    /**
     * Test validation error - multiple validation errors
     */
    @IsTest
    static void testValidationErrorMultipleErrors() {
        // Prepare test data with multiple missing fields
        String invalidJson = JSON.serialize(new Map<String, Object>{
            'priority' => 'InvalidPriority'
        });
        
        // Mock RestContext
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(invalidJson);
        RestContext.request.httpMethod = 'POST';
        
        // Execute the API
        Test.startTest();
        CaseAPI.CaseResponse response = CaseAPI.createCase();
        Test.stopTest();
        
        // Verify response
        System.assert(!response.success, 'Response should not be successful');
        System.assertEquals(null, response.caseId, 'Case ID should be null');
        System.assertEquals(3, response.errors.size(), 'Three errors should be returned');
        
        // Verify all expected errors are present
        Set<String> expectedErrors = new Set<String>{
            'Subject is required',
            'Description is required',
            'Priority must be one of: Low, Medium, High, Critical'
        };
        System.assertEquals(expectedErrors, new Set<String>(response.errors));
    }
    
    /**
     * Test JSON parsing error
     */
    @IsTest
    static void testJsonParsingError() {
        // Prepare invalid JSON
        String invalidJson = '{"subject": "Test", "description": "Test", "priority": "High", "contactEmail": "test@example.com"';
        
        // Mock RestContext
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(invalidJson);
        RestContext.request.httpMethod = 'POST';
        
        // Execute the API
        Test.startTest();
        CaseAPI.CaseResponse response = CaseAPI.createCase();
        Test.stopTest();
        
        // Verify response
        System.assert(!response.success, 'Response should not be successful');
        System.assertEquals(null, response.caseId, 'Case ID should be null');
        System.assertEquals(1, response.errors.size(), 'One error should be returned');
        System.assert(response.errors[0].contains('Invalid JSON format'), 'Should contain JSON parsing error');
    }
    
    /**
     * Test all valid priority values
     */
    @IsTest
    static void testAllValidPriorities() {
        List<String> validPriorities = new List<String>{'Low', 'Medium', 'High', 'Critical'};
        
        for (String priority : validPriorities) {
            // Prepare test data
            String validJson = JSON.serialize(new Map<String, Object>{
                'subject' => 'Test Case - ' + priority,
                'description' => 'Test case with ' + priority + ' priority',
                'priority' => priority
            });
            
            // Mock RestContext
            RestContext.request = new RestRequest();
            RestContext.response = new RestResponse();
            RestContext.request.requestBody = Blob.valueOf(validJson);
            RestContext.request.httpMethod = 'POST';
            
            // Execute the API
            CaseAPI.CaseResponse response = CaseAPI.createCase();
            
            // Verify response
            System.assert(response.success, 'Response should be successful for priority: ' + priority);
            System.assertNotEquals(null, response.caseId, 'Case ID should be returned for priority: ' + priority);
            System.assertEquals(0, response.errors.size(), 'No errors should be returned for priority: ' + priority);
            
            // Verify case was created with correct priority
            Case createdCase = [SELECT Id, Priority FROM Case WHERE Id = :response.caseId];
            System.assertEquals(priority, createdCase.Priority, 'Priority should match for: ' + priority);
        }
    }
} 