/**
 * Concrete implementation of IHttpService for production use
 */
public class HttpService implements IHttpService {
    public HttpResponse send(HttpRequest request) {
        Http http = new Http();
        return http.send(request);
    }
} 