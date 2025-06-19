@isTest
private class StaleOpportunityCloserTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert testAccounts;
        
        // Create opportunities with different scenarios
        List<Opportunity> testOpportunities = new List<Opportunity>();
        
        // 1. Stale Prospecting opportunity (should be closed)
        testOpportunities.add(new Opportunity(
            Name = 'Stale Prospecting Opp',
            AccountId = testAccounts[0].Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 10000
        ));
        
        // 2. Recent Prospecting opportunity (should NOT be closed)
        testOpportunities.add(new Opportunity(
            Name = 'Recent Prospecting Opp',
            AccountId = testAccounts[1].Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 15000
        ));
        
        // 3. Stale Closed Won opportunity (should NOT be closed)
        testOpportunities.add(new Opportunity(
            Name = 'Stale Closed Won Opp',
            AccountId = testAccounts[2].Id,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-10),
            Amount = 20000
        ));
        
        // 4. Stale Closed Lost opportunity (should NOT be closed)
        testOpportunities.add(new Opportunity(
            Name = 'Stale Closed Lost Opp',
            AccountId = testAccounts[3].Id,
            StageName = 'Closed Lost',
            CloseDate = Date.today().addDays(-10),
            Amount = 5000
        ));
        
        // 5. Stale Qualification opportunity (should NOT be closed)
        testOpportunities.add(new Opportunity(
            Name = 'Stale Qualification Opp',
            AccountId = testAccounts[4].Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            Amount = 12000
        ));
        
        insert testOpportunities;
        
        // Update the stale opportunities to have LastModifiedDate > 90 days ago
        // We need to use Test.setCreatedDate to simulate old records
        List<Opportunity> staleOpps = [
            SELECT Id 
            FROM Opportunity 
            WHERE Name IN ('Stale Prospecting Opp', 'Stale Closed Won Opp', 'Stale Closed Lost Opp', 'Stale Qualification Opp')
        ];
        
        for (Opportunity opp : staleOpps) {
            Test.setCreatedDate(opp.Id, Date.today().addDays(-95));
        }
    }
    
    @isTest
    static void testStaleOpportunityCloser() {
        // Query for opportunities before running the batch
        List<Opportunity> opportunitiesBefore = [
            SELECT Id, Name, StageName, LastModifiedDate, CloseDate
            FROM Opportunity
            ORDER BY Name
        ];
        
        // Verify initial state
        System.assertEquals(5, opportunitiesBefore.size(), 'Should have 5 test opportunities');
        
        // Find the stale prospecting opportunity
        Opportunity staleProspectingOpp = null;
        Opportunity recentProspectingOpp = null;
        
        for (Opportunity opp : opportunitiesBefore) {
            if (opp.Name == 'Stale Prospecting Opp') {
                staleProspectingOpp = opp;
            } else if (opp.Name == 'Recent Prospecting Opp') {
                recentProspectingOpp = opp;
            }
        }
        
        // Verify the stale opportunity is in Prospecting stage
        System.assertEquals('Prospecting', staleProspectingOpp.StageName, 'Stale opportunity should be in Prospecting stage');
        System.assertEquals('Prospecting', recentProspectingOpp.StageName, 'Recent opportunity should be in Prospecting stage');
        
        // Execute the batch job
        Test.startTest();
        StaleOpportunityCloser batchJob = new StaleOpportunityCloser();
        Database.executeBatch(batchJob, 200);
        Test.stopTest();
        
        // Query for opportunities after running the batch
        List<Opportunity> opportunitiesAfter = [
            SELECT Id, Name, StageName, LastModifiedDate, CloseDate
            FROM Opportunity
            ORDER BY Name
        ];
        
        // Verify results
        for (Opportunity opp : opportunitiesAfter) {
            if (opp.Name == 'Stale Prospecting Opp') {
                // This should have been updated to Closed Lost
                System.assertEquals('Closed Lost', opp.StageName, 'Stale prospecting opportunity should be closed');
                System.assertEquals(Date.today(), opp.CloseDate, 'Close date should be set to today');
            } else if (opp.Name == 'Recent Prospecting Opp') {
                // This should remain in Prospecting stage
                System.assertEquals('Prospecting', opp.StageName, 'Recent prospecting opportunity should remain in Prospecting stage');
            } else if (opp.Name == 'Stale Closed Won Opp') {
                // This should remain in Closed Won stage
                System.assertEquals('Closed Won', opp.StageName, 'Stale closed won opportunity should remain in Closed Won stage');
            } else if (opp.Name == 'Stale Closed Lost Opp') {
                // This should remain in Closed Lost stage
                System.assertEquals('Closed Lost', opp.StageName, 'Stale closed lost opportunity should remain in Closed Lost stage');
            } else if (opp.Name == 'Stale Qualification Opp') {
                // This should remain in Qualification stage
                System.assertEquals('Qualification', opp.StageName, 'Stale qualification opportunity should remain in Qualification stage');
            }
        }
    }
    
    @isTest
    static void testBatchWithNoStaleOpportunities() {
        // Delete all opportunities and create only recent ones
        delete [SELECT Id FROM Opportunity];
        
        // Create test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create only recent prospecting opportunities
        List<Opportunity> recentOpportunities = new List<Opportunity>();
        for (Integer i = 0; i < 3; i++) {
            recentOpportunities.add(new Opportunity(
                Name = 'Recent Opp ' + i,
                AccountId = testAccount.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Amount = 10000
            ));
        }
        insert recentOpportunities;
        
        // Execute the batch job
        Test.startTest();
        StaleOpportunityCloser batchJob = new StaleOpportunityCloser();
        Database.executeBatch(batchJob, 200);
        Test.stopTest();
        
        // Verify all opportunities remain in Prospecting stage
        List<Opportunity> opportunitiesAfter = [
            SELECT Id, Name, StageName
            FROM Opportunity
        ];
        
        for (Opportunity opp : opportunitiesAfter) {
            System.assertEquals('Prospecting', opp.StageName, 'Recent opportunities should remain in Prospecting stage');
        }
    }
    
    @isTest
    static void testBatchWithEmptyResult() {
        // Delete all opportunities
        delete [SELECT Id FROM Opportunity];
        
        // Execute the batch job with no data
        Test.startTest();
        StaleOpportunityCloser batchJob = new StaleOpportunityCloser();
        Database.executeBatch(batchJob, 200);
        Test.stopTest();
        
        // Verify no exceptions were thrown
        System.assert(true, 'Batch should complete successfully with no data');
    }
} 