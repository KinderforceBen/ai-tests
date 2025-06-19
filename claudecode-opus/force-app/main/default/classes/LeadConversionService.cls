public with sharing class LeadConversionService {
    
    public static void convertLeads(List<Lead> leadsToConvert) {
        if (leadsToConvert.isEmpty()) {
            return;
        }
        
        Lead_Conversion_Setting__mdt setting = LeadTriggerHandler.getConversionSettings();
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        
        // Get the lead convert status
        LeadStatus convertStatus = [
            SELECT Id, MasterLabel, IsConverted
            FROM LeadStatus
            WHERE IsConverted = true
            LIMIT 1
        ];
        
        // Create LeadConvert objects for bulk processing
        for (Lead lead : leadsToConvert) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(lead.Id);
            lc.setConvertedStatus(convertStatus.MasterLabel);
            
            // Set whether to create opportunity based on custom metadata
            lc.setDoNotCreateOpportunity(!setting.Create_Opportunity__c);
            
            // If creating opportunity, set the stage name
            if (setting.Create_Opportunity__c) {
                lc.setOpportunityName(lead.Company + ' - ' + lead.LastName);
            }
            
            leadConverts.add(lc);
        }
        
        // Perform bulk conversion
        if (!leadConverts.isEmpty()) {
            try {
                List<Database.LeadConvertResult> results = Database.convertLead(leadConverts, false);
                
                // Process results and handle any errors
                processConversionResults(results, leadsToConvert, setting);
                
            } catch (Exception e) {
                System.debug('Error during lead conversion: ' + e.getMessage());
                throw new LeadConversionException('Failed to convert leads: ' + e.getMessage());
            }
        }
    }
    
    private static void processConversionResults(
        List<Database.LeadConvertResult> results,
        List<Lead> originalLeads,
        Lead_Conversion_Setting__mdt setting
    ) {
        List<Id> opportunityIds = new List<Id>();
        List<String> errors = new List<String>();
        
        for (Integer i = 0; i < results.size(); i++) {
            Database.LeadConvertResult result = results[i];
            
            if (result.isSuccess()) {
                if (result.getOpportunityId() != null) {
                    opportunityIds.add(result.getOpportunityId());
                }
            } else {
                // Collect errors
                Lead failedLead = originalLeads[i];
                for (Database.Error error : result.getErrors()) {
                    errors.add('Lead ' + failedLead.Id + ': ' + error.getMessage());
                }
            }
        }
        
        // Update opportunity stages if any were created
        if (!opportunityIds.isEmpty() && setting.Create_Opportunity__c) {
            updateOpportunityStages(opportunityIds, setting.Default_Opportunity_Stage__c);
        }
        
        // Log errors if any
        if (!errors.isEmpty()) {
            System.debug('Lead conversion errors: ' + String.join(errors, '\n'));
        }
    }
    
    private static void updateOpportunityStages(List<Id> opportunityIds, String stageName) {
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        
        for (Id oppId : opportunityIds) {
            oppsToUpdate.add(new Opportunity(
                Id = oppId,
                StageName = stageName
            ));
        }
        
        if (!oppsToUpdate.isEmpty()) {
            try {
                update oppsToUpdate;
            } catch (Exception e) {
                System.debug('Error updating opportunity stages: ' + e.getMessage());
            }
        }
    }
    
    public class LeadConversionException extends Exception {}
}