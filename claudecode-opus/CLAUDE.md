# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Salesforce DX (SFDX) project named "claudecode-opus" configured for developing custom Salesforce applications, Lightning Web Components, and Apex code. The project uses API version 64.0.

## Common Development Commands

### Build, Lint, and Test Commands

```bash
# Lint JavaScript files in aura and lwc directories
npm run lint

# Run all unit tests
npm test
# or
npm run test:unit

# Run tests in watch mode (auto-rerun on file changes)
npm run test:unit:watch

# Run tests with debugging enabled
npm run test:unit:debug

# Run tests with coverage report
npm run test:unit:coverage

# Format all code files
npm run prettier

# Check formatting without making changes
npm run prettier:verify
```

### Salesforce CLI Commands

**IMPORTANT**: Always use the `claudecodeopus` scratch org for this project.

```bash
# Create a scratch org (if needed)
sf org create scratch -f config/project-scratch-def.json -a claudecodeopus

# Push source to scratch org
sf project deploy start -o claudecodeopus

# Pull changes from scratch org
sf project retrieve start -o claudecodeopus

# Open scratch org
sf org open -o claudecodeopus

# Run Apex tests
sf apex test run -l RunLocalTests -w 10 -o claudecodeopus

# Execute anonymous Apex
sf apex run -f scripts/apex/hello.apex -o claudecodeopus

# Run SOQL query
sf data query -q "SELECT Id, Name FROM Account" -o claudecodeopus
```

## Architecture and Structure

### Source Organization
All Salesforce metadata is located in `/force-app/main/default/`:
- **lwc/** - Lightning Web Components (modern UI framework)
- **aura/** - Aura components (legacy Lightning components)
- **classes/** - Apex classes (server-side business logic)
- **triggers/** - Apex triggers for database events
- **objects/** - Custom objects and field definitions
- **permissionsets/** - Permission set configurations
- **applications/** - Custom app definitions
- **flexipages/** - Lightning page layouts

### Key Patterns
1. **Lightning Web Components**: Located in `lwc/` directory, each component has its own folder with .js, .html, and .js-meta.xml files
2. **Apex Classes**: Server-side logic in `classes/` with corresponding .cls-meta.xml files
3. **Test Classes**: Apex test classes should follow the naming pattern `*Test.cls`

### Development Workflow
1. Code is developed locally and pushed to scratch orgs for testing
2. Pre-commit hooks run Prettier formatting and ESLint checks automatically
3. Jest is used for LWC unit testing
4. Apex tests are run in the scratch org environment