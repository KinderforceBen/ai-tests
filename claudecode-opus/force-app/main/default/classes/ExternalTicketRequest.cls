public class ExternalTicketRequest {
    public String subject { get; set; }
    public String description { get; set; }
    public String priority { get; set; }
    public String status { get; set; }
    public String caseNumber { get; set; }
    public String contactEmail { get; set; }
    public String contactName { get; set; }
    public String accountName { get; set; }
    public String origin { get; set; }
    public Map<String, Object> customFields { get; set; }
    
    public ExternalTicketRequest() {
        this.customFields = new Map<String, Object>();
    }
    
    public static ExternalTicketRequest fromCase(Case caseRecord) {
        ExternalTicketRequest request = new ExternalTicketRequest();
        
        request.subject = caseRecord.Subject;
        request.description = caseRecord.Description;
        request.priority = caseRecord.Priority;
        request.status = caseRecord.Status;
        request.caseNumber = caseRecord.CaseNumber;
        request.origin = caseRecord.Origin;
        
        // Add contact information if available
        if (caseRecord.ContactId != null && caseRecord.Contact != null) {
            request.contactEmail = caseRecord.Contact.Email;
            request.contactName = caseRecord.Contact.Name;
        }
        
        // Add account information if available
        if (caseRecord.AccountId != null && caseRecord.Account != null) {
            request.accountName = caseRecord.Account.Name;
        }
        
        // Add any custom fields that might be needed
        request.customFields.put('salesforceId', caseRecord.Id);
        request.customFields.put('createdDate', caseRecord.CreatedDate);
        
        return request;
    }
    
    public String toJSON() {
        return JSON.serialize(this);
    }
}