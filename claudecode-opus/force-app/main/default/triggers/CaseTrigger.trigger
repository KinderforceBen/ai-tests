trigger CaseTrigger on Case (after insert) {
    CaseTriggerHandler.handleTrigger(
        Trigger.new,
        Trigger.oldMap,
        Trigger.operationType
    );
}