@isTest
private class CaseSyncQueueableTest {
    
    @TestSetup
    static void setup() {
        // Create test cases
        List<Case> testCases = new List<Case>();
        for (Integer i = 0; i < 10; i++) {
            testCases.add(new Case(
                Subject = 'Test Case ' + i,
                Description = 'Test Description ' + i,
                Priority = 'High',
                Status = 'New',
                Sync_Status__c = 'Pending'
            ));
        }
        insert testCases;
    }
    
    @isTest
    static void testSuccessfulQueueableExecution() {
        List<Case> testCases = [SELECT Id FROM Case LIMIT 3];
        List<Id> caseIds = new List<Id>();
        for (Case c : testCases) {
            caseIds.add(c.Id);
        }
        
        // Create mock sync service
        MockCaseSyncService mockService = new MockCaseSyncService(true);
        CaseSyncQueueable queueable = new CaseSyncQueueable(caseIds, mockService);
        
        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Verify cases were updated
        List<Case> updatedCases = [
            SELECT Id, External_Ticket_ID__c, Sync_Status__c, Sync_Error_Message__c
            FROM Case
            WHERE Id IN :caseIds
        ];
        
        for (Case c : updatedCases) {
            System.assertEquals('Synced', c.Sync_Status__c, 'Case should be marked as Synced');
            System.assertNotEquals(null, c.External_Ticket_ID__c, 'External ticket ID should be populated');
            System.assertEquals(null, c.Sync_Error_Message__c, 'Error message should be null for successful sync');
        }
    }
    
    @isTest
    static void testFailedQueueableExecution() {
        List<Case> testCases = [SELECT Id FROM Case LIMIT 2];
        List<Id> caseIds = new List<Id>();
        for (Case c : testCases) {
            caseIds.add(c.Id);
        }
        
        // Create mock sync service that returns failures
        MockCaseSyncService mockService = new MockCaseSyncService(false);
        CaseSyncQueueable queueable = new CaseSyncQueueable(caseIds, mockService);
        
        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Verify cases were marked as failed
        List<Case> updatedCases = [
            SELECT Id, External_Ticket_ID__c, Sync_Status__c, Sync_Error_Message__c
            FROM Case
            WHERE Id IN :caseIds
        ];
        
        for (Case c : updatedCases) {
            System.assertEquals('Failed', c.Sync_Status__c, 'Case should be marked as Failed');
            System.assertEquals(null, c.External_Ticket_ID__c, 'External ticket ID should be null for failed sync');
            System.assertNotEquals(null, c.Sync_Error_Message__c, 'Error message should be populated for failed sync');
        }
    }
    
    @isTest
    static void testMixedResultsQueueable() {
        List<Case> testCases = [SELECT Id FROM Case LIMIT 4];
        List<Id> caseIds = new List<Id>();
        for (Case c : testCases) {
            caseIds.add(c.Id);
        }
        
        // Create mock sync service with mixed results
        MockCaseSyncService mockService = new MockCaseSyncService(null); // Mixed results
        CaseSyncQueueable queueable = new CaseSyncQueueable(caseIds, mockService);
        
        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Verify mixed results
        List<Case> updatedCases = [
            SELECT Id, External_Ticket_ID__c, Sync_Status__c
            FROM Case
            WHERE Id IN :caseIds
        ];
        
        Integer syncedCount = 0;
        Integer failedCount = 0;
        
        for (Case c : updatedCases) {
            if (c.Sync_Status__c == 'Synced') {
                syncedCount++;
            } else if (c.Sync_Status__c == 'Failed') {
                failedCount++;
            }
        }
        
        System.assert(syncedCount > 0, 'Should have at least one synced case');
        System.assert(failedCount > 0, 'Should have at least one failed case');
    }
    
    @isTest
    static void testEmptyQueueable() {
        CaseSyncQueueable queueable = new CaseSyncQueueable(new List<Id>());
        
        Test.startTest();
        // Should not throw exception
        queueable.execute(null);
        Test.stopTest();
        
        System.assert(true, 'Empty queueable should execute without errors');
    }
    
    @isTest
    static void testAlreadySyncedCases() {
        // Update cases to have external ticket IDs
        List<Case> testCases = [SELECT Id FROM Case LIMIT 2];
        for (Case c : testCases) {
            c.External_Ticket_ID__c = 'TKT-EXISTING-' + c.Id;
        }
        update testCases;
        
        List<Id> caseIds = new List<Id>();
        for (Case c : testCases) {
            caseIds.add(c.Id);
        }
        
        MockCaseSyncService mockService = new MockCaseSyncService(true);
        CaseSyncQueueable queueable = new CaseSyncQueueable(caseIds, mockService);
        
        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Verify no sync occurred (external ticket ID unchanged)
        List<Case> unchangedCases = [
            SELECT Id, External_Ticket_ID__c
            FROM Case
            WHERE Id IN :caseIds
        ];
        
        for (Case c : unchangedCases) {
            System.assert(c.External_Ticket_ID__c.startsWith('TKT-EXISTING'), 
                         'Already synced cases should not be re-synced');
        }
    }
    
    // Mock implementation of ICaseSyncService for testing
    public class MockCaseSyncService implements ICaseSyncService {
        private Boolean shouldSucceed;
        private Integer callCount = 0;
        
        public MockCaseSyncService(Boolean shouldSucceed) {
            this.shouldSucceed = shouldSucceed;
        }
        
        public ExternalTicketResponse syncCase(Case caseRecord) {
            ExternalTicketResponse response = new ExternalTicketResponse();
            
            if (shouldSucceed == null) {
                // Mixed results - alternate between success and failure
                callCount++;
                response.success = Math.mod(callCount, 2) == 1;
            } else {
                response.success = shouldSucceed;
            }
            
            if (response.success) {
                response.ticketId = 'TKT-TEST-' + caseRecord.Id;
                response.status = 'Created';
            } else {
                response.message = 'Mock sync failure';
                response.errors.add('Test error message');
            }
            
            return response;
        }
        
        public List<CaseSyncResult> syncCases(List<Case> cases) {
            List<CaseSyncResult> results = new List<CaseSyncResult>();
            
            for (Case c : cases) {
                CaseSyncResult result = new CaseSyncResult(c.Id);
                ExternalTicketResponse response = syncCase(c);
                
                result.success = response.isSuccess();
                result.ticketId = response.ticketId;
                
                if (!result.success) {
                    result.errorMessage = response.getErrorMessage();
                }
                
                results.add(result);
            }
            
            return results;
        }
    }
}