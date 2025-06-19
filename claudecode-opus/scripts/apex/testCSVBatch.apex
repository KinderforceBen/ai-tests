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

// Create CSV content
String csvContent = 'Email,FirstName,LastName,Title,Department\n';
csvContent += 'demo0@example.com,Updated,DemoContact0,CEO,Executive\n';
csvContent += 'demo1@example.com,Updated,DemoContact1,CTO,Technology\n';
csvContent += 'demo2@example.com,Updated,DemoContact2,CFO,Finance\n';

// Create mock service
MockCSVFileService mockService = new MockCSVFileService(csvContent);

// Execute the batch
ContactCSVUpdateBatch batch = new ContactCSVUpdateBatch('https://example.com/demo.csv', mockService);
Id batchId = Database.executeBatch(batch, 200);

System.debug('Batch job started with ID: ' + batchId);
System.debug('Check AsyncApexJob for status: SELECT Id, Status, JobType FROM AsyncApexJob WHERE Id = \'' + batchId + '\'');