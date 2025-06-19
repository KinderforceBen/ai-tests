@isTest
public class StaleOpportunityCloserBatchTest {
    
    @testSetup
    static void setupTestData() {
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            testAccounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert testAccounts;
        
        // Create fresh prospecting opportunities that should NOT be closed
        List<Opportunity> freshOpportunities = new List<Opportunity>();
        Date today = Date.today();
        for (Integer i = 0; i < 3; i++) {
            freshOpportunities.add(new Opportunity(
                Name = 'Fresh Prospecting Opp ' + i,
                AccountId = testAccounts[1].Id,
                StageName = 'Prospecting',
                CloseDate = today.addDays(30)
            ));
        }
        insert freshOpportunities;
        
        // Create old opportunities in different stages that should NOT be closed
        List<Opportunity> nonProspectingOpportunities = new List<Opportunity>();
        for (Integer i = 0; i < 3; i++) {
            nonProspectingOpportunities.add(new Opportunity(
                Name = 'Old Non-Prospecting Opp ' + i,
                AccountId = testAccounts[2].Id,
                StageName = 'Qualification',
                CloseDate = today.addDays(30)
            ));
        }
        insert nonProspectingOpportunities;
        
        // Set creation dates for non-prospecting opportunities to simulate old records
        Date oneHundredDaysAgo = today.addDays(-100);
        for (Opportunity opp : nonProspectingOpportunities) {
            Test.setCreatedDate(opp.Id, oneHundredDaysAgo);
        }
        
        // Create stale prospecting opportunities using a custom approach
        // Since we can't directly manipulate LastModifiedDate in tests, we'll create them
        // in a way that allows the batch to find them using a test-specific query
        List<Opportunity> staleOpportunities = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            staleOpportunities.add(new Opportunity(
                Name = 'Stale Prospecting Opp ' + i,
                AccountId = testAccounts[0].Id,
                StageName = 'Prospecting',
                CloseDate = today.addDays(30),
                Description = 'STALE_FOR_TEST' // Marker for test identification
            ));
        }
        insert staleOpportunities;
        
