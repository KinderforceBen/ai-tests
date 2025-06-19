public with sharing class LeadTriggerHandler {
    
    @TestVisible
    private static Boolean bypassTrigger = false;
    
    public static void handleTrigger(
        List<Lead> newLeads,
        Map<Id, Lead> oldLeadMap,
        System.TriggerOperation operationType
    ) {
        if (bypassTrigger) {
            return;
        }
        
        switch on operationType {
            when AFTER_INSERT {
                handleAfterInsert(newLeads);
            }
            when AFTER_UPDATE {
                handleAfterUpdate(newLeads, oldLeadMap);
            }
        }
    }
    
    private static void handleAfterInsert(List<Lead> newLeads) {
        List<Lead> leadsToConvert = filterWebLeadsForConversion(newLeads, null);
        
        if (!leadsToConvert.isEmpty()) {
            LeadConversionService.convertLeads(leadsToConvert);
        }
    }
    
    private static void handleAfterUpdate(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        List<Lead> leadsToConvert = filterWebLeadsForConversion(newLeads, oldLeadMap);
        
        if (!leadsToConvert.isEmpty()) {
            LeadConversionService.convertLeads(leadsToConvert);
        }
    }
    
    private static List<Lead> filterWebLeadsForConversion(
        List<Lead> newLeads,
        Map<Id, Lead> oldLeadMap
    ) {
        Lead_Conversion_Setting__mdt setting = getConversionSettings();
        
        if (!setting.Auto_Convert_Web_Leads__c) {
            return new List<Lead>();
        }
        
        List<Lead> leadsToConvert = new List<Lead>();
        
        for (Lead lead : newLeads) {
            if (shouldConvertLead(lead, oldLeadMap)) {
                leadsToConvert.add(lead);
            }
        }
        
        return leadsToConvert;
    }
    
    private static Boolean shouldConvertLead(Lead lead, Map<Id, Lead> oldLeadMap) {
        // Convert only Web-to-Lead submissions that are not already converted
        if (lead.IsConverted) {
            return false;
        }
        
        // Check if it's a web lead
        if (lead.LeadSource != 'Web') {
            return false;
        }
        
        // For inserts, convert if it's a web lead
        if (oldLeadMap == null) {
            return true;
        }
        
        // For updates, only convert if LeadSource changed to 'Web'
        Lead oldLead = oldLeadMap.get(lead.Id);
        return oldLead.LeadSource != 'Web' && lead.LeadSource == 'Web';
    }
    
    public static Lead_Conversion_Setting__mdt getConversionSettings() {
        Lead_Conversion_Setting__mdt setting;
        
        try {
            setting = [
                SELECT Auto_Convert_Web_Leads__c, Create_Opportunity__c, Default_Opportunity_Stage__c
                FROM Lead_Conversion_Setting__mdt
                WHERE DeveloperName = 'Default'
                LIMIT 1
            ];
        } catch (Exception e) {
            // Return default values if no custom metadata exists
            setting = new Lead_Conversion_Setting__mdt(
                Auto_Convert_Web_Leads__c = true,
                Create_Opportunity__c = true,
                Default_Opportunity_Stage__c = 'Prospecting'
            );
        }
        
        return setting;
    }
}