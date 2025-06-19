/**
 * Test class for TriggerHandler base class
 */
@isTest
private class TriggerHandlerTest {
    
    /**
     * Test trigger handler bypass functionality
     */
    @isTest
    static void testBypassFunctionality() {
        // Test bypass
        TriggerHandler.bypass('TestHandler');
        System.assert(TriggerHandler.isBypassed('TestHandler'), 'Handler should be bypassed');
        
        // Test clear bypass
        TriggerHandler.clearBypass('TestHandler');
        System.assert(!TriggerHandler.isBypassed('TestHandler'), 'Handler should not be bypassed');
        
        // Test clear all bypasses
        TriggerHandler.bypass('TestHandler1');
        TriggerHandler.bypass('TestHandler2');
        TriggerHandler.clearAllBypasses();
        System.assert(!TriggerHandler.isBypassed('TestHandler1'), 'All handlers should be cleared');
        System.assert(!TriggerHandler.isBypassed('TestHandler2'), 'All handlers should be cleared');
    }
    
    /**
     * Test max loop count functionality
     */
    @isTest
    static void testMaxLoopCount() {
        TestTriggerHandler handler = new TestTriggerHandler();
        
        // Set max loop count
        handler.setMaxLoopCount(2);
        
        // Run handler multiple times
        handler.run();
        handler.run();
        handler.run(); // This should not execute due to max loop count
        
        // Verify execution count
        System.assertEquals(2, handler.beforeInsertCount, 'Handler should only run twice');
        
        // Clear max loop count
        handler.clearMaxLoopCount();
    }
    
    /**
     * Test trigger context detection
     */
    @isTest
    static void testTriggerContext() {
        TestTriggerHandler handler = new TestTriggerHandler();
        
        // Since we're not in a trigger context, handler should not execute
        handler.run();
        System.assertEquals(0, handler.beforeInsertCount, 'Handler should not execute outside trigger context');
    }
    
    /**
     * Test handler for testing purposes
     */
    private class TestTriggerHandler extends TriggerHandler {
        public Integer beforeInsertCount = 0;
        public Integer afterInsertCount = 0;
        
        // Override the context check for testing
        public TestTriggerHandler() {
            super();
            // Force trigger context for testing
            this.isTriggerExecuting = true;
            this.context = TriggerContext.BEFORE_INSERT;
        }
        
        protected override void beforeInsert() {
            beforeInsertCount++;
        }
        
        protected override void afterInsert() {
            afterInsertCount++;
        }
    }
} 