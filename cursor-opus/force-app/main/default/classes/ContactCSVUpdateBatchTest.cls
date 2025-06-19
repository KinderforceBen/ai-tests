/**
 * Test class for ContactCSVUpdateBatch
 * Tests both all-success and partial-failure scenarios
 */
@isTest
private class ContactCSVUpdateBatchTest {
    
    /**
     * Mock HTTP Service for testing
     */
    private class MockHttpService implements IHttpService {
        private String responseBody;
        private Integer statusCode;
        
        public MockHttpService(String responseBody, Integer statusCode) {
            this.responseBody = responseBody;
            this.statusCode = statusCode;
        }
        
        public HttpResponse send(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setBody(responseBody);
            response.setStatusCode(statusCode);
            return response;
        }
    }
    
    /**
     * Setup test data
     */
    @testSetup
    static void setupTestData() {
        // Create test contacts
        List<Contact> testContacts = new List<Contact>();
        
        for (Integer i = 0; i < 100; i++) {
            Contact c = new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                Email = 'test' + i + '@example.com',
                Phone = '555-000' + i
            );
            testContacts.add(c);
        }
        
        // Add some contacts with duplicate emails for error testing
        testContacts.add(new Contact(
            FirstName = 'Duplicate',
            LastName = 'Contact 1',
            Email = 'duplicate@example.com'
        ));
        
        testContacts.add(new Contact(
            FirstName = 'Duplicate',
            LastName = 'Contact 2',
            Email = 'duplicate@example.com'
        ));
        
