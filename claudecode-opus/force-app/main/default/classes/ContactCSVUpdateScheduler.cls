public with sharing class ContactCSVUpdateScheduler implements Schedulable {
    
    private String csvEndpoint;
    
    public ContactCSVUpdateScheduler(String csvEndpoint) {
        this.csvEndpoint = csvEndpoint;
    }
    
    public void execute(SchedulableContext SC) {
        // Execute the batch job
        ContactCSVUpdateBatch batch = new ContactCSVUpdateBatch(csvEndpoint);
        Database.executeBatch(batch, 200); // Process 200 records at a time
    }
    
    // Helper method to schedule the job
    public static String scheduleNightlyJob(String jobName, String cronExpression, String csvEndpoint) {
        ContactCSVUpdateScheduler scheduler = new ContactCSVUpdateScheduler(csvEndpoint);
        return System.schedule(jobName, cronExpression, scheduler);
    }
    
    // Helper method to schedule daily at 2 AM
    public static String scheduleDailyAt2AM(String csvEndpoint) {
        String jobName = 'Contact CSV Update - ' + DateTime.now().format('yyyy-MM-dd HH:mm:ss');
        String cronExpression = '0 0 2 * * ?'; // Run at 2:00 AM every day
        return scheduleNightlyJob(jobName, cronExpression, csvEndpoint);
    }
}