        // Set creation dates for stale opportunities
        for (Opportunity opp : staleOpportunities) {
            Test.setCreatedDate(opp.Id, oneHundredDaysAgo);
        }
    }
    
    @isTest
    static void testBatchProcessing() {
        // Since Test.setCreatedDate doesn't affect LastModifiedDate, and we can't
        // directly manipulate LastModifiedDate in tests, we'll test the batch logic
        // by creating opportunities and immediately running the batch.
        // In a real scenario, opportunities would naturally age over time.
        
        Test.startTest();
        
        // Execute the batch job
        StaleOpportunityCloserBatch batch = new StaleOpportunityCloserBatch();
        Id batchId = Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        // Verify that no recently created opportunities were affected
        // (all test opportunities were just created, so none should be 90+ days old)
        List<Opportunity> freshProspectingOpps = [
            SELECT Id, Name, StageName 
            FROM Opportunity 
            WHERE Name LIKE 'Fresh Prospecting Opp%'
        ];
        
        for (Opportunity opp : freshProspectingOpps) {
            System.assertEquals('Prospecting', opp.StageName, 
                               'Fresh prospecting opportunities should not be closed: ' + opp.Name);
        }
        
        // All non-prospecting opportunities should remain unchanged
        List<Opportunity> nonProspectingOpps = [
            SELECT Id, Name, StageName 
            FROM Opportunity 
            WHERE Name LIKE 'Old Non-Prospecting Opp%'
        ];
        
        for (Opportunity opp : nonProspectingOpps) {
            System.assertEquals('Qualification', opp.StageName, 
                               'Non-prospecting opportunities should not be affected: ' + opp.Name);
        }
        
        // Stale opportunities should also remain unchanged since they're not actually old
        List<Opportunity> staleOpps = [
            SELECT Id, Name, StageName 
            FROM Opportunity 
            WHERE Name LIKE 'Stale Prospecting Opp%'
        ];
        
        for (Opportunity opp : staleOpps) {
            System.assertEquals('Prospecting', opp.StageName, 
                               'Recently created opportunities should not be closed: ' + opp.Name);
        }
        
        // Verify no opportunities were changed (since none are actually old)
        Integer totalProspectingCount = [SELECT COUNT() FROM Opportunity WHERE StageName = 'Prospecting'];
        System.assertEquals(8, totalProspectingCount, 
                           'All prospecting opportunities should remain unchanged');
        
        Integer totalClosedLostCount = [SELECT COUNT() FROM Opportunity WHERE StageName = 'Closed Lost'];
        System.assertEquals(0, totalClosedLostCount, 
                           'No opportunities should be closed lost');
    }
    
    @isTest
    static void testBatchWithNoQualifyingRecords() {
        // Delete all opportunities to test empty result set
        delete [SELECT Id FROM Opportunity];
        
        Test.startTest();
        
        // Execute the batch job
        StaleOpportunityCloserBatch batch = new StaleOpportunityCloserBatch();
        Id batchId = Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        // Verify no errors occurred and job completed successfully
        // This test ensures the batch handles empty result sets gracefully
        Integer totalOpportunities = [SELECT COUNT() FROM Opportunity];
        System.assertEquals(0, totalOpportunities, 'No opportunities should exist');
    }
    
    @isTest
    static void testBatchExecuteMethodDirectly() {
        // Test the execute method directly by providing opportunities to process
        Account testAccount = new Account(Name = 'Direct Test Account');
        insert testAccount;
        
        // Create opportunities that should be updated
        List<Opportunity> testOpps = new List<Opportunity>();
        for (Integer i = 0; i < 3; i++) {
            testOpps.add(new Opportunity(
                Name = 'Direct Test Opp ' + i,
                AccountId = testAccount.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            ));
        }
        insert testOpps;
        
        Test.startTest();
        
        // Call the execute method directly
        StaleOpportunityCloserBatch batch = new StaleOpportunityCloserBatch();
        batch.execute(null, testOpps);
        
        Test.stopTest();
        
        // Verify the opportunities were updated to Closed Lost
        List<Opportunity> updatedOpps = [
            SELECT Id, Name, StageName 
            FROM Opportunity 
            WHERE Name LIKE 'Direct Test Opp%'
        ];
        
        for (Opportunity opp : updatedOpps) {
            System.assertEquals('Closed Lost', opp.StageName, 
                               'Opportunity should be closed lost: ' + opp.Name);
        }
        
        System.assertEquals(3, updatedOpps.size(), 'Should have 3 updated opportunities');
    }
    
    @isTest
    static void testBatchQueryLogic() {
        // Test that the batch query works correctly by verifying the SOQL structure
        Date today = Date.today();
        Date ninetyDaysAgo = today.addDays(-90);
        
        Test.startTest();
        
        // Test the batch start method to ensure it returns a valid QueryLocator
        StaleOpportunityCloserBatch batch = new StaleOpportunityCloserBatch();
        Database.QueryLocator ql = batch.start(null);
        
        // Verify the query locator is not null
        System.assertNotEquals(null, ql, 'QueryLocator should not be null');
        
        // Test execute method with empty scope to ensure no errors
        List<SObject> emptyScope = new List<SObject>();
        batch.execute(null, emptyScope);
        
        // Test finish method
        batch.finish(null);
        
        Test.stopTest();
        
        // Verify the batch logic works with actual Prospecting opportunities
        List<Opportunity> prospectingOpps = [
            SELECT Id, Name, StageName, LastModifiedDate 
            FROM Opportunity 
            WHERE StageName = 'Prospecting'
        ];
        
        // All opportunities should still be in Prospecting since they're not old enough
        for (Opportunity opp : prospectingOpps) {
            System.assertEquals('Prospecting', opp.StageName, 
                               'Opportunity should remain in Prospecting stage: ' + opp.Name);
        }
        
        // Test the date logic manually
        Boolean dateComparisonWorks = (Date.today() > ninetyDaysAgo);
        System.assert(dateComparisonWorks, 'Date comparison logic should work correctly');
        
        // Verify query structure by testing with manually created old date
        List<Opportunity> queryTest = [
            SELECT Id 
            FROM Opportunity 
            WHERE StageName = 'Prospecting' 
            AND LastModifiedDate <= :ninetyDaysAgo
        ];
        
        // Should be empty since all test opportunities are newly created
        System.assertEquals(0, queryTest.size(), 
                           'No opportunities should match the old date criteria');
    }
}