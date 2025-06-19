/**
 * Utility class for parsing CSV data
 */
public class CSVParser {
    
    /**
     * Parse CSV string into a list of maps
     * @param csvString The CSV content as a string
     * @return List of maps where each map represents a row with column headers as keys
     */
    public static List<Map<String, String>> parseCSV(String csvString) {
        List<Map<String, String>> result = new List<Map<String, String>>();
        
        if (String.isBlank(csvString)) {
            return result;
        }
        
        // Split by line breaks
        List<String> lines = csvString.split('\n');
        if (lines.isEmpty()) {
            return result;
        }
        
        // Get headers from first line
        List<String> headers = parseCSVLine(lines[0]);
        
        // Parse each data row
        for (Integer i = 1; i < lines.size(); i++) {
            String line = lines[i].trim();
            if (String.isNotBlank(line)) {
                List<String> values = parseCSVLine(line);
                Map<String, String> rowMap = new Map<String, String>();
                
                // Map values to headers
                for (Integer j = 0; j < headers.size(); j++) {
                    String value = j < values.size() ? values[j] : '';
                    rowMap.put(headers[j], value);
                }
                
                result.add(rowMap);
            }
        }
        
        return result;
    }
    
    /**
     * Parse a single CSV line handling quotes and commas
     * @param line The CSV line to parse
     * @return List of values
     */
    private static List<String> parseCSVLine(String line) {
        List<String> values = new List<String>();
        String currentValue = '';
        Boolean insideQuotes = false;
        
        for (Integer i = 0; i < line.length(); i++) {
            String currentChar = line.substring(i, i + 1);
            
            if (currentChar == '"') {
                // Handle double quotes
                if (insideQuotes && i + 1 < line.length() && line.substring(i + 1, i + 2) == '"') {
                    currentValue += '"';
                    i++; // Skip next quote
                } else {
                    insideQuotes = !insideQuotes;
                }
            } else if (currentChar == ',' && !insideQuotes) {
                // End of value
                values.add(currentValue.trim());
                currentValue = '';
            } else {
                currentValue += currentChar;
            }
        }
        
        // Add last value
        values.add(currentValue.trim());
        
        return values;
    }
} 