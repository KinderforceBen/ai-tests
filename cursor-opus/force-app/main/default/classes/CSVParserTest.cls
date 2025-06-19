/**
 * Test class for CSVParser utility
 */
@isTest
private class CSVParserTest {
    
    /**
     * Test basic CSV parsing
     */
    @isTest
    static void testBasicCSVParsing() {
        String csv = 'Name,Email,Phone\n';
        csv += 'John Doe,john@example.com,555-1234\n';
        csv += 'Jane Smith,jane@example.com,555-5678\n';
        
        List<Map<String, String>> result = CSVParser.parseCSV(csv);
        
        System.assertEquals(2, result.size(), 'Should parse 2 rows');
        System.assertEquals('John Doe', result[0].get('Name'), 'First row name');
        System.assertEquals('john@example.com', result[0].get('Email'), 'First row email');
        System.assertEquals('555-1234', result[0].get('Phone'), 'First row phone');
        System.assertEquals('Jane Smith', result[1].get('Name'), 'Second row name');
    }
    
    /**
     * Test CSV with quotes and commas
     */
    @isTest
    static void testCSVWithQuotesAndCommas() {
        String csv = 'Name,Title,Company\n';
        csv += '"Smith, John","CEO, Inc.","ACME, Corp"\n';
        csv += 'Jane Doe,Manager,"Simple Co"\n';
        
        List<Map<String, String>> result = CSVParser.parseCSV(csv);
        
        System.assertEquals(2, result.size(), 'Should parse 2 rows');
        System.assertEquals('Smith, John', result[0].get('Name'), 'Should handle comma in quoted field');
        System.assertEquals('CEO, Inc.', result[0].get('Title'), 'Should handle comma in title');
        System.assertEquals('ACME, Corp', result[0].get('Company'), 'Should handle comma in company');
    }
    
    /**
     * Test CSV with escaped quotes
     */
    @isTest
    static void testCSVWithEscapedQuotes() {
        String csv = 'Name,Nickname\n';
        csv += 'John,"Johnny ""The Great"" Doe"\n';
        csv += '"O\'Brien, Pat","Pat"\n';
        
        List<Map<String, String>> result = CSVParser.parseCSV(csv);
        
        System.assertEquals(2, result.size(), 'Should parse 2 rows');
        System.assertEquals('Johnny "The Great" Doe', result[0].get('Nickname'), 'Should handle escaped quotes');
        System.assertEquals('O\'Brien, Pat', result[1].get('Name'), 'Should handle apostrophe and comma');
    }
    
    /**
     * Test empty CSV
     */
    @isTest
    static void testEmptyCSV() {
        List<Map<String, String>> result = CSVParser.parseCSV('');
        System.assertEquals(0, result.size(), 'Empty string should return empty list');
        
        result = CSVParser.parseCSV(null);
        System.assertEquals(0, result.size(), 'Null should return empty list');
    }
    
    /**
     * Test CSV with empty lines
     */
    @isTest
    static void testCSVWithEmptyLines() {
        String csv = 'Name,Email\n';
        csv += 'John,john@example.com\n';
        csv += '\n';  // Empty line
        csv += 'Jane,jane@example.com\n';
        csv += '   \n';  // Line with spaces
        
        List<Map<String, String>> result = CSVParser.parseCSV(csv);
        
        System.assertEquals(2, result.size(), 'Should skip empty lines');
        System.assertEquals('John', result[0].get('Name'), 'First row');
        System.assertEquals('Jane', result[1].get('Name'), 'Second row');
    }
    
    /**
     * Test CSV with missing values
     */
    @isTest
    static void testCSVWithMissingValues() {
        String csv = 'Name,Email,Phone\n';
        csv += 'John,john@example.com,\n';  // Missing phone
        csv += 'Jane,,555-1234\n';  // Missing email
        csv += ',,\n';  // All missing
        
        List<Map<String, String>> result = CSVParser.parseCSV(csv);
        
        System.assertEquals(3, result.size(), 'Should parse all rows');
        System.assertEquals('', result[0].get('Phone'), 'Missing value should be empty string');
        System.assertEquals('', result[1].get('Email'), 'Missing email should be empty string');
        System.assertEquals('', result[2].get('Name'), 'All missing values should be empty strings');
    }
} 