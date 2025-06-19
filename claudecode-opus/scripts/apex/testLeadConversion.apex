// Create a test web lead
Lead webLead = new Lead(
    FirstName = 'Test',
    LastName = 'WebLead',
    Company = 'Test Web Company',
    LeadSource = 'Web',
    Email = 'test.weblead@example.com',
    Phone = '555-0001'
);

insert webLead;

// Query the lead to check if it was converted
Lead convertedLead = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId 
                      FROM Lead WHERE Id = :webLead.Id];

System.debug('Lead Created: ' + webLead.Id);
System.debug('Is Converted: ' + convertedLead.IsConverted);
System.debug('Account Id: ' + convertedLead.ConvertedAccountId);
System.debug('Contact Id: ' + convertedLead.ConvertedContactId);
System.debug('Opportunity Id: ' + convertedLead.ConvertedOpportunityId);

if (convertedLead.IsConverted) {
    // Check the opportunity stage
    Opportunity opp = [SELECT Id, Name, StageName FROM Opportunity WHERE Id = :convertedLead.ConvertedOpportunityId];
    System.debug('Opportunity Name: ' + opp.Name);
    System.debug('Opportunity Stage: ' + opp.StageName);
}