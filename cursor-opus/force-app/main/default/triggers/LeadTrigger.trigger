/**
 * Trigger for Lead object
 * Delegates all logic to LeadTriggerHandler
 */
trigger LeadTrigger on Lead (
    before insert, 
    before update, 
    after insert, 
    after update,
    before delete,
    after delete,
    after undelete
) {
    new LeadTriggerHandler().run();
} 