// Anonymous Apex script to schedule the Stale Opportunity Closer batch job
// This script will schedule the batch job to run nightly at 2 AM

// Schedule the nightly job
StaleOpportunityCloserScheduler.scheduleNightlyJob();

System.debug('Stale Opportunity Closer nightly job scheduling completed.');

// To unschedule the job later, use:
// StaleOpportunityCloserScheduler.unscheduleNightlyJob(); 