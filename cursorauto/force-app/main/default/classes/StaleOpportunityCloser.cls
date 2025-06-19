public class StaleOpportunityCloser implements Database.Batchable<sObject> {
    
    /**
     * Start method to query for stale opportunities
     * @param context The batchable context
     * @return Database.QueryLocator for opportunities that meet the stale criteria
     */
    public Database.QueryLocator start(Database.BatchableContext context) {
        // Query for opportunities that are in 'Prospecting' stage and haven't been modified in 90 days
        return Database.getQueryLocator([
            SELECT Id, Name, StageName, LastModifiedDate, CloseDate
            FROM Opportunity 
            WHERE StageName = 'Prospecting' 
            AND LastModifiedDate <= :Date.today().addDays(-90)
        ]);
    }
    
    /**
     * Execute method to process each batch of stale opportunities
     * @param context The batchable context
     * @param scope List of opportunities to process
     */
    public void execute(Database.BatchableContext context, List<Opportunity> scope) {
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        
        for (Opportunity opp : scope) {
            // Update the opportunity to 'Closed Lost' stage
            opp.StageName = 'Closed Lost';
            opp.CloseDate = Date.today(); // Set close date to today
            opportunitiesToUpdate.add(opp);
        }
        
        // Update the opportunities
        if (!opportunitiesToUpdate.isEmpty()) {
            try {
                update opportunitiesToUpdate;
            } catch (Exception e) {
                System.debug('Error updating stale opportunities: ' + e.getMessage());
                throw e;
            }
        }
    }
    
    /**
     * Finish method to log the completion of the batch job
     * @param context The batchable context
     */
    public void finish(Database.BatchableContext context) {
        // Get the job information
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, 
                   TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob 
            WHERE Id = :context.getJobId()
        ];
        
        // Log the results
        System.debug('Stale Opportunity Closer Batch Job Completed');
        System.debug('Job ID: ' + job.Id);
        System.debug('Status: ' + job.Status);
        System.debug('Total records processed: ' + job.TotalJobItems);
        System.debug('Records with errors: ' + job.NumberOfErrors);
        System.debug('Records successfully processed: ' + job.JobItemsProcessed);
    }
} 