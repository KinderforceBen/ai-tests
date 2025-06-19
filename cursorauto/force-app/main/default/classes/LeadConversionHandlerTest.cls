@isTest
private class LeadConversionHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test data that will be used across all test methods
    }
    
    @isTest
    static void testSingleLeadConversion() {
        // Test single Lead conversion scenario
        Lead testLead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'Test Company',
            Email = 'john.doe@testcompany.com'
        );
        insert testLead;
        
        Test.startTest();
        
        // Convert the Lead
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        lc.setConvertedStatus('Closed - Converted');
        lc.setDoNotCreateOpportunity(true);
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        
        Test.stopTest();
        
        // Verify the conversion was successful
        System.assert(lcr.isSuccess(), 'Lead conversion should be successful');
        
        // Query the converted Account
        Account convertedAccount = [
            SELECT Id, Description 
            FROM Account 
            WHERE Id = :lcr.getAccountId()
        ];
        
        // Verify the Description was populated correctly
        System.assertEquals(
            'Converted from John Doe', 
            convertedAccount.Description, 
            'Account Description should be populated with Lead name'
        );
    }
    
    @isTest
    static void testBulkLeadConversion() {
        // Test bulk Lead conversion scenario
        List<Lead> testLeads = new List<Lead>();
        
        // Create 200 test Leads (bulk scenario)
        for (Integer i = 0; i < 200; i++) {
            testLeads.add(new Lead(
                FirstName = 'Bulk',
                LastName = 'User ' + i,
                Company = 'Bulk Company ' + i,
                Email = 'bulk.user' + i + '@bulkcompany.com'
            ));
        }
        insert testLeads;
        
        Test.startTest();
        
        // Convert all Leads
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        for (Lead lead : testLeads) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(lead.Id);
            lc.setConvertedStatus('Closed - Converted');
            lc.setDoNotCreateOpportunity(true);
            leadConverts.add(lc);
        }
        
        List<Database.LeadConvertResult> results = Database.convertLead(leadConverts);
        
        Test.stopTest();
        
        // Verify all conversions were successful
        for (Database.LeadConvertResult result : results) {
            System.assert(result.isSuccess(), 'All Lead conversions should be successful');
        }
        
        // Query converted Accounts
        Set<Id> accountIds = new Set<Id>();
        for (Database.LeadConvertResult result : results) {
            accountIds.add(result.getAccountId());
        }
        
        List<Account> convertedAccounts = [
            SELECT Id, Description 
            FROM Account 
            WHERE Id IN :accountIds
        ];
        
        // Verify all Accounts have the correct Description
        System.assertEquals(200, convertedAccounts.size(), 'Should have 200 converted Accounts');
        
        for (Account acc : convertedAccounts) {
            System.assert(
                acc.Description != null && acc.Description.startsWith('Converted from Bulk User'),
                'All Account Descriptions should be populated with Lead names'
            );
        }
    }
    
    @isTest
    static void testAccountWithExistingDescription() {
        // Test scenario where Account already has a non-blank Description
        Lead testLead = new Lead(
            FirstName = 'Jane',
            LastName = 'Smith',
            Company = 'Existing Description Company',
            Email = 'jane.smith@existingcompany.com'
        );
        insert testLead;
        
        // Convert the Lead
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        lc.setConvertedStatus('Closed - Converted');
        lc.setDoNotCreateOpportunity(true);
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        
        // Manually update the Account Description to simulate existing data
        Account existingAccount = [
            SELECT Id, Description 
            FROM Account 
            WHERE Id = :lcr.getAccountId()
        ];
        
        String originalDescription = 'This is an existing description that should not be overwritten';
        existingAccount.Description = originalDescription;
        update existingAccount;
        
        Test.startTest();
        
        // Update the Lead to trigger the conversion logic again
        Lead updatedLead = [
            SELECT Id, IsConverted, ConvertedAccountId 
            FROM Lead 
            WHERE Id = :testLead.Id
        ];
        update updatedLead;
        
        Test.stopTest();
        
        // Query the Account again to verify Description was not changed
        Account finalAccount = [
            SELECT Id, Description 
            FROM Account 
            WHERE Id = :lcr.getAccountId()
        ];
        
        // Verify the Description remains unchanged
        System.assertEquals(
            originalDescription, 
            finalAccount.Description, 
            'Account Description should remain unchanged when already populated'
        );
    }
    
    @isTest
    static void testLeadConversionWithoutAccount() {
        // Test scenario where Lead conversion doesn't create an Account
        Lead testLead = new Lead(
            FirstName = 'No',
            LastName = 'Account',
            Company = 'No Account Company',
            Email = 'no.account@nocompany.com'
        );
        insert testLead;
        
        Test.startTest();
        
        // Convert Lead without creating Account
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        lc.setConvertedStatus('Closed - Converted');
        lc.setDoNotCreateOpportunity(true);
        lc.setDoNotCreateAccount(true); // Don't create Account
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        
        Test.stopTest();
        
        // Verify conversion was successful but no Account was created
        System.assert(lcr.isSuccess(), 'Lead conversion should be successful');
        System.assertEquals(null, lcr.getAccountId(), 'No Account should be created');
    }
    
    @isTest
    static void testLeadNotConverted() {
        // Test scenario where Lead is not converted (should not trigger Account update)
        Lead testLead = new Lead(
            FirstName = 'Not',
            LastName = 'Converted',
            Company = 'Not Converted Company',
            Email = 'not.converted@nocompany.com'
        );
        insert testLead;
        
        Test.startTest();
        
        // Update Lead without converting
        testLead.Company = 'Updated Company Name';
        update testLead;
        
        Test.stopTest();
        
        // Verify no Account was created
        List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Not Converted Company'];
        System.assertEquals(0, accounts.size(), 'No Account should be created for non-converted Lead');
    }
} 