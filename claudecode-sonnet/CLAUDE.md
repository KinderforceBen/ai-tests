# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Salesforce DX project using the standard Salesforce development model. The project uses Lightning Web Components (LWC) and Aura components for the frontend, with Apex for server-side logic.

## Architecture

- **force-app/main/default/**: Main source directory containing all Salesforce metadata
  - **lwc/**: Lightning Web Components 
  - **aura/**: Aura components
  - **classes/**: Apex classes
  - **triggers/**: Apex triggers  
  - **objects/**: Custom objects and fields
  - **layouts/**: Page layouts
  - **flexipages/**: Lightning pages
  - **permissionsets/**: Permission sets
  - **applications/**: Custom applications
  - **tabs/**: Custom tabs
  - **staticresources/**: Static resources

## Common Commands

### Development
- `npm run lint` - Lint JavaScript code in Aura and LWC components
- `npm run prettier` - Format all code files
- `npm run prettier:verify` - Check code formatting

### LWC Unit Testing (Local)
- `npm run test` or `npm run test:unit` - Run all LWC unit tests
- `npm run test:unit:watch` - Run tests in watch mode
- `npm run test:unit:debug` - Run tests in debug mode
- `npm run test:unit:coverage` - Run tests with coverage report

### Salesforce Deployment and Testing
**IMPORTANT**: Always deploy to and run tests in the 'claudecodesonnet' scratch org

- Deploy: `sf project deploy start --target-org claudecodesonnet`
- Retrieve: `sf project retrieve start --target-org claudecodesonnet`
- Run Apex tests: `sf apex run test --target-org claudecodesonnet`
- Run specific test class: `sf apex run test --class-names TestClassName --target-org claudecodesonnet`

## Development Notes

- Lightning Web Components use the `c/` namespace for component imports
- Jest is configured for LWC unit testing with `@salesforce/sfdx-lwc-jest`
- Husky and lint-staged are configured for pre-commit hooks
- Source API version is 64.0
- Always use 'claudecodesonnet' as the target org for all Salesforce operations