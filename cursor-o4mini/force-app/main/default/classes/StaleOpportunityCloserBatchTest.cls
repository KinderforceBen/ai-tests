@isTest
private class StaleOpportunityCloserBatchTest {
    @isTest
    static void testStaleOpportunityClosure() {
        // Create test opportunities
        Opportunity oppToClose = new Opportunity(
            Name = 'Prospecting Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        Opportunity oppOtherStage = new Opportunity(
            Name = 'Other Stage Opp',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30)
        );
        insert new List<Opportunity>{ oppToClose, oppOtherStage };

        Test.startTest();
        // Use a cutoff date in the future so the test record qualifies
        StaleOpportunityCloserBatch batch = new StaleOpportunityCloserBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Retrieve records to verify changes
        oppToClose = [SELECT StageName FROM Opportunity WHERE Id = :oppToClose.Id];
        oppOtherStage = [SELECT StageName FROM Opportunity WHERE Id = :oppOtherStage.Id];

        // Assert only the prospecting opportunity was closed
        System.assertEquals('Closed Lost', oppToClose.StageName);
        System.assertEquals('Qualification', oppOtherStage.StageName);
    }
} 