public with sharing class LeadTriggerHandler {
    public static void onAfterUpdate(List<Lead> newLeads, Map<Id, Lead> oldMap) {
        // Map to hold account IDs and corresponding lead names
        Map<Id, String> accountIdToLeadName = new Map<Id, String>();
        for (Lead ld : newLeads) {
            Lead oldLd = oldMap.get(ld.Id);
            if (!oldLd.IsConverted && ld.IsConverted && ld.ConvertedAccountId != null) {
                accountIdToLeadName.put(ld.ConvertedAccountId, ld.Name);
            }
        }
        if (accountIdToLeadName.isEmpty()) {
            return;
        }
        // Query accounts to update
        List<Account> accsToUpdate = [
            SELECT Id, Description
            FROM Account
            WHERE Id IN :accountIdToLeadName.keySet()
        ];
        List<Account> updates = new List<Account>();
        for (Account acc : accsToUpdate) {
            if (String.isBlank(acc.Description)) {
                acc.Description = 'Converted from ' + accountIdToLeadName.get(acc.Id);
                updates.add(acc);
            }
        }
        if (!updates.isEmpty()) {
            update updates;
        }
    }
} 