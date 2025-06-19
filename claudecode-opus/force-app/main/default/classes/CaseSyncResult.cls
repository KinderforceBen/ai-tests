public class CaseSyncResult {
    public Id caseId { get; set; }
    public Boolean success { get; set; }
    public String ticketId { get; set; }
    public String errorMessage { get; set; }
    
    public CaseSyncResult(Id caseId) {
        this.caseId = caseId;
        this.success = false;
    }
}