        insert testContacts;
    }
    
    /**
     * Test successful processing of all records
     */
    @isTest
    static void testAllSuccessScenario() {
        // Create CSV content
        String csvContent = 'Email,FirstName,LastName,Phone,Title,Department\n';
        csvContent += 'test0@example.com,Updated,Contact 0,555-1111,CEO,Executive\n';
        csvContent += 'test1@example.com,Updated,Contact 1,555-2222,CTO,Technology\n';
        csvContent += 'test2@example.com,Updated,Contact 2,555-3333,CFO,Finance\n';
        
        // Create mock HTTP service
        MockHttpService mockService = new MockHttpService(csvContent, 200);
        
        // Create and execute batch
        Test.startTest();
        ContactCSVUpdateBatch batch = new ContactCSVUpdateBatch('https://example.com/csv', mockService);
        Id batchId = Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify results
        List<Contact> updatedContacts = [SELECT FirstName, LastName, Phone, Title, Department 
                                        FROM Contact 
                                        WHERE Email IN ('test0@example.com', 'test1@example.com', 'test2@example.com')
                                        ORDER BY Email];
        
        System.assertEquals(3, updatedContacts.size(), 'Should have 3 updated contacts');
        System.assertEquals('Updated', updatedContacts[0].FirstName, 'First name should be updated');
        System.assertEquals('555-1111', updatedContacts[0].Phone, 'Phone should be updated');
        System.assertEquals('CEO', updatedContacts[0].Title, 'Title should be updated');
        
        // Verify success logs
        List<CSV_Processing_Result__c> successLogs = [SELECT Id FROM CSV_Processing_Result__c 
                                                     WHERE Status__c = 'Success' AND Batch_Job_Id__c = :batchId];
        System.assertEquals(3, successLogs.size(), 'Should have 3 success logs');
        
        // Verify no error logs
        List<CSV_Processing_Result__c> errorLogs = [SELECT Id FROM CSV_Processing_Result__c 
                                                   WHERE Status__c = 'Error' AND Batch_Job_Id__c = :batchId];
        System.assertEquals(0, errorLogs.size(), 'Should have no error logs');
    }
    
    /**
     * Test partial failure scenario
     */
    @isTest
    static void testPartialFailureScenario() {
        // Create CSV content with some problematic records
        String csvContent = 'Email,FirstName,LastName,Phone,Title\n';
        csvContent += 'test0@example.com,Updated,Contact 0,555-1111,CEO\n';  // Valid
        csvContent += ',Missing,Email,555-2222,CTO\n';  // Missing email
        csvContent += 'nonexistent@example.com,New,Contact,555-3333,CFO\n';  // Contact doesn't exist
        csvContent += 'test1@example.com,Updated,Contact 1,INVALID_PHONE_FORMAT_THAT_IS_TOO_LONG_FOR_FIELD,Manager\n';  // Invalid phone
        
        // Create mock HTTP service
        MockHttpService mockService = new MockHttpService(csvContent, 200);
        
        // Create and execute batch
        Test.startTest();
        ContactCSVUpdateBatch batch = new ContactCSVUpdateBatch('https://example.com/csv', mockService);
        Id batchId = Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify successful update
        Contact successContact = [SELECT FirstName, Phone, Title FROM Contact WHERE Email = 'test0@example.com'];
        System.assertEquals('Updated', successContact.FirstName, 'Successful contact should be updated');
        
        // Verify error logs
        List<CSV_Processing_Result__c> errorLogs = [SELECT Error_Message__c, Row_Data__c 
                                                   FROM CSV_Processing_Result__c 
                                                   WHERE Status__c = 'Error' AND Batch_Job_Id__c = :batchId
                                                   ORDER BY Row_Number__c];
        
        System.assertEquals(3, errorLogs.size(), 'Should have 3 error logs');
        System.assert(errorLogs[0].Error_Message__c.contains('Missing email'), 'Should log missing email error');
        System.assert(errorLogs[1].Error_Message__c.contains('Contact not found'), 'Should log contact not found error');
        System.assert(errorLogs[2].Error_Message__c.contains('DML Error'), 'Should log DML error for invalid phone');
    }
    
    /**
     * Test CSV fetch failure
     */
    @isTest
    static void testCSVFetchFailure() {
        // Create mock HTTP service that returns error
        MockHttpService mockService = new MockHttpService('Error', 500);
        
        // Create and execute batch
        Test.startTest();
        ContactCSVUpdateBatch batch = new ContactCSVUpdateBatch('https://example.com/csv', mockService);
        Id batchId = Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify error was logged
        List<CSV_Processing_Result__c> errorLogs = [SELECT Error_Message__c 
                                                   FROM CSV_Processing_Result__c 
                                                   WHERE Status__c = 'Error' AND Batch_Job_Id__c = :batchId];
        
        System.assertEquals(1, errorLogs.size(), 'Should have 1 error log for fetch failure');
        System.assert(errorLogs[0].Error_Message__c.contains('Failed to fetch'), 'Should log fetch failure');
    }
    
    /**
     * Test large batch processing
     */
    @isTest
    static void testLargeBatchProcessing() {
        // Create CSV content with 50 records
        String csvContent = 'Email,FirstName,LastName,Phone\n';
        for (Integer i = 0; i < 50; i++) {
            csvContent += 'test' + i + '@example.com,Bulk' + i + ',Update' + i + ',555-999' + i + '\n';
        }
        
        // Create mock HTTP service
        MockHttpService mockService = new MockHttpService(csvContent, 200);
        
        // Create and execute batch with smaller batch size
        Test.startTest();
        ContactCSVUpdateBatch batch = new ContactCSVUpdateBatch('https://example.com/csv', mockService);
        Id batchId = Database.executeBatch(batch, 10); // Process 10 records at a time
        Test.stopTest();
        
        // Verify all records were processed
        List<Contact> updatedContacts = [SELECT Id FROM Contact WHERE FirstName LIKE 'Bulk%'];
        System.assertEquals(50, updatedContacts.size(), 'All 50 contacts should be updated');
        
        // Verify success logs
        List<CSV_Processing_Result__c> successLogs = [SELECT Id FROM CSV_Processing_Result__c 
                                                     WHERE Status__c = 'Success' AND Batch_Job_Id__c = :batchId];
        System.assertEquals(50, successLogs.size(), 'Should have 50 success logs');
    }
    
    /**
     * Test CSV with special characters and quotes
     */
    @isTest
    static void testCSVWithSpecialCharacters() {
        // Create CSV content with special characters
        String csvContent = 'Email,FirstName,LastName,Title\n';
        csvContent += 'test0@example.com,"John, Jr.",O\'Brien,"CEO, Inc."\n';
        csvContent += 'test1@example.com,Jane,"Smith ""The Great""",Manager\n';
        
        // Create mock HTTP service
        MockHttpService mockService = new MockHttpService(csvContent, 200);
        
        // Create and execute batch
        Test.startTest();
        ContactCSVUpdateBatch batch = new ContactCSVUpdateBatch('https://example.com/csv', mockService);
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify special characters were handled correctly
        Contact contact1 = [SELECT FirstName, LastName, Title FROM Contact WHERE Email = 'test0@example.com'];
        System.assertEquals('John, Jr.', contact1.FirstName, 'Should handle comma in quoted field');
        System.assertEquals('O\'Brien', contact1.LastName, 'Should handle apostrophe');
        System.assertEquals('CEO, Inc.', contact1.Title, 'Should handle comma in title');
        
        Contact contact2 = [SELECT LastName FROM Contact WHERE Email = 'test1@example.com'];
        System.assertEquals('Smith "The Great"', contact2.LastName, 'Should handle double quotes');
    }
} 