@isTest
public class MockCSVFileService implements ICSVFileService {
    
    private String mockResponse;
    private Boolean shouldThrowException;
    
    public MockCSVFileService(String mockResponse) {
        this.mockResponse = mockResponse;
        this.shouldThrowException = false;
    }
    
    public MockCSVFileService(Boolean shouldThrowException) {
        this.shouldThrowException = shouldThrowException;
    }
    
    public String fetchCSVContent(String endpoint) {
        if (shouldThrowException) {
            throw new CSVFileService.CSVFileServiceException('Mock exception: Failed to fetch CSV');
        }
        return mockResponse;
    }
}