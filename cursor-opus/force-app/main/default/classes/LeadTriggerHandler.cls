/**
 * Trigger handler for Lead object
 * Manages bulk lead conversion process
 */
public class LeadTriggerHandler extends TriggerHandler {
    
    private List<Lead> newLeads;
    private Map<Id, Lead> oldLeadsMap;
    
    /**
     * Constructor
     */
    public LeadTriggerHandler() {
        this.newLeads = (List<Lead>) Trigger.new;
        this.oldLeadsMap = (Map<Id, Lead>) Trigger.oldMap;
    }
    
    /**
     * Handle before update logic
     */
    protected override void beforeUpdate() {
        List<Lead> leadsToConvert = new List<Lead>();
        
        // Collect leads that need to be converted based on status change
        for (Lead lead : newLeads) {
            Lead oldLead = oldLeadsMap.get(lead.Id);
            
            // Check if lead status changed to a convertible status
            if (!lead.IsConverted && lead.Status != oldLead.Status && isConvertibleStatus(lead.Status)) {
                leadsToConvert.add(lead);
            }
        }
        
        // Process bulk conversion if there are leads to convert
        if (!leadsToConvert.isEmpty()) {
            // Mark leads for conversion in after update
            for (Lead lead : leadsToConvert) {
                lead.Description = (lead.Description != null ? lead.Description + '\n' : '') + 
                                 'Marked for conversion on ' + System.now();
            }
        }
    }
    
    /**
     * Handle after update logic
     */
    protected override void afterUpdate() {
        List<Lead> leadsToConvert = new List<Lead>();
        
        // Collect leads that need to be converted
        for (Lead lead : newLeads) {
            Lead oldLead = oldLeadsMap.get(lead.Id);
            
            // Check if lead status indicates it should be converted
            if (!lead.IsConverted && lead.Status != oldLead.Status && isConvertibleStatus(lead.Status)) {
                leadsToConvert.add(lead);
            }
        }
        
        // Process bulk conversion if there are leads to convert
        if (!leadsToConvert.isEmpty()) {
            LeadConversionService.convertLeads(leadsToConvert);
        }
    }
    
    /**
     * Check if a status indicates the lead should be converted
     */
    private Boolean isConvertibleStatus(String status) {
        // Define which statuses trigger conversion
        Set<String> convertibleStatuses = new Set<String>{
            'Qualified',
            'Working - Contacted',
            'Closed - Converted'
        };
        
        return convertibleStatuses.contains(status);
    }
} 