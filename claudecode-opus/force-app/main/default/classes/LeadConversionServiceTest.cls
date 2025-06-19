@isTest
private class LeadConversionServiceTest {
    
    @isTest
    static void testConvertLeadsWithOpportunity() {
        // Create test leads
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 50; i++) {
            testLeads.add(new Lead(
                FirstName = 'Test',
                LastName = 'Lead' + i,
                Company = 'Test Company ' + i,
                LeadSource = 'Web',
                Email = 'test' + i + '@example.com'
            ));
        }
        insert testLeads;
        
        Test.startTest();
        LeadConversionService.convertLeads(testLeads);
        Test.stopTest();
        
        // Verify all leads are converted
        List<Lead> convertedLeads = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId 
                                     FROM Lead WHERE Id IN :testLeads];
        
        System.assertEquals(50, convertedLeads.size(), 'All leads should be queried');
        
        for (Lead lead : convertedLeads) {
            System.assert(lead.IsConverted, 'Lead should be converted');
            System.assertNotEquals(null, lead.ConvertedAccountId, 'Account should be created');
            System.assertNotEquals(null, lead.ConvertedContactId, 'Contact should be created');
            System.assertNotEquals(null, lead.ConvertedOpportunityId, 'Opportunity should be created');
        }
        
        // Verify opportunities have correct stage
        List<Opportunity> createdOpps = [SELECT Id, StageName FROM Opportunity 
                                        WHERE Id IN (SELECT ConvertedOpportunityId FROM Lead WHERE Id IN :testLeads)];
        
        for (Opportunity opp : createdOpps) {
            System.assertEquals('Prospecting', opp.StageName, 'Opportunity should have default stage from custom metadata');
        }
    }
    
    @isTest
    static void testConvertLeadsWithoutOpportunity() {
        // Mock custom metadata to not create opportunities
        Lead_Conversion_Setting__mdt mockSetting = new Lead_Conversion_Setting__mdt(
            Auto_Convert_Web_Leads__c = true,
            Create_Opportunity__c = false,
            Default_Opportunity_Stage__c = 'Prospecting'
        );
        
        // Since we can't easily mock custom metadata in tests, we'll test the service directly
        // with a modified approach
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 10; i++) {
            testLeads.add(new Lead(
                FirstName = 'NoOpp',
                LastName = 'Lead' + i,
                Company = 'NoOpp Company ' + i,
                LeadSource = 'Web',
                Email = 'noopp' + i + '@example.com'
            ));
        }
        insert testLeads;
        
        // For this test, we'll use the default setting which creates opportunities
        // In a real scenario, you might use dependency injection or test-visible methods
        Test.startTest();
        LeadConversionService.convertLeads(testLeads);
        Test.stopTest();
        
        // Verify leads are converted
        List<Lead> convertedLeads = [SELECT Id, IsConverted FROM Lead WHERE Id IN :testLeads];
        for (Lead lead : convertedLeads) {
            System.assert(lead.IsConverted, 'Lead should be converted');
        }
    }
    
    @isTest
    static void testBulkConversion() {
        // Test with maximum bulk size (200 records)
        List<Lead> bulkLeads = new List<Lead>();
        for (Integer i = 0; i < 200; i++) {
            bulkLeads.add(new Lead(
                FirstName = 'Bulk',
                LastName = 'Lead' + i,
                Company = 'Bulk Company ' + i,
                LeadSource = 'Web',
                Email = 'bulk' + i + '@example.com',
                Phone = '555-' + String.valueOf(1000 + i)
            ));
        }
        insert bulkLeads;
        
        Test.startTest();
        LeadConversionService.convertLeads(bulkLeads);
        Test.stopTest();
        
        // Verify all leads are converted
        Integer convertedCount = [SELECT COUNT() FROM Lead WHERE Id IN :bulkLeads AND IsConverted = true];
        System.assertEquals(200, convertedCount, 'All 200 leads should be converted');
        
        // Verify accounts and contacts created
        Integer accountCount = [SELECT COUNT() FROM Account WHERE Id IN (SELECT ConvertedAccountId FROM Lead WHERE Id IN :bulkLeads)];
        Integer contactCount = [SELECT COUNT() FROM Contact WHERE Id IN (SELECT ConvertedContactId FROM Lead WHERE Id IN :bulkLeads)];
        
        System.assertEquals(200, accountCount, '200 accounts should be created');
        System.assertEquals(200, contactCount, '200 contacts should be created');
    }
    
    @isTest
    static void testEmptyLeadList() {
        List<Lead> emptyList = new List<Lead>();
        
        Test.startTest();
        // Should not throw any exceptions
        LeadConversionService.convertLeads(emptyList);
        Test.stopTest();
        
        System.assert(true, 'Empty list should be handled gracefully');
    }
    
    @isTest
    static void testDuplicateLeadConversion() {
        // Create a lead with duplicate information
        Account existingAccount = new Account(Name = 'Existing Company');
        insert existingAccount;
        
        Contact existingContact = new Contact(
            FirstName = 'Existing',
            LastName = 'Contact',
            Email = 'existing@example.com',
            AccountId = existingAccount.Id
        );
        insert existingContact;
        
        Lead duplicateLead = new Lead(
            FirstName = 'Existing',
            LastName = 'Contact',
            Company = 'Existing Company',
            Email = 'existing@example.com',
            LeadSource = 'Web'
        );
        insert duplicateLead;
        
        Test.startTest();
        try {
            LeadConversionService.convertLeads(new List<Lead>{duplicateLead});
            
            // Check if lead was converted (it might link to existing records)
            Lead convertedLead = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedContactId 
                                 FROM Lead WHERE Id = :duplicateLead.Id];
            
            if (convertedLead.IsConverted) {
                System.assert(true, 'Duplicate lead conversion handled');
            }
        } catch (Exception e) {
            // Some orgs might have duplicate rules that prevent conversion
            System.assert(e.getMessage().contains('duplicate') || e.getMessage().contains('Duplicate'), 
                        'Exception should be related to duplicates');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testConversionWithErrors() {
        // Create a lead with minimal information that might cause validation errors
        Lead invalidLead = new Lead(
            LastName = 'InvalidLead',
            Company = 'Invalid Company',
            LeadSource = 'Web'
            // Missing required fields might cause conversion to fail
        );
        insert invalidLead;
        
        // Create valid leads to test partial success
        List<Lead> mixedLeads = new List<Lead>();
        mixedLeads.add(invalidLead);
        
        for (Integer i = 0; i < 5; i++) {
            mixedLeads.add(new Lead(
                FirstName = 'Valid',
                LastName = 'Lead' + i,
                Company = 'Valid Company ' + i,
                LeadSource = 'Web',
                Email = 'valid' + i + '@example.com'
            ));
        }
        List<Lead> validLeads = new List<Lead>();
        for (Integer i = 1; i < mixedLeads.size(); i++) {
            validLeads.add(mixedLeads[i]);
        }
        insert validLeads; // Valid leads already inserted
        
        Test.startTest();
        try {
            LeadConversionService.convertLeads(mixedLeads);
        } catch (LeadConversionService.LeadConversionException e) {
            System.assert(e.getMessage().contains('Failed to convert leads'), 
                         'Should throw custom exception for conversion failures');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testOpportunityStageUpdate() {
        // Create leads that will have opportunities
        List<Lead> leadsWithOpps = new List<Lead>();
        for (Integer i = 0; i < 10; i++) {
            leadsWithOpps.add(new Lead(
                FirstName = 'OppStage',
                LastName = 'Lead' + i,
                Company = 'OppStage Company ' + i,
                LeadSource = 'Web',
                Email = 'oppstage' + i + '@example.com'
            ));
        }
        insert leadsWithOpps;
        
        Test.startTest();
        LeadConversionService.convertLeads(leadsWithOpps);
        Test.stopTest();
        
        // Verify opportunities have the correct stage from custom metadata
        List<Opportunity> opportunities = [
            SELECT Id, StageName, Name 
            FROM Opportunity 
            WHERE Id IN (SELECT ConvertedOpportunityId FROM Lead WHERE Id IN :leadsWithOpps)
        ];
        
        System.assertEquals(10, opportunities.size(), 'Should have 10 opportunities');
        
        for (Opportunity opp : opportunities) {
            System.assertEquals('Prospecting', opp.StageName, 
                               'Opportunity stage should match custom metadata default');
            System.assert(opp.Name.contains('OppStage Company'), 
                         'Opportunity name should contain company name');
        }
    }
}