trigger LeadTrigger on Lead (after update) {
    // Handle Lead conversion to populate Account Description
    LeadConversionHandler.handleLeadConversion(Trigger.new, Trigger.old);
} 