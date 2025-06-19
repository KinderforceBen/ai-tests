// Anonymous Apex script to launch the StaleOpportunityCloserBatch with batch size = 200
// This can be executed in Developer Console, VS Code, or CLI

StaleOpportunityCloserBatch batch = new StaleOpportunityCloserBatch();
Id batchId = Database.executeBatch(batch, 200);

System.debug('Batch job started with ID: ' + batchId);
System.debug('You can monitor the batch job progress in Setup -> Apex Jobs');

// Optional: Query to check current qualifying opportunities before running batch
Integer qualifyingCount = [
    SELECT COUNT() 
    FROM Opportunity 
    WHERE StageName = 'Prospecting' 
    AND LastModifiedDate <= :Date.today().addDays(-90)
];

System.debug('Number of qualifying opportunities to be processed: ' + qualifyingCount);