public with sharing class ContactCSVUpdateBatch implements Database.Batchable<CSVParser.CSVRow>, Database.AllowsCallouts, Database.Stateful {
    
    private String csvEndpoint;
    private ICSVFileService fileService;
    private List<CSVParser.CSVRow> csvRows;
    private Integer successCount = 0;
    private Integer errorCount = 0;
    private String jobId;
    private List<CSV_Import_Error__c> allErrors = new List<CSV_Import_Error__c>();
    
    public ContactCSVUpdateBatch(String csvEndpoint) {
        this(csvEndpoint, new CSVFileService());
    }
    
    public ContactCSVUpdateBatch(String csvEndpoint, ICSVFileService fileService) {
        this.csvEndpoint = csvEndpoint;
        this.fileService = fileService;
    }
    
    public Iterable<CSVParser.CSVRow> start(Database.BatchableContext BC) {
        jobId = BC.getJobId();
        
        try {
            // Fetch CSV content
            String csvContent = fileService.fetchCSVContent(csvEndpoint);
            
            // Parse CSV
            csvRows = CSVParser.parse(csvContent);
            
            System.debug('Total rows to process: ' + csvRows.size());
            return csvRows;
            
        } catch (Exception e) {
            // Log error and return empty list
            System.debug('Error in start method: ' + e.getMessage());
            throw e;
        }
    }
    
    public void execute(Database.BatchableContext BC, List<CSVParser.CSVRow> scope) {
        List<Contact> contactsToUpdate = new List<Contact>();
        Map<Integer, CSVParser.CSVRow> rowByIndex = new Map<Integer, CSVParser.CSVRow>();
        
        for (CSVParser.CSVRow row : scope) {
            try {
                Contact con = createContactFromRow(row);
                if (con != null) {
                    contactsToUpdate.add(con);
                    rowByIndex.put(contactsToUpdate.size() - 1, row);
                }
            } catch (Exception e) {
                logError(row, 'Failed to parse row: ' + e.getMessage());
            }
        }
        
        if (!contactsToUpdate.isEmpty()) {
            List<Database.SaveResult> results = Database.update(contactsToUpdate, false);
            
            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult result = results[i];
                CSVParser.CSVRow originalRow = rowByIndex.get(i);
                
                if (result.isSuccess()) {
                    successCount++;
                } else {
                    String errorMessage = '';
                    for (Database.Error error : result.getErrors()) {
                        errorMessage += error.getMessage() + '; ';
                    }
                    logError(originalRow, errorMessage);
                }
            }
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        // Insert all error records
        if (!allErrors.isEmpty()) {
            insert allErrors;
        }
        
        // Send notification email
        sendNotificationEmail();
    }
    
    private Contact createContactFromRow(CSVParser.CSVRow row) {
        String email = row.values.get('Email');
        
        if (String.isBlank(email)) {
            throw new ContactUpdateException('Email is required');
        }
        
        // Query existing contact by email
        List<Contact> existingContacts = [
            SELECT Id FROM Contact 
            WHERE Email = :email 
            LIMIT 1
        ];
        
        if (existingContacts.isEmpty()) {
            throw new ContactUpdateException('Contact not found with email: ' + email);
        }
        
        Contact con = new Contact(Id = existingContacts[0].Id);
        
        // Update fields based on CSV columns
        if (row.values.containsKey('FirstName')) {
            con.FirstName = row.values.get('FirstName');
        }
        if (row.values.containsKey('LastName')) {
            con.LastName = row.values.get('LastName');
        }
        if (row.values.containsKey('Phone')) {
            con.Phone = row.values.get('Phone');
        }
        if (row.values.containsKey('Title')) {
            con.Title = row.values.get('Title');
        }
        if (row.values.containsKey('Department')) {
            con.Department = row.values.get('Department');
        }
        if (row.values.containsKey('MailingStreet')) {
            con.MailingStreet = row.values.get('MailingStreet');
        }
        if (row.values.containsKey('MailingCity')) {
            con.MailingCity = row.values.get('MailingCity');
        }
        if (row.values.containsKey('MailingState')) {
            con.MailingState = row.values.get('MailingState');
        }
        if (row.values.containsKey('MailingPostalCode')) {
            con.MailingPostalCode = row.values.get('MailingPostalCode');
        }
        if (row.values.containsKey('MailingCountry')) {
            con.MailingCountry = row.values.get('MailingCountry');
        }
        
        return con;
    }
    
    private void logError(CSVParser.CSVRow row, String errorMessage) {
        errorCount++;
        
        CSV_Import_Error__c error = new CSV_Import_Error__c(
            Batch_Job_Id__c = jobId,
            Row_Number__c = row.rowNumber,
            Row_Data__c = JSON.serialize(row.values),
            Error_Message__c = errorMessage,
            Contact_Email__c = row.values.get('Email')
        );
        
        allErrors.add(error);
    }
    
    private void sendNotificationEmail() {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        // Get the current user's email
        User currentUser = [SELECT Email, Name FROM User WHERE Id = :UserInfo.getUserId()];
        
        mail.setToAddresses(new String[] { currentUser.Email });
        mail.setSubject('Contact CSV Import Completed - Job ID: ' + jobId);
        
        String body = 'Hello ' + currentUser.Name + ',\n\n';
        body += 'The Contact CSV import batch job has completed.\n\n';
        body += 'Job Summary:\n';
        body += '- Job ID: ' + jobId + '\n';
        body += '- Total Records Processed: ' + (successCount + errorCount) + '\n';
        body += '- Successful Updates: ' + successCount + '\n';
        body += '- Failed Updates: ' + errorCount + '\n';
        
        if (errorCount > 0) {
            body += '\nError details have been logged in the CSV Import Error object.\n';
            body += 'You can view them by running this SOQL query:\n';
            body += 'SELECT Row_Number__c, Contact_Email__c, Error_Message__c FROM CSV_Import_Error__c WHERE Batch_Job_Id__c = \'' + jobId + '\'';
        }
        
        body += '\n\nBest regards,\nSalesforce Automation';
        
        mail.setPlainTextBody(body);
        mail.setSaveAsActivity(false);
        
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } catch (Exception e) {
            System.debug('Failed to send notification email: ' + e.getMessage());
        }
    }
    
    public class ContactUpdateException extends Exception {}
}