// Anonymous Apex script to launch the Stale Opportunity Closer batch job
// This script will close all opportunities that are in 'Prospecting' stage 
// and haven't been modified in the last 90 days

// Create an instance of the batch class
StaleOpportunityCloser batchJob = new StaleOpportunityCloser();

// Execute the batch with a batch size of 200
Database.executeBatch(batchJob, 200);

// Optional: You can also schedule this to run nightly using the following code:
// String cronExp = '0 0 2 * * ?'; // Runs at 2 AM every day
// System.schedule('Stale Opportunity Closer - Nightly', cronExp, new StaleOpportunityCloserScheduler());

System.debug('Stale Opportunity Closer batch job has been queued for execution.'); 