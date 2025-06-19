public with sharing class LeadConversionHandler {
    
    /**
     * Handles Lead conversion to populate Account Description with Lead Name
     * @param newLeads List of new Lead records
     * @param oldLeads List of old Lead records
     */
    public static void handleLeadConversion(List<Lead> newLeads, List<Lead> oldLeads) {
        // Map to store converted Lead IDs and their corresponding Account IDs
        Map<Id, Id> leadToAccountMap = new Map<Id, Id>();
        
        // Check for Leads that were just converted (IsConverted changed from false to true)
        for (Integer i = 0; i < newLeads.size(); i++) {
            Lead newLead = newLeads[i];
            Lead oldLead = oldLeads != null ? oldLeads[i] : null;
            
            // Check if Lead was just converted
            if (newLead.IsConverted && 
                (oldLead == null || !oldLead.IsConverted) && 
                newLead.ConvertedAccountId != null) {
                leadToAccountMap.put(newLead.Id, newLead.ConvertedAccountId);
            }
        }
        
        // If no conversions found, exit early
        if (leadToAccountMap.isEmpty()) {
            return;
        }
        
        // Query for the converted Accounts and their current Description
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        for (Account acc : [SELECT Id, Description 
                          FROM Account 
                          WHERE Id IN :leadToAccountMap.values()]) {
            accountsToUpdate.put(acc.Id, acc);
        }
        
        // Query for the converted Leads to get their names
        Map<Id, Lead> convertedLeads = new Map<Id, Lead>([
            SELECT Id, Name 
            FROM Lead 
            WHERE Id IN :leadToAccountMap.keySet()
        ]);
        
        // Update Account Descriptions where they are blank
        List<Account> accountsToUpdateList = new List<Account>();
        for (Id leadId : leadToAccountMap.keySet()) {
            Id accountId = leadToAccountMap.get(leadId);
            Lead lead = convertedLeads.get(leadId);
            Account account = accountsToUpdate.get(accountId);
            
            // Only update if Account exists, Description is blank, and Lead exists
            if (account != null && lead != null && 
                (account.Description == null || account.Description.trim() == '')) {
                account.Description = 'Converted from ' + lead.Name;
                accountsToUpdateList.add(account);
            }
        }
        
        // Update the Accounts if there are any to update
        if (!accountsToUpdateList.isEmpty()) {
            try {
                update accountsToUpdateList;
            } catch (Exception e) {
                // Log error but don't fail the trigger
                System.debug('Error updating Account Description: ' + e.getMessage());
            }
        }
    }
} 