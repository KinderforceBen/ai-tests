public with sharing class CSVParser {
    
    public class CSVRow {
        public Integer rowNumber { get; set; }
        public Map<String, String> values { get; set; }
        
        public CSVRow(Integer rowNumber) {
            this.rowNumber = rowNumber;
            this.values = new Map<String, String>();
        }
    }
    
    public static List<CSVRow> parse(String csvContent) {
        List<CSVRow> rows = new List<CSVRow>();
        
        if (String.isBlank(csvContent)) {
            return rows;
        }
        
        List<String> lines = csvContent.split('\n');
        if (lines.isEmpty()) {
            return rows;
        }
        
        // Parse headers
        List<String> headers = parseCSVLine(lines[0]);
        
        // Parse data rows
        for (Integer i = 1; i < lines.size(); i++) {
            String line = lines[i].trim();
            if (String.isBlank(line)) {
                continue;
            }
            
            CSVRow row = new CSVRow(i + 1); // Row number starts at 1, header is row 1
            List<String> values = parseCSVLine(line);
            
            for (Integer j = 0; j < headers.size() && j < values.size(); j++) {
                row.values.put(headers[j].trim(), values[j].trim());
            }
            
            rows.add(row);
        }
        
        return rows;
    }
    
    private static List<String> parseCSVLine(String line) {
        List<String> values = new List<String>();
        
        if (String.isBlank(line)) {
            return values;
        }
        
        Boolean inQuotes = false;
        String currentValue = '';
        
        for (Integer i = 0; i < line.length(); i++) {
            String currentChar = line.substring(i, i + 1);
            
            if (currentChar == '"') {
                // Check if it's an escaped quote
                if (i + 1 < line.length() && line.substring(i + 1, i + 2) == '"') {
                    currentValue += '"';
                    i++; // Skip the next quote
                } else {
                    inQuotes = !inQuotes;
                }
            } else if (currentChar == ',' && !inQuotes) {
                values.add(currentValue);
                currentValue = '';
            } else {
                currentValue += currentChar;
            }
        }
        
        // Add the last value
        values.add(currentValue);
        
        return values;
    }
}