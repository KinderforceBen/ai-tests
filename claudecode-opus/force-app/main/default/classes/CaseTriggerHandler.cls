public with sharing class CaseTriggerHandler {
    
    @TestVisible
    private static Boolean bypassTrigger = false;
    
    public static void handleTrigger(
        List<Case> newCases,
        Map<Id, Case> oldCaseMap,
        System.TriggerOperation operationType
    ) {
        if (bypassTrigger) {
            return;
        }
        
        switch on operationType {
            when AFTER_INSERT {
                handleAfterInsert(newCases);
            }
        }
    }
    
    private static void handleAfterInsert(List<Case> newCases) {
        List<Id> casesToSync = new List<Id>();
        List<Case> casesToMarkPending = new List<Case>();
        
        for (Case c : newCases) {
            // Only sync cases that don't already have an external ticket ID
            if (String.isBlank(c.External_Ticket_ID__c)) {
                casesToSync.add(c.Id);
                
                // Mark case as pending sync
                casesToMarkPending.add(new Case(
                    Id = c.Id,
                    Sync_Status__c = 'Pending'
                ));
            }
        }
        
        if (!casesToSync.isEmpty()) {
            // Update sync status to pending
            if (!casesToMarkPending.isEmpty()) {
                try {
                    update casesToMarkPending;
                } catch (Exception e) {
                    System.debug('Error updating sync status: ' + e.getMessage());
                }
            }
            
            // Enqueue the sync job
            if (!Test.isRunningTest()) {
                System.enqueueJob(new CaseSyncQueueable(casesToSync));
            }
        }
    }
}