// Example usage of the CaseAPI REST endpoint
// This script demonstrates how to call the API programmatically

// Example 1: Create a case with an existing contact
String jsonPayload1 = JSON.serialize(new Map<String, Object>{
    'subject' => 'API Test Case - High Priority',
    'description' => 'This case was created via the REST API for testing purposes.',
    'priority' => 'High',
    'contactEmail' => 'john.doe@example.com'
});

System.debug('Example 1 - Valid case creation:');
System.debug(jsonPayload1);

// Example 2: Create a case without a contact (email doesn't exist)
String jsonPayload2 = JSON.serialize(new Map<String, Object>{
    'subject' => 'API Test Case - Medium Priority',
    'description' => 'This case was created via the REST API without an existing contact.',
    'priority' => 'Medium',
    'contactEmail' => 'nonexistent@example.com'
});

System.debug('Example 2 - Case creation without contact:');
System.debug(jsonPayload2);

// Example 3: Invalid payload (missing required fields)
String jsonPayload3 = JSON.serialize(new Map<String, Object>{
    'subject' => 'Incomplete Case',
    'priority' => 'InvalidPriority'
});

System.debug('Example 3 - Invalid payload:');
System.debug(jsonPayload3);

// Example 4: All valid priority values
List<String> priorities = new List<String>{'Low', 'Medium', 'High', 'Critical'};
for (String priority : priorities) {
    String jsonPayload = JSON.serialize(new Map<String, Object>{
        'subject' => 'Test Case - ' + priority + ' Priority',
        'description' => 'Testing ' + priority + ' priority level',
        'priority' => priority
    });
    System.debug('Example 4 - ' + priority + ' priority:');
    System.debug(jsonPayload);
}

// Note: To actually call the REST API, you would need to make an HTTP request
// to: /services/apexrest/CaseAPI/v1/create
// with the JSON payload in the request body 