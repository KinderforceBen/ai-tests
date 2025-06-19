// Create some test contacts for the demo
List<Contact> testContacts = new List<Contact>();
for (Integer i = 0; i < 5; i++) {
    testContacts.add(new Contact(
        FirstName = 'Demo',
        LastName = 'Contact' + i,
        Email = 'demo' + i + '@example.com',
        Title = 'Original Title ' + i
    ));
}
insert testContacts;

System.debug('Created ' + testContacts.size() + ' test contacts');
System.debug('Sample Contact: ' + [SELECT FirstName, LastName, Email, Title FROM Contact WHERE Email = 'demo0@example.com']);

// In a real scenario, you would:
// 1. Schedule the batch job to run nightly:
//    ContactCSVUpdateScheduler.scheduleDailyAt2AM('https://your-csv-endpoint.com/contacts.csv');
//
// 2. Or run it manually:
//    ContactCSVUpdateBatch batch = new ContactCSVUpdateBatch('https://your-csv-endpoint.com/contacts.csv');
//    Database.executeBatch(batch, 200);
//
// 3. The batch will:
//    - Fetch the CSV file from the endpoint
//    - Parse the CSV data
//    - Update contacts based on email matching
//    - Log any errors to CSV_Import_Error__c object
//    - Send email notification with results

System.debug('Demo complete. In production, the batch job would fetch CSV from external endpoint and update contacts.');
System.debug('Errors would be logged to CSV_Import_Error__c for review.');