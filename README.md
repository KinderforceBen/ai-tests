## Challenge 1: Bulk Lead Conversion

**Use Case:**
Your org collects hundreds to thousands of web-to-lead submissions every day. Those Leads must be converted into Contact, Account and Opportunity records in one go, with a configurable default Opportunity stage.

**What We’re Looking For:**
- A bulk-safe solution that cleanly separates trigger logic from processing logic
- Usage of Custom Metadata to drive default settings
- Comprehensive unit tests covering both single-record and large-batch scenarios

**Time Estimate:** ~60 minutes

---

## Challenge 2: Nightly CSV-Driven Contact Updates

**Use Case:**
Marketing drops large CSV files (up to ~50 k rows) of contact updates into an external endpoint each night. You need to process them in Apex, update Contact records, record any row-level failures, and deliver a summary notification.

**What We’re Looking For:**
- A Batchable Apex implementation that reads CSV via a mockable HTTP callout
- Robust error-logging (without aborting the whole job) to a custom object
- Post-job notification (email or scheduler chaining) with success/failure counts
- Unit tests simulating both all-success and partial-failure scenarios

**Time Estimate:** ~60 minutes

---

## Challenge 3: REST-Based Case Synchronization

**Use Case:**
Your support org must push new Case records into an external ticketing system over REST, using a Named Credential for authentication. The external system returns a ticket ID that needs to be stored back on the Case.

**What We’re Looking For:**
- Apex callouts leveraging a Named Credential (no hard-coded endpoints)
- JSON serialization/deserialization and record updates
- Proper exception handling when the remote call fails
- HttpCalloutMock-driven tests for both success and error responses

**Time Estimate:** ~60 minutes

