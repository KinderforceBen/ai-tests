trigger LeadTrigger on Lead (after insert, after update) {
    LeadTriggerHandler.handleTrigger(
        Trigger.new,
        Trigger.oldMap,
        Trigger.operationType
    );
}