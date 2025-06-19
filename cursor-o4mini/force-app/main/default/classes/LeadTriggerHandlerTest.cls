@isTest
private class LeadTriggerHandlerTest {

    @isTest static void testSingleLeadConversion() {
        // Create a lead and an account to simulate conversion
        Lead ld = new Lead(FirstName='Test', LastName='Lead', Company='TestCo');
        insert ld;
        Account acc = new Account(Name='TestAcc');
        insert acc;
        
        // Simulate lead conversion
        ld.IsConverted = true;
        ld.ConvertedAccountId = acc.Id;
        update ld;
        
        // Verify account description was populated
        acc = [SELECT Description FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Converted from ' + ld.Name, acc.Description);
    }

    @isTest static void testBulkLeadConversion() {
        // Create multiple leads and accounts
        List<Lead> leads = new List<Lead>();
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            leads.add(new Lead(FirstName='Bulk', LastName='Lead' + i, Company='TestCo'));
            accounts.add(new Account(Name='BulkAcc' + i));
        }
        insert leads;
        insert accounts;
        
        // Map accounts to leads by index
        Map<Id, String> expected = new Map<Id, String>();
        for (Integer i = 0; i < leads.size(); i++) {
            leads[i].IsConverted = true;
            leads[i].ConvertedAccountId = accounts[i].Id;
            expected.put(accounts[i].Id, 'Converted from ' + leads[i].Name);
        }
        
        // Bulk update leads to fire trigger
        update leads;
        
        // Verify all accounts have the correct descriptions
        for (Account a : [SELECT Id, Description FROM Account WHERE Id IN :expected.keySet()]) {
            System.assertEquals(expected.get(a.Id), a.Description);
        }
    }

    @isTest static void testAccountDescriptionAlreadyPopulated() {
        // Create lead and account with pre-populated description
        Lead ld = new Lead(FirstName='Existing', LastName='Lead', Company='TestCo');
        insert ld;
        Account acc = new Account(Name='ExistingAcc', Description='AlreadySet');
        insert acc;
        
        // Simulate conversion
        ld.IsConverted = true;
        ld.ConvertedAccountId = acc.Id;
        update ld;
        
        // Verify existing description was not overwritten
        acc = [SELECT Description FROM Account WHERE Id = :acc.Id];
        System.assertEquals('AlreadySet', acc.Description);
    }
} 