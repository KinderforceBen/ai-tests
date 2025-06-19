public class StaleOpportunityCloserScheduler implements Schedulable {
    
    /**
     * Execute method for the scheduler
     * @param context The schedulable context
     */
    public void execute(SchedulableContext context) {
        // Create an instance of the batch class
        StaleOpportunityCloser batchJob = new StaleOpportunityCloser();
        
        // Execute the batch with a batch size of 200
        Database.executeBatch(batchJob, 200);
        
        System.debug('Stale Opportunity Closer batch job has been scheduled and executed.');
    }
    
    /**
     * Static method to schedule the job
     * Call this method to schedule the batch job to run nightly at 2 AM
     */
    public static void scheduleNightlyJob() {
        String cronExp = '0 0 2 * * ?'; // Runs at 2 AM every day
        String jobName = 'Stale Opportunity Closer - Nightly';
        
        // Check if the job is already scheduled
        List<CronTrigger> existingJobs = [
            SELECT Id, CronExpression, State 
            FROM CronTrigger 
            WHERE CronJobDetail.Name = :jobName
        ];
        
        if (existingJobs.isEmpty()) {
            // Schedule the job
            System.schedule(jobName, cronExp, new StaleOpportunityCloserScheduler());
            System.debug('Stale Opportunity Closer nightly job has been scheduled.');
        } else {
            System.debug('Stale Opportunity Closer nightly job is already scheduled.');
        }
    }
    
    /**
     * Static method to unschedule the job
     */
    public static void unscheduleNightlyJob() {
        String jobName = 'Stale Opportunity Closer - Nightly';
        
        List<CronTrigger> existingJobs = [
            SELECT Id 
            FROM CronTrigger 
            WHERE CronJobDetail.Name = :jobName
        ];
        
        for (CronTrigger job : existingJobs) {
            System.abortJob(job.Id);
        }
        
        System.debug('Stale Opportunity Closer nightly job has been unscheduled.');
    }
} 