/**
 * Interface for HTTP service to enable mocking in unit tests
 */
public interface IHttpService {
    HttpResponse send(HttpRequest request);
} 