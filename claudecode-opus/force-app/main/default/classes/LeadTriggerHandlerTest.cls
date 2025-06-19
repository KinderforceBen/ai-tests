@isTest
private class LeadTriggerHandlerTest {
    
    @TestSetup
    static void setup() {
        // Create test data that will be used across test methods
        List<Lead> testLeads = new List<Lead>();
        
        // Create non-web leads
        for (Integer i = 0; i < 50; i++) {
            testLeads.add(new Lead(
                FirstName = 'Test',
                LastName = 'NonWebLead' + i,
                Company = 'Test Company ' + i,
                LeadSource = 'Phone Inquiry',
                Email = 'nonweb' + i + '@test.com'
            ));
        }
        
        // Create web leads
        for (Integer i = 0; i < 50; i++) {
            testLeads.add(new Lead(
                FirstName = 'Test',
                LastName = 'WebLead' + i,
                Company = 'Web Company ' + i,
                LeadSource = 'Web',
                Email = 'web' + i + '@test.com'
            ));
        }
        
        insert testLeads;
    }
    
    @isTest
    static void testSingleWebLeadConversion() {
        // Bypass trigger for setup
        LeadTriggerHandler.bypassTrigger = true;
        
        Lead webLead = new Lead(
            FirstName = 'Single',
            LastName = 'WebLead',
            Company = 'Single Web Company',
            LeadSource = 'Other',
            Email = 'singleweb@test.com'
        );
        insert webLead;
        
        // Enable trigger and update to Web source
        LeadTriggerHandler.bypassTrigger = false;
        
        Test.startTest();
        webLead.LeadSource = 'Web';
        update webLead;
        Test.stopTest();
        
        // Verify conversion
        Lead convertedLead = [SELECT Id, IsConverted FROM Lead WHERE Id = :webLead.Id];
        System.assert(convertedLead.IsConverted, 'Web lead should be converted');
    }
    
    @isTest
    static void testBulkWebLeadConversion() {
        // Delete existing leads to start fresh
        delete [SELECT Id FROM Lead];
        
        // Create 200 web leads
        List<Lead> bulkWebLeads = new List<Lead>();
        for (Integer i = 0; i < 200; i++) {
            bulkWebLeads.add(new Lead(
                FirstName = 'Bulk',
                LastName = 'WebLead' + i,
                Company = 'Bulk Company ' + i,
                LeadSource = 'Web',
                Email = 'bulkweb' + i + '@test.com'
            ));
        }
        
        Test.startTest();
        insert bulkWebLeads;
        Test.stopTest();
        
        // Verify all web leads are converted
        List<Lead> convertedLeads = [SELECT Id, IsConverted FROM Lead WHERE Id IN :bulkWebLeads];
        System.assertEquals(200, convertedLeads.size(), 'All leads should be queried');
        
        for (Lead lead : convertedLeads) {
            System.assert(lead.IsConverted, 'All web leads should be converted');
        }
    }
    
    @isTest
    static void testNonWebLeadsNotConverted() {
        // Create non-web leads
        List<Lead> nonWebLeads = new List<Lead>();
        for (Integer i = 0; i < 50; i++) {
            nonWebLeads.add(new Lead(
                FirstName = 'NonWeb',
                LastName = 'Lead' + i,
                Company = 'NonWeb Company ' + i,
                LeadSource = 'Phone Inquiry',
                Email = 'nonweb' + i + '@test.com'
            ));
        }
        
        Test.startTest();
        insert nonWebLeads;
        Test.stopTest();
        
        // Verify non-web leads are not converted
        List<Lead> unconvertedLeads = [SELECT Id, IsConverted FROM Lead WHERE Id IN :nonWebLeads];
        for (Lead lead : unconvertedLeads) {
            System.assert(!lead.IsConverted, 'Non-web leads should not be converted');
        }
    }
    
    @isTest
    static void testLeadSourceUpdateToWeb() {
        // Get existing non-web leads
        List<Lead> nonWebLeads = [SELECT Id, LeadSource FROM Lead WHERE LeadSource != 'Web' LIMIT 50];
        System.assert(!nonWebLeads.isEmpty(), 'Should have non-web leads from setup');
        
        // Update their source to Web
        for (Lead lead : nonWebLeads) {
            lead.LeadSource = 'Web';
        }
        
        Test.startTest();
        update nonWebLeads;
        Test.stopTest();
        
        // Verify they are converted
        List<Lead> convertedLeads = [SELECT Id, IsConverted FROM Lead WHERE Id IN :nonWebLeads];
        for (Lead lead : convertedLeads) {
            System.assert(lead.IsConverted, 'Leads updated to Web source should be converted');
        }
    }
    
    @isTest
    static void testAlreadyConvertedLeadsNotProcessed() {
        // Manually convert a lead
        LeadTriggerHandler.bypassTrigger = true;
        
        Lead manualLead = new Lead(
            FirstName = 'Manual',
            LastName = 'ConvertLead',
            Company = 'Manual Company',
            LeadSource = 'Other',
            Email = 'manual@test.com'
        );
        insert manualLead;
        
        // Convert it manually
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(manualLead.Id);
        lc.setConvertedStatus('Closed - Converted');
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess(), 'Manual conversion should succeed');
        
        // Enable trigger and try to update
        LeadTriggerHandler.bypassTrigger = false;
        
        Test.startTest();
        Lead convertedLead = [SELECT Id, LeadSource, IsConverted FROM Lead WHERE Id = :manualLead.Id];
        convertedLead.LeadSource = 'Web';
        update convertedLead;
        Test.stopTest();
        
        // Should still be converted but not throw any errors
        Lead finalLead = [SELECT Id, IsConverted FROM Lead WHERE Id = :manualLead.Id];
        System.assert(finalLead.IsConverted, 'Lead should remain converted');
    }
    
    @isTest
    static void testTriggerBypass() {
        // Enable bypass
        LeadTriggerHandler.bypassTrigger = true;
        
        // Create web leads
        List<Lead> webLeads = new List<Lead>();
        for (Integer i = 0; i < 10; i++) {
            webLeads.add(new Lead(
                FirstName = 'Bypass',
                LastName = 'WebLead' + i,
                Company = 'Bypass Company ' + i,
                LeadSource = 'Web',
                Email = 'bypass' + i + '@test.com'
            ));
        }
        
        Test.startTest();
        insert webLeads;
        Test.stopTest();
        
        // Verify they are NOT converted due to bypass
        List<Lead> unconvertedLeads = [SELECT Id, IsConverted FROM Lead WHERE Id IN :webLeads];
        for (Lead lead : unconvertedLeads) {
            System.assert(!lead.IsConverted, 'Web leads should not be converted when trigger is bypassed');
        }
        
        // Reset bypass
        LeadTriggerHandler.bypassTrigger = false;
    }
}