public class StaleOpportunityCloserBatch implements Database.Batchable<SObject> {
    
    private Integer processedCount = 0;
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Calculate 90 days ago from today
        Date ninetyDaysAgo = Date.today().addDays(-90);
        
        return Database.getQueryLocator([
            SELECT Id, Name, StageName, LastModifiedDate 
            FROM Opportunity 
            WHERE StageName = 'Prospecting' 
            AND LastModifiedDate <= :ninetyDaysAgo
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        
        for (SObject record : scope) {
            Opportunity opp = (Opportunity) record;
            opp.StageName = 'Closed Lost';
            opportunitiesToUpdate.add(opp);
        }
        
        if (!opportunitiesToUpdate.isEmpty()) {
            update opportunitiesToUpdate;
            processedCount += opportunitiesToUpdate.size();
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('StaleOpportunityCloserBatch completed. Total records processed: ' + processedCount);
    }
}