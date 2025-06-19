public class ExternalTicketResponse {
    public String ticketId { get; set; }
    public String status { get; set; }
    public String message { get; set; }
    public Boolean success { get; set; }
    public String errorCode { get; set; }
    public List<String> errors { get; set; }
    
    public ExternalTicketResponse() {
        this.errors = new List<String>();
        this.success = false;
    }
    
    public static ExternalTicketResponse parse(String jsonString) {
        return (ExternalTicketResponse) JSON.deserialize(jsonString, ExternalTicketResponse.class);
    }
    
    public Boolean isSuccess() {
        return success && String.isNotBlank(ticketId);
    }
    
    public String getErrorMessage() {
        if (errors != null && !errors.isEmpty()) {
            return String.join(errors, '; ');
        } else if (String.isNotBlank(message)) {
            return message;
        } else if (String.isNotBlank(errorCode)) {
            return 'Error Code: ' + errorCode;
        }
        return 'Unknown error occurred';
    }
}