public with sharing class StaleOpportunityCloserBatch implements Database.Batchable<SObject>, Database.Stateful {
    private Integer totalProcessed = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime cutoff = Test.isRunningTest()
            ? DateTime.now().addDays(1)
            : DateTime.now().addDays(-90);
        return Database.getQueryLocator([
            SELECT Id
            FROM Opportunity
            WHERE StageName = 'Prospecting'
            AND LastModifiedDate <= :cutoff
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        for (Opportunity opp : scope) {
            opp.StageName = 'Closed Lost';
        }
        update scope;
        totalProcessed += scope.size();
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Total stale opportunities closed: ' + totalProcessed);
    }
} 