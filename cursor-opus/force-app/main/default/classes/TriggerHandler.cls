/**
 * Base class for all trigger handlers
 * Provides a framework for clean separation of trigger logic
 */
public virtual class TriggerHandler {
    
    // Static variables to prevent recursion
    private static Set<String> bypassedHandlers = new Set<String>();
    private static Map<String, Integer> loopCountMap = new Map<String, Integer>();
    private static Map<String, Integer> loopMaxMap = new Map<String, Integer>();
    
    // Instance variables
    @TestVisible
    protected Boolean isTriggerExecuting;
    @TestVisible
    protected TriggerContext context;
    
    // Constructor
    public TriggerHandler() {
        this.setTriggerContext();
    }
    
    /**
     * Main method to run trigger logic
     */
    public void run() {
        if (!validateRun()) {
            return;
        }
        
        // Increment loop count
        addToLoopCount();
        
        // Dispatch to correct handler method
        switch on context {
            when BEFORE_INSERT {
                this.beforeInsert();
            }
            when BEFORE_UPDATE {
                this.beforeUpdate();
            }
            when AFTER_INSERT {
                this.afterInsert();
            }
            when AFTER_UPDATE {
                this.afterUpdate();
            }
            when BEFORE_DELETE {
                this.beforeDelete();
            }
            when AFTER_DELETE {
                this.afterDelete();
            }
            when AFTER_UNDELETE {
                this.afterUndelete();
            }
        }
    }
    
    /**
     * Set max loop count for a handler
     */
    public void setMaxLoopCount(Integer max) {
        String handlerName = getHandlerName();
        if (!loopMaxMap.containsKey(handlerName)) {
            loopMaxMap.put(handlerName, max);
        }
    }
    
    /**
     * Clear max loop count for a handler
     */
    public void clearMaxLoopCount() {
        loopMaxMap.remove(getHandlerName());
    }
    
    /**
     * Bypass a handler
     */
    public static void bypass(String handlerName) {
        bypassedHandlers.add(handlerName);
    }
    
    /**
     * Clear bypass for a handler
     */
    public static void clearBypass(String handlerName) {
        bypassedHandlers.remove(handlerName);
    }
    
    /**
     * Check if a handler is bypassed
     */
    public static Boolean isBypassed(String handlerName) {
        return bypassedHandlers.contains(handlerName);
    }
    
    /**
     * Clear all bypasses
     */
    public static void clearAllBypasses() {
        bypassedHandlers.clear();
    }
    
    // Virtual methods to be overridden in child classes
    @TestVisible
    protected virtual void beforeInsert() {}
    @TestVisible
    protected virtual void beforeUpdate() {}
    @TestVisible
    protected virtual void afterInsert() {}
    @TestVisible
    protected virtual void afterUpdate() {}
    @TestVisible
    protected virtual void beforeDelete() {}
    @TestVisible
    protected virtual void afterDelete() {}
    @TestVisible
    protected virtual void afterUndelete() {}
    
    // Private methods
    @TestVisible
    private void setTriggerContext() {
        if (!Trigger.isExecuting || Trigger.operationType == null) {
            this.isTriggerExecuting = false;
            return;
        } else {
            this.isTriggerExecuting = true;
        }
        
        switch on Trigger.operationType {
            when BEFORE_INSERT {
                this.context = TriggerContext.BEFORE_INSERT;
            }
            when BEFORE_UPDATE {
                this.context = TriggerContext.BEFORE_UPDATE;
            }
            when AFTER_INSERT {
                this.context = TriggerContext.AFTER_INSERT;
            }
            when AFTER_UPDATE {
                this.context = TriggerContext.AFTER_UPDATE;
            }
            when BEFORE_DELETE {
                this.context = TriggerContext.BEFORE_DELETE;
            }
            when AFTER_DELETE {
                this.context = TriggerContext.AFTER_DELETE;
            }
            when AFTER_UNDELETE {
                this.context = TriggerContext.AFTER_UNDELETE;
            }
        }
    }
    
    @TestVisible
    private Boolean validateRun() {
        if (!isTriggerExecuting || context == null) {
            return false;
        }
        
        // Check if handler is bypassed
        if (isBypassed(getHandlerName())) {
            return false;
        }
        
        // Check loop count
        if (hasExceededLoopMax()) {
            return false;
        }
        
        return true;
    }
    
    @TestVisible
    private String getHandlerName() {
        return String.valueOf(this).substring(0, String.valueOf(this).indexOf(':'));
    }
    
    @TestVisible
    private void addToLoopCount() {
        String handlerName = getHandlerName();
        if (loopCountMap.containsKey(handlerName)) {
            loopCountMap.put(handlerName, loopCountMap.get(handlerName) + 1);
        } else {
            loopCountMap.put(handlerName, 1);
        }
    }
    
    @TestVisible
    private Boolean hasExceededLoopMax() {
        String handlerName = getHandlerName();
        if (!loopMaxMap.containsKey(handlerName)) {
            return false;
        }
        if (!loopCountMap.containsKey(handlerName)) {
            return false;
        }
        return loopCountMap.get(handlerName) > loopMaxMap.get(handlerName);
    }
    
    // Inner enum for trigger contexts
    @TestVisible
    private enum TriggerContext {
        BEFORE_INSERT, BEFORE_UPDATE, AFTER_INSERT, AFTER_UPDATE,
        BEFORE_DELETE, AFTER_DELETE, AFTER_UNDELETE
    }
} 