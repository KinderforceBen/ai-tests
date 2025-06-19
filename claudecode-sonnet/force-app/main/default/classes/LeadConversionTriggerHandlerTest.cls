@isTest
public class LeadConversionTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test leads
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 5; i++) {
            testLeads.add(new Lead(
                FirstName = 'Test',
                LastName = 'Lead ' + i,
                Company = 'Test Company ' + i,
                Email = 'testlead' + i + '@example.com',
                Status = 'Open - Not Contacted'
            ));
        }
        insert testLeads;
    }
    
    @isTest
    static void testSingleLeadConversion() {
        // Get a test lead with explicit name fields
        Lead testLead = [SELECT Id, FirstName, LastName FROM Lead LIMIT 1];
        String expectedLeadName = testLead.FirstName + ' ' + testLead.LastName;
        
        Test.startTest();
        
        // Convert the lead
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        lc.setConvertedStatus('Closed - Converted');
        lc.setDoNotCreateOpportunity(true);
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        
        Test.stopTest();
        
        // Verify conversion was successful
        System.assert(lcr.isSuccess(), 'Lead conversion should be successful');
        
        // Verify account description was set correctly
        Account convertedAccount = [SELECT Id, Description FROM Account WHERE Id = :lcr.getAccountId()];
        System.assertEquals('Converted from ' + expectedLeadName, convertedAccount.Description, 
                           'Account description should be set to "Converted from " + Lead Name');
    }
    
    @isTest
    static void testBulkLeadConversion() {
        // Get multiple test leads with explicit name fields
        List<Lead> testLeads = [SELECT Id, FirstName, LastName FROM Lead LIMIT 3];
        
        Test.startTest();
        
        // Convert leads in bulk
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        for (Lead lead : testLeads) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(lead.Id);
            lc.setConvertedStatus('Closed - Converted');
            lc.setDoNotCreateOpportunity(true);
            leadConverts.add(lc);
        }
        
        List<Database.LeadConvertResult> lcResults = Database.convertLead(leadConverts);
        
        Test.stopTest();
        
        // Verify all conversions were successful
        for (Database.LeadConvertResult lcr : lcResults) {
            System.assert(lcr.isSuccess(), 'All lead conversions should be successful');
        }
        
        // Collect account IDs and create expected descriptions map
        Set<Id> accountIds = new Set<Id>();
        Map<Id, String> expectedDescriptions = new Map<Id, String>();
        
        for (Integer i = 0; i < lcResults.size(); i++) {
            Id accountId = lcResults[i].getAccountId();
            accountIds.add(accountId);
            String expectedLeadName = testLeads[i].FirstName + ' ' + testLeads[i].LastName;
            expectedDescriptions.put(accountId, 'Converted from ' + expectedLeadName);
        }
        
        // Verify all account descriptions were set correctly
        List<Account> convertedAccounts = [SELECT Id, Description FROM Account WHERE Id IN :accountIds];
        
        for (Account acc : convertedAccounts) {
            System.assertEquals(expectedDescriptions.get(acc.Id), acc.Description, 
                               'Account description should be set correctly for bulk conversion');
        }
    }
    
    @isTest
    static void testAccountWithExistingDescription() {
        // Get a test lead
        Lead testLead = [SELECT Id, FirstName, LastName FROM Lead LIMIT 1];
        
        // Create an account with existing description
        Account existingAccount = new Account(
            Name = 'Existing Account',
            Description = 'Existing description that should not be overwritten'
        );
        insert existingAccount;
        
        Test.startTest();
        
        // Convert the lead to the existing account
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        lc.setAccountId(existingAccount.Id);
        lc.setConvertedStatus('Closed - Converted');
        lc.setDoNotCreateOpportunity(true);
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        
        Test.stopTest();
        
        // Verify conversion was successful
        System.assert(lcr.isSuccess(), 'Lead conversion should be successful');
        
        // Verify account description was NOT changed
        Account updatedAccount = [SELECT Id, Description FROM Account WHERE Id = :existingAccount.Id];
        System.assertEquals('Existing description that should not be overwritten', updatedAccount.Description, 
                           'Account description should not be overwritten when it already has content');
    }
    
    @isTest
    static void testLeadUpdateWithoutConversion() {
        // Get a test lead
        Lead testLead = [SELECT Id, Name, Status FROM Lead LIMIT 1];
        
        Test.startTest();
        
        // Update lead without converting
        testLead.Status = 'Working - Contacted';
        update testLead;
        
        Test.stopTest();
        
        // Verify no accounts were created (trigger should not fire for non-conversion updates)
        List<Account> accounts = [SELECT Id FROM Account];
        System.assertEquals(0, accounts.size(), 'No accounts should be created for non-conversion updates');
    }
    
    @isTest
    static void testAlreadyConvertedLeadUpdate() {
        // Get a test lead and convert it first
        Lead testLead = [SELECT Id, FirstName, LastName FROM Lead LIMIT 1];
        String expectedLeadName = testLead.FirstName + ' ' + testLead.LastName;
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        lc.setConvertedStatus('Closed - Converted');
        lc.setDoNotCreateOpportunity(true);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        
        // Get the converted lead
        Lead convertedLead = [SELECT Id, IsConverted, ConvertedAccountId FROM Lead WHERE Id = :testLead.Id];
        
        Test.startTest();
        
        // Try to update the already converted lead (should not trigger our logic)
        // Note: Most fields on converted leads are read-only, but we can try updating a custom field
        // For this test, we'll simulate the scenario by testing our handler directly
        List<Lead> oldLeads = new List<Lead>{new Lead(Id = convertedLead.Id, IsConverted = true)};
        List<Lead> newLeads = new List<Lead>{convertedLead};
        
        // This should not cause any DML operations since the lead was already converted
        LeadConversionTriggerHandler.handleAfterUpdate(oldLeads, newLeads);
        
        Test.stopTest();
        
        // Verify account description remains unchanged from first conversion
        Account convertedAccount = [SELECT Id, Description FROM Account WHERE Id = :lcr.getAccountId()];
        System.assertEquals('Converted from ' + expectedLeadName, convertedAccount.Description, 
                           'Account description should remain from initial conversion');
    }
}