/**
 * Batch class to process CSV files containing contact updates
 * Implements Database.Batchable, Database.Stateful, and Database.AllowsCallouts
 */
public class ContactCSVUpdateBatch implements Database.Batchable<Map<String, String>>, 
                                               Database.Stateful, 
                                               Database.AllowsCallouts {
    
    // Instance variables
    private String csvEndpointUrl;
    private IHttpService httpService;
    private Integer successCount = 0;
    private Integer errorCount = 0;
    private String jobId;
    private List<Map<String, String>> csvData;
    
    /**
     * Constructor
     * @param endpointUrl The URL to fetch the CSV file from
     */
    public ContactCSVUpdateBatch(String endpointUrl) {
        this(endpointUrl, new HttpService());
    }
    
    /**
     * Constructor with dependency injection for testing
     * @param endpointUrl The URL to fetch the CSV file from
     * @param httpService The HTTP service to use for callouts
     */
    public ContactCSVUpdateBatch(String endpointUrl, IHttpService httpService) {
        this.csvEndpointUrl = endpointUrl;
        this.httpService = httpService;
    }
    
    /**
     * Start method - fetches CSV and returns iterable
     */
    public Iterable<Map<String, String>> start(Database.BatchableContext bc) {
        this.jobId = bc.getJobId();
        
        try {
            // Fetch CSV data
            String csvContent = fetchCSVData();
            
            // Parse CSV
            this.csvData = CSVParser.parseCSV(csvContent);
            
            return this.csvData;
        } catch (Exception e) {
            // Log error and return empty list
            logError(0, 'Failed to fetch or parse CSV', e.getMessage(), '');
            return new List<Map<String, String>>();
        }
    }
    
    /**
     * Execute method - processes each batch of CSV rows
     */
    public void execute(Database.BatchableContext bc, List<Map<String, String>> scope) {
        List<Contact> contactsToUpdate = new List<Contact>();
        Map<String, Map<String, String>> emailToRowMap = new Map<String, Map<String, String>>();
        
        // Build map of contacts to update
        for (Map<String, String> row : scope) {
            String email = row.get('Email');
            if (String.isNotBlank(email)) {
                emailToRowMap.put(email.toLowerCase(), row);
            }
        }
        
        // Query existing contacts
        Map<String, Contact> existingContacts = new Map<String, Contact>();
        for (Contact c : [SELECT Id, Email, FirstName, LastName, Phone, Title, Department, MailingStreet, 
                                MailingCity, MailingState, MailingPostalCode, MailingCountry
                         FROM Contact 
                         WHERE Email IN :emailToRowMap.keySet()]) {
            existingContacts.put(c.Email.toLowerCase(), c);
        }
        
        // Process each row
        Integer rowNumber = getRowNumber(scope[0]);
        for (Map<String, String> row : scope) {
            String email = row.get('Email');
            
            if (String.isBlank(email)) {
                logError(rowNumber, 'Missing email', 'Email is required', JSON.serialize(row));
                errorCount++;
            } else {
                Contact contact = existingContacts.get(email.toLowerCase());
                
                if (contact != null) {
                    // Update existing contact
                    try {
                        updateContactFromRow(contact, row);
                        contactsToUpdate.add(contact);
                    } catch (Exception e) {
                        logError(rowNumber, 'Update preparation failed', e.getMessage(), JSON.serialize(row));
                        errorCount++;
                    }
                } else {
                    logError(rowNumber, 'Contact not found', 'No contact found with email: ' + email, JSON.serialize(row));
                    errorCount++;
                }
            }
            rowNumber++;
        }
        
        // Perform DML with partial success
        if (!contactsToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(contactsToUpdate, false);
            
            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult result = results[i];
                Contact contact = contactsToUpdate[i];
                Integer actualRowNumber = getRowNumber(emailToRowMap.get(contact.Email.toLowerCase()));
                
                if (result.isSuccess()) {
                    successCount++;
                    logSuccess(actualRowNumber, contact.Email);
                } else {
                    errorCount++;
                    String errors = '';
                    for (Database.Error err : result.getErrors()) {
                        errors += err.getMessage() + '; ';
                    }
                    logError(actualRowNumber, 'DML Error', errors, JSON.serialize(emailToRowMap.get(contact.Email.toLowerCase())));
                }
            }
        }
    }
    
    /**
     * Finish method - sends summary notification
     */
    public void finish(Database.BatchableContext bc) {
        // Send summary email
        sendSummaryNotification();
    }
    
    /**
     * Fetch CSV data from endpoint
     */
    private String fetchCSVData() {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(csvEndpointUrl);
        request.setMethod('GET');
        request.setTimeout(120000); // 2 minutes timeout
        
        HttpResponse response = httpService.send(request);
        
        if (response.getStatusCode() != 200) {
            throw new CalloutException('Failed to fetch CSV. Status: ' + response.getStatusCode() + 
                                     ', Body: ' + response.getBody());
        }
        
        return response.getBody();
    }
    
    /**
     * Update contact fields from CSV row
     */
    private void updateContactFromRow(Contact contact, Map<String, String> row) {
        // Update fields if present in CSV
        if (row.containsKey('FirstName')) {
            contact.FirstName = row.get('FirstName');
        }
        if (row.containsKey('LastName')) {
            contact.LastName = row.get('LastName');
        }
        if (row.containsKey('Phone')) {
            contact.Phone = row.get('Phone');
        }
        if (row.containsKey('Title')) {
            contact.Title = row.get('Title');
        }
        if (row.containsKey('Department')) {
            contact.Department = row.get('Department');
        }
        if (row.containsKey('MailingStreet')) {
            contact.MailingStreet = row.get('MailingStreet');
        }
        if (row.containsKey('MailingCity')) {
            contact.MailingCity = row.get('MailingCity');
        }
        if (row.containsKey('MailingState')) {
            contact.MailingState = row.get('MailingState');
        }
        if (row.containsKey('MailingPostalCode')) {
            contact.MailingPostalCode = row.get('MailingPostalCode');
        }
        if (row.containsKey('MailingCountry')) {
            contact.MailingCountry = row.get('MailingCountry');
        }
    }
    
    /**
     * Get row number for a CSV row
     */
    private Integer getRowNumber(Map<String, String> row) {
        if (csvData != null) {
            for (Integer i = 0; i < csvData.size(); i++) {
                if (csvData[i] == row) {
                    return i + 2; // +2 because row 1 is headers, and we start counting from 1
                }
            }
        }
        return 0;
    }
    
    /**
     * Log successful processing
     */
    private void logSuccess(Integer rowNumber, String email) {
        CSV_Processing_Result__c result = new CSV_Processing_Result__c();
        result.Batch_Job_Id__c = jobId;
        result.Row_Number__c = rowNumber;
        result.Status__c = 'Success';
        result.Contact_Email__c = email;
        
        insert result;
    }
    
    /**
     * Log error during processing
     */
    private void logError(Integer rowNumber, String errorType, String errorMessage, String rowData) {
        CSV_Processing_Result__c result = new CSV_Processing_Result__c();
        result.Batch_Job_Id__c = jobId;
        result.Row_Number__c = rowNumber;
        result.Status__c = 'Error';
        result.Error_Message__c = errorType + ': ' + errorMessage;
        result.Row_Data__c = rowData;
        
        insert result;
    }
    
    /**
     * Send summary notification email
     */
    private void sendSummaryNotification() {
        // Get job info
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, TotalJobItems, CreatedBy.Email 
                           FROM AsyncApexJob 
                           WHERE Id = :jobId];
        
        // Build email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { job.CreatedBy.Email });
        email.setSubject('Contact CSV Update Batch - Job Completed');
        
        String body = 'The Contact CSV Update batch job has completed.\n\n';
        body += 'Job ID: ' + jobId + '\n';
        body += 'Status: ' + job.Status + '\n';
        body += 'Total Records Processed: ' + (successCount + errorCount) + '\n';
        body += 'Successful Updates: ' + successCount + '\n';
        body += 'Failed Updates: ' + errorCount + '\n\n';
        
        if (errorCount > 0) {
            body += 'Please check the CSV Processing Result records for details on failures.\n';
            body += 'Query: SELECT Row_Number__c, Error_Message__c, Row_Data__c FROM CSV_Processing_Result__c ';
            body += 'WHERE Batch_Job_Id__c = \'' + jobId + '\' AND Status__c = \'Error\'';
        }
        
        email.setPlainTextBody(body);
        email.setSaveAsActivity(false);
        
        // Send email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
} 