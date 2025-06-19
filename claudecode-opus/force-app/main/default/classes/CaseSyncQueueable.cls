public class CaseSyncQueueable implements Queueable, Database.AllowsCallouts {
    
    private List<Id> caseIds;
    private ICaseSyncService syncService;
    
    public CaseSyncQueueable(List<Id> caseIds) {
        this(caseIds, new CaseSyncService());
    }
    
    @TestVisible
    private CaseSyncQueueable(List<Id> caseIds, ICaseSyncService syncService) {
        this.caseIds = caseIds;
        this.syncService = syncService;
    }
    
    public void execute(QueueableContext context) {
        if (caseIds == null || caseIds.isEmpty()) {
            return;
        }
        
        // Query cases that need syncing
        List<Case> casesToSync = [
            SELECT Id, Subject, Description, Priority, Status, CaseNumber,
                   Origin, ContactId, AccountId, CreatedDate,
                   External_Ticket_ID__c, Sync_Status__c
            FROM Case
            WHERE Id IN :caseIds
            AND External_Ticket_ID__c = null
        ];
        
        if (casesToSync.isEmpty()) {
            return;
        }
        
        // Sync cases
        List<CaseSyncResult> results = syncService.syncCases(casesToSync);
        
        // Process results and update cases
        List<Case> casesToUpdate = new List<Case>();
        Map<Id, CaseSyncResult> resultsByCase = new Map<Id, CaseSyncResult>();
        
        for (CaseSyncResult result : results) {
            resultsByCase.put(result.caseId, result);
        }
        
        for (Case c : casesToSync) {
            CaseSyncResult result = resultsByCase.get(c.Id);
            if (result != null) {
                Case caseToUpdate = new Case(Id = c.Id);
                
                if (result.success) {
                    caseToUpdate.External_Ticket_ID__c = result.ticketId;
                    caseToUpdate.Sync_Status__c = 'Synced';
                    caseToUpdate.Sync_Error_Message__c = null;
                } else {
                    caseToUpdate.Sync_Status__c = 'Failed';
                    caseToUpdate.Sync_Error_Message__c = result.errorMessage;
                }
                
                casesToUpdate.add(caseToUpdate);
            }
        }
        
        if (!casesToUpdate.isEmpty()) {
            // Use Database.update to allow partial success
            Database.SaveResult[] saveResults = Database.update(casesToUpdate, false);
            
            // Log any update failures
            for (Integer i = 0; i < saveResults.size(); i++) {
                if (!saveResults[i].isSuccess()) {
                    System.debug('Failed to update case ' + casesToUpdate[i].Id + ': ' + 
                               saveResults[i].getErrors()[0].getMessage());
                }
            }
        }
        
        // Chain next batch if there are more cases
        if (caseIds.size() > casesToSync.size()) {
            // Some cases were already synced, check if there are more to process
            Integer remainingCount = [SELECT COUNT() FROM Case WHERE Sync_Status__c = 'Pending' LIMIT 1];
            if (remainingCount > 0) {
                List<Case> nextBatch = [
                    SELECT Id FROM Case 
                    WHERE Sync_Status__c = 'Pending' 
                    LIMIT 50
                ];
                
                if (!nextBatch.isEmpty()) {
                    List<Id> nextCaseIds = new List<Id>();
                    for (Case c : nextBatch) {
                        nextCaseIds.add(c.Id);
                    }
                    
                    if (!Test.isRunningTest()) {
                        System.enqueueJob(new CaseSyncQueueable(nextCaseIds));
                    }
                }
            }
        }
    }
}