trigger LeadTrigger on Lead (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        LeadTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }
} 