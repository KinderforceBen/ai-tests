/**
 * Scheduler class to run ContactCSVUpdateBatch nightly
 */
public class ContactCSVUpdateScheduler implements Schedulable {
    
    private String csvEndpointUrl;
    
    /**
     * Constructor
     * @param endpointUrl The URL to fetch CSV from
     */
    public ContactCSVUpdateScheduler(String endpointUrl) {
        this.csvEndpointUrl = endpointUrl;
    }
    
    /**
     * Execute method called by scheduler
     */
    public void execute(SchedulableContext sc) {
        // Create and execute batch job
        ContactCSVUpdateBatch batch = new ContactCSVUpdateBatch(csvEndpointUrl);
        Database.executeBatch(batch, 200); // Process 200 records at a time
    }
    
    /**
     * Schedule the job to run nightly at 2 AM
     * @param endpointUrl The CSV endpoint URL
     * @return The job ID
     */
    public static String scheduleNightlyJob(String endpointUrl) {
        ContactCSVUpdateScheduler scheduler = new ContactCSVUpdateScheduler(endpointUrl);
        
        // Schedule to run daily at 2 AM
        String cronExp = '0 0 2 * * ?';
        String jobName = 'Contact CSV Update - Nightly at 2 AM';
        
        return System.schedule(jobName, cronExp, scheduler);
    }
    
    /**
     * Remove scheduled job
     * @param jobId The scheduled job ID to remove
     */
    public static void unscheduleJob(String jobId) {
        System.abortJob(jobId);
    }
} 