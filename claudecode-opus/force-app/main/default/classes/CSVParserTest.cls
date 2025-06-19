@isTest
private class CSVParserTest {
    
    @isTest
    static void testBasicCSVParsing() {
        String csvContent = 'Name,Email,Phone\n';
        csvContent += 'John Doe,john@example.com,555-1234\n';
        csvContent += 'Jane Smith,jane@example.com,555-5678\n';
        
        List<CSVParser.CSVRow> rows = CSVParser.parse(csvContent);
        
        System.assertEquals(2, rows.size(), 'Should have 2 data rows');
        
        // Check first row
        CSVParser.CSVRow row1 = rows[0];
        System.assertEquals(2, row1.rowNumber);
        System.assertEquals('John Doe', row1.values.get('Name'));
        System.assertEquals('john@example.com', row1.values.get('Email'));
        System.assertEquals('555-1234', row1.values.get('Phone'));
        
        // Check second row
        CSVParser.CSVRow row2 = rows[1];
        System.assertEquals(3, row2.rowNumber);
        System.assertEquals('Jane Smith', row2.values.get('Name'));
    }
    
    @isTest
    static void testCSVWithQuotedValues() {
        String csvContent = 'Name,Title,Company\n';
        csvContent += '"Smith, John","VP, Sales","ABC Corp"\n';
        csvContent += '"O\'Brien, Mary","Director","XYZ ""International"" Ltd"\n';
        
        List<CSVParser.CSVRow> rows = CSVParser.parse(csvContent);
        
        System.assertEquals(2, rows.size());
        
        // Check handling of comma in quoted field
        System.assertEquals('Smith, John', rows[0].values.get('Name'));
        System.assertEquals('VP, Sales', rows[0].values.get('Title'));
        
        // Check handling of quotes within quoted field
        System.assertEquals('O\'Brien, Mary', rows[1].values.get('Name'));
        System.assertEquals('XYZ "International" Ltd', rows[1].values.get('Company'));
    }
    
    @isTest
    static void testEmptyCSV() {
        String csvContent = '';
        List<CSVParser.CSVRow> rows = CSVParser.parse(csvContent);
        System.assertEquals(0, rows.size(), 'Empty CSV should return empty list');
        
        csvContent = null;
        rows = CSVParser.parse(csvContent);
        System.assertEquals(0, rows.size(), 'Null CSV should return empty list');
    }
    
    @isTest
    static void testCSVWithEmptyLines() {
        String csvContent = 'Name,Email\n';
        csvContent += 'John,john@example.com\n';
        csvContent += '\n'; // Empty line
        csvContent += 'Jane,jane@example.com\n';
        csvContent += '   \n'; // Line with spaces
        
        List<CSVParser.CSVRow> rows = CSVParser.parse(csvContent);
        
        System.assertEquals(2, rows.size(), 'Should skip empty lines');
        System.assertEquals('John', rows[0].values.get('Name'));
        System.assertEquals('Jane', rows[1].values.get('Name'));
    }
    
    @isTest
    static void testCSVWithMissingValues() {
        String csvContent = 'Name,Email,Phone\n';
        csvContent += 'John,john@example.com,\n'; // Missing phone
        csvContent += 'Jane,,555-1234\n'; // Missing email
        
        List<CSVParser.CSVRow> rows = CSVParser.parse(csvContent);
        
        System.assertEquals(2, rows.size());
        
        // Check first row with missing phone
        System.assertEquals('John', rows[0].values.get('Name'));
        System.assertEquals('john@example.com', rows[0].values.get('Email'));
        System.assertEquals('', rows[0].values.get('Phone'));
        
        // Check second row with missing email
        System.assertEquals('Jane', rows[1].values.get('Name'));
        System.assertEquals('', rows[1].values.get('Email'));
        System.assertEquals('555-1234', rows[1].values.get('Phone'));
    }
    
    @isTest
    static void testLargeCSV() {
        String csvContent = 'Id,Name,Value\n';
        
        // Create 1000 rows
        for (Integer i = 0; i < 1000; i++) {
            csvContent += i + ',Name' + i + ',Value' + i + '\n';
        }
        
        List<CSVParser.CSVRow> rows = CSVParser.parse(csvContent);
        
        System.assertEquals(1000, rows.size(), 'Should handle 1000 rows');
        
        // Spot check some rows
        System.assertEquals('0', rows[0].values.get('Id'));
        System.assertEquals('Name499', rows[499].values.get('Name'));
        System.assertEquals('Value999', rows[999].values.get('Value'));
    }
}