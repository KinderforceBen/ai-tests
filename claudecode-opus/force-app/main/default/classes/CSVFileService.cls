public with sharing class CSVFileService implements ICSVFileService {
    
    public String fetchCSVContent(String endpoint) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setTimeout(120000); // 2 minutes timeout for large files
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() != 200) {
            throw new CSVFileServiceException('Failed to fetch CSV file. Status: ' + res.getStatusCode() + ' - ' + res.getStatus());
        }
        
        return res.getBody();
    }
    
    public class CSVFileServiceException extends Exception {}
}