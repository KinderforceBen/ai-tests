@isTest
private class CaseTriggerHandlerTest {
    
    @TestSetup
    static void setup() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;
    }
    
    @isTest
    static void testNewCaseTriggersSyncNoCallout() {
        // Bypass trigger for setup
        CaseTriggerHandler.bypassTrigger = true;
        
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        Case testCase = new Case(
            Subject = 'Test Case for Sync',
            Description = 'This case should trigger sync',
            Priority = 'High',
            Status = 'New',
            Origin = 'Web',
            ContactId = con.Id,
            AccountId = acc.Id
        );
        
        // Enable trigger
        CaseTriggerHandler.bypassTrigger = false;
        
        Test.startTest();
        insert testCase;
        Test.stopTest();
        
        // Verify sync status was set to pending
        Case updatedCase = [SELECT Id, Sync_Status__c, External_Ticket_ID__c FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('Pending', updatedCase.Sync_Status__c, 'Sync status should be Pending');
        System.assertEquals(null, updatedCase.External_Ticket_ID__c, 'External ticket ID should be null');
    }
    
    @isTest
    static void testCaseWithExistingTicketIdNotSynced() {
        CaseTriggerHandler.bypassTrigger = true;
        
        Case testCase = new Case(
            Subject = 'Already Synced Case',
            External_Ticket_ID__c = 'TKT-EXISTING'
        );
        insert testCase;
        
        // Ensure sync status is not pending
        Case insertedCase = [SELECT Id, Sync_Status__c FROM Case WHERE Id = :testCase.Id];
        System.assertNotEquals('Pending', insertedCase.Sync_Status__c, 'Already synced case should not be marked as Pending');
    }
    
    @isTest
    static void testBulkCaseInsert() {
        List<Case> testCases = new List<Case>();
        
        for (Integer i = 0; i < 50; i++) {
            testCases.add(new Case(
                Subject = 'Bulk Test Case ' + i,
                Description = 'Bulk test description ' + i,
                Priority = 'Medium',
                Status = 'New'
            ));
        }
        
        Test.startTest();
        insert testCases;
        Test.stopTest();
        
        // Verify all cases are marked as pending
        List<Case> updatedCases = [SELECT Id, Sync_Status__c FROM Case WHERE Id IN :testCases];
        System.assertEquals(50, updatedCases.size(), 'Should have 50 cases');
        
        for (Case c : updatedCases) {
            System.assertEquals('Pending', c.Sync_Status__c, 'All cases should be marked as Pending');
        }
    }
    
    @isTest
    static void testTriggerBypass() {
        CaseTriggerHandler.bypassTrigger = true;
        
        Case testCase = new Case(
            Subject = 'Bypass Test Case',
            Description = 'This should not trigger sync'
        );
        
        Test.startTest();
        insert testCase;
        Test.stopTest();
        
        // Verify sync status was NOT set
        Case insertedCase = [SELECT Id, Sync_Status__c FROM Case WHERE Id = :testCase.Id];
        System.assertNotEquals('Pending', insertedCase.Sync_Status__c, 'Bypassed trigger should not set sync status');
        
        // Reset bypass
        CaseTriggerHandler.bypassTrigger = false;
    }
}