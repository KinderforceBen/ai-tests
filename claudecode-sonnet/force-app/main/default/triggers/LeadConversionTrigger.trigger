trigger LeadConversionTrigger on Lead (after update) {
    LeadConversionTriggerHandler.handleAfterUpdate(Trigger.old, Trigger.new);
}