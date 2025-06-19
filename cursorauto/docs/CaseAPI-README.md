# CaseAPI REST Endpoint Documentation

## Overview
The CaseAPI provides a REST endpoint for external systems to create Cases in Salesforce without using the UI. This enables automated ticket intake from external support systems.

## Endpoint
```
POST /services/apexrest/CaseAPI/v1/create
```

## Request Format

### Headers
```
Content-Type: application/json
Authorization: Bearer {access_token}
```

### Request Body (JSON)
```json
{
    "subject": "Case Subject",
    "description": "Case Description",
    "priority": "High",
    "contactEmail": "user@example.com"
}
```

### Field Descriptions
- **subject** (required): The case subject/title
- **description** (required): Detailed description of the case
- **priority** (required): Case priority - must be one of: `Low`, `Medium`, `High`, `Critical`
- **contactEmail** (optional): Email address to link the case to an existing Contact

## Response Format

### Success Response
```json
{
    "success": true,
    "caseId": "500xx000001ABCDAAA",
    "errors": []
}
```

### Error Response
```json
{
    "success": false,
    "caseId": null,
    "errors": [
        "Subject is required",
        "Priority must be one of: Low, Medium, High, Critical"
    ]
}
```

## Business Logic

1. **JSON Parsing**: The API parses the incoming JSON into an Apex wrapper class
2. **Validation**: Validates all required fields and data formats
3. **Contact Lookup**: If a contactEmail is provided, searches for an existing Contact
4. **Case Creation**: Creates a new Case record with the provided data
5. **Response**: Returns success/error status with case ID or error messages

## Usage Examples

### cURL Example
```bash
curl -X POST \
  https://your-instance.salesforce.com/services/apexrest/CaseAPI/v1/create \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_ACCESS_TOKEN' \
  -d '{
    "subject": "API Test Case",
    "description": "This case was created via the REST API",
    "priority": "High",
    "contactEmail": "john.doe@example.com"
  }'
```

### JavaScript Example
```javascript
const response = await fetch('/services/apexrest/CaseAPI/v1/create', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + accessToken
    },
    body: JSON.stringify({
        subject: 'API Test Case',
        description: 'This case was created via the REST API',
        priority: 'High',
        contactEmail: 'john.doe@example.com'
    })
});

const result = await response.json();
if (result.success) {
    console.log('Case created with ID:', result.caseId);
} else {
    console.error('Errors:', result.errors);
}
```

### Python Example
```python
import requests
import json

url = 'https://your-instance.salesforce.com/services/apexrest/CaseAPI/v1/create'
headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer YOUR_ACCESS_TOKEN'
}
data = {
    'subject': 'API Test Case',
    'description': 'This case was created via the REST API',
    'priority': 'High',
    'contactEmail': 'john.doe@example.com'
}

response = requests.post(url, headers=headers, json=data)
result = response.json()

if result['success']:
    print(f"Case created with ID: {result['caseId']}")
else:
    print(f"Errors: {result['errors']}")
```

## Error Handling

The API handles various error scenarios:

1. **JSON Parsing Errors**: Invalid JSON format
2. **Validation Errors**: Missing required fields or invalid data
3. **Database Errors**: Issues with case creation
4. **Unexpected Errors**: Any other runtime errors

All errors are returned in a consistent format with descriptive messages.

## Testing

The API includes comprehensive test coverage:
- Successful case creation with existing contact
- Successful case creation without contact
- Validation errors for missing fields
- Validation errors for invalid data
- JSON parsing errors
- All valid priority values

Run tests using:
```bash
sfdx force:apex:test:run --testlevel RunLocalTests --classnames CaseAPITest
```

## Security Considerations

- The API uses `with sharing` to respect Salesforce sharing rules
- Input validation prevents injection attacks
- Error messages don't expose sensitive information
- Authentication is required via Salesforce OAuth

## Limitations

- Contact lookup is case-sensitive
- Only one contact is linked per case (first match found)
- Priority values are restricted to predefined options
- Email validation uses basic regex pattern 