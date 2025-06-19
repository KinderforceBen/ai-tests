/**
 * Service class for bulk lead conversion
 * Handles the conversion of leads to contacts, accounts, and opportunities
 */
public with sharing class LeadConversionService {
    
    /**
     * Convert multiple leads in bulk
     * @param leadsToConvert List of leads to convert
     */
    public static void convertLeads(List<Lead> leadsToConvert) {
        // Get conversion settings from Custom Metadata
        Lead_Conversion_Setting__mdt settings = getActiveSettings();
        
        // Prepare lead conversion objects
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        
        for (Lead lead : leadsToConvert) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(lead.Id);
            
            // Set conversion status
            LeadStatus convertStatus = [
                SELECT Id, MasterLabel 
                FROM LeadStatus 
                WHERE IsConverted = true 
                LIMIT 1
            ];
            lc.setConvertedStatus(convertStatus.MasterLabel);
            
            // Configure opportunity creation based on settings
            if (settings != null && settings.Create_Opportunity__c) {
                lc.setDoNotCreateOpportunity(false);
                lc.setOpportunityName(lead.Company + ' - ' + System.today().format());
            } else {
                lc.setDoNotCreateOpportunity(true);
            }
            
            leadConverts.add(lc);
        }
        
        // Perform bulk conversion
        if (!leadConverts.isEmpty()) {
            List<Database.LeadConvertResult> results = Database.convertLead(leadConverts, false);
            
            // Process results and handle any errors
            handleConversionResults(results, leadsToConvert);
            
            // Update opportunity stages if needed
            if (settings != null && settings.Create_Opportunity__c && !String.isBlank(settings.Default_Opportunity_Stage__c)) {
                updateOpportunityStages(results, settings.Default_Opportunity_Stage__c);
            }
        }
    }
    
    /**
     * Get active lead conversion settings from Custom Metadata
     * @return Active Lead_Conversion_Setting__mdt record
     */
    private static Lead_Conversion_Setting__mdt getActiveSettings() {
        List<Lead_Conversion_Setting__mdt> settings = [
            SELECT Id, Default_Opportunity_Stage__c, Create_Opportunity__c, Is_Active__c
            FROM Lead_Conversion_Setting__mdt
            WHERE Is_Active__c = true
            LIMIT 1
        ];
        
        return settings.isEmpty() ? null : settings[0];
    }
    
    /**
     * Handle conversion results and log any errors
     * @param results List of conversion results
     * @param originalLeads Original list of leads
     */
    private static void handleConversionResults(
        List<Database.LeadConvertResult> results, 
        List<Lead> originalLeads
    ) {
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        
        for (Integer i = 0; i < results.size(); i++) {
            Database.LeadConvertResult result = results[i];
            
            if (!result.isSuccess()) {
                // Create error log for failed conversions
                Error_Log__c errorLog = new Error_Log__c();
                errorLog.Error_Message__c = String.join(result.getErrors()[0].getFields(), ', ') + 
                                           ': ' + result.getErrors()[0].getMessage();
                errorLog.Record_Id__c = originalLeads[i].Id;
                errorLog.Object_Type__c = 'Lead';
                errorLog.Process_Name__c = 'Lead Conversion';
                errorLogs.add(errorLog);
            }
        }
        
        // Insert error logs if any
        if (!errorLogs.isEmpty()) {
            insert errorLogs;
        }
    }
    
    /**
     * Update opportunity stages after conversion
     * @param results List of conversion results
     * @param stageName Default stage name from settings
     */
    private static void updateOpportunityStages(
        List<Database.LeadConvertResult> results,
        String stageName
    ) {
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        Set<Id> opportunityIds = new Set<Id>();
        
        // Collect opportunity IDs from successful conversions
        for (Database.LeadConvertResult result : results) {
            if (result.isSuccess() && result.getOpportunityId() != null) {
                opportunityIds.add(result.getOpportunityId());
            }
        }
        
        // Query and update opportunities
        if (!opportunityIds.isEmpty()) {
            for (Opportunity opp : [SELECT Id, StageName FROM Opportunity WHERE Id IN :opportunityIds]) {
                opp.StageName = stageName;
                opportunitiesToUpdate.add(opp);
            }
            
            if (!opportunitiesToUpdate.isEmpty()) {
                update opportunitiesToUpdate;
            }
        }
    }
} 