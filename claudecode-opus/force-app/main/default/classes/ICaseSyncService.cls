public interface ICaseSyncService {
    ExternalTicketResponse syncCase(Case caseRecord);
    List<CaseSyncResult> syncCases(List<Case> cases);
}