public class LeadConversionTriggerHandler {
    
    public static void handleAfterUpdate(List<Lead> oldLeads, List<Lead> newLeads) {
        List<Id> convertedLeadIds = new List<Id>();
        List<Id> convertedAccountIds = new List<Id>();
        
        // Identify newly converted leads
        for (Integer i = 0; i < newLeads.size(); i++) {
            Lead oldLead = oldLeads[i];
            Lead newLead = newLeads[i];
            
            // Check if Lead was just converted (IsConverted flipped from false to true)
            if (!oldLead.IsConverted && newLead.IsConverted && newLead.ConvertedAccountId != null) {
                convertedLeadIds.add(newLead.Id);
                convertedAccountIds.add(newLead.ConvertedAccountId);
            }
        }
        
        // If no conversions detected, exit early
        if (convertedLeadIds.isEmpty()) {
            return;
        }
        
        // Query the converted leads to get their names and account mappings
        Map<Id, String> accountIdToLeadNameMap = new Map<Id, String>();
        List<Lead> convertedLeads = [
            SELECT Id, FirstName, LastName, ConvertedAccountId 
            FROM Lead 
            WHERE Id IN :convertedLeadIds
        ];
        
        for (Lead lead : convertedLeads) {
            String leadName = (lead.FirstName != null ? lead.FirstName + ' ' : '') + 
                             (lead.LastName != null ? lead.LastName : '');
            leadName = leadName.trim();
            accountIdToLeadNameMap.put(lead.ConvertedAccountId, leadName);
        }
        
        // Query the converted accounts to check their current descriptions
        List<Account> accountsToUpdate = new List<Account>();
        List<Account> convertedAccounts = [
            SELECT Id, Description 
            FROM Account 
            WHERE Id IN :convertedAccountIds 
            FOR UPDATE
        ];
        
        // Update accounts with blank descriptions
        for (Account acc : convertedAccounts) {
            if (String.isBlank(acc.Description)) {
                String leadName = accountIdToLeadNameMap.get(acc.Id);
                if (String.isNotBlank(leadName)) {
                    acc.Description = 'Converted from ' + leadName;
                    accountsToUpdate.add(acc);
                }
            }
        }
        
        // Perform bulk update if needed
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}