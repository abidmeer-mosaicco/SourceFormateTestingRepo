/**
 * @description : Builder class for constructing and executing HTTP callouts with fluent interface
 * @author      : Raphael Ferreira de Holanda Soares
 */
public with sharing class CalloutBuilder {
	private HttpRequest request;
	private HttpResponse response;
	private Exception calloutException;

	public CalloutBuilder() {
		this.request = new HttpRequest();
	}

	/**
	 * @description : Set HTTP method
	 */
	public CalloutBuilder withMethod(String method) {
		this.request.setMethod(method);
		return this;
	}

	/**
	 * @description : Set endpoint URL
	 */
	public CalloutBuilder withEndpoint(String endpoint) {
		this.request.setEndpoint(endpoint);
		return this;
	}

	/**
	 * @description : Set timeout in milliseconds
	 */
	public CalloutBuilder withTimeout(Integer timeout) {
		this.request.setTimeout(timeout);
		return this;
	}

	/**
	 * @description : Add single header
	 */
	public CalloutBuilder withHeader(String key, String value) {
		this.request.setHeader(key, value);
		return this;
	}

	/**
	 * @description : Add multiple headers
	 */
	public CalloutBuilder withHeaders(Map<String, String> headers) {
		if (headers != null) {
			for (String key : headers.keySet()) {
				this.request.setHeader(key, headers.get(key));
			}
		}
		return this;
	}

	/**
	 * @description : Set request body
	 */
	public CalloutBuilder withBody(String body) {
		this.request.setBody(body);
		return this;
	}

	/**
	 * @description : Set JSON body with automatic serialization
	 */
	public CalloutBuilder withJsonBody(Object bodyObject) {
		String jsonBody = JSON.serialize(bodyObject);
		return withHeader('Content-Type', 'application/json').withBody(jsonBody);
	}

	/**
	 * @description : Set form URL encoded body
	 */
	public CalloutBuilder withFormBody(Map<String, String> formData) {
		List<String> formParams = new List<String>();
		for (String key : formData.keySet()) {
			formParams.add(EncodingUtil.urlEncode(key, 'UTF-8') + '=' + EncodingUtil.urlEncode(formData.get(key), 'UTF-8'));
		}
		String formBody = String.join(formParams, '&');
		return withHeader('Content-Type', 'application/x-www-form-urlencoded').withBody(formBody);
	}

	/**
	 * @description : Set authorization header with Bearer token
	 */
	public CalloutBuilder withBearerToken(String token) {
		return withHeader('Authorization', 'Bearer ' + token);
	}

	/**
	 * @description : Set basic authentication
	 */
	public CalloutBuilder withBasicAuth(String username, String password) {
		String authHeader = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password));
		return withHeader('Authorization', authHeader);
	}

	/**
	 * @description : Set custom authorization header
	 */
	public CalloutBuilder withCustomAuth(String authHeader) {
		return withHeader('Authorization', authHeader);
	}

	/**
	 * @description : Set API key authentication
	 */
	public CalloutBuilder withApiKey(String apiKey, String headerName) {
		return withHeader(headerName, apiKey);
	}

	/**
	 * @description : Execute the callout and return HttpResponse
	 */
	public HttpResponse execute() {
		validate();

		try {
			Http http = new Http();
			this.response = http.send(this.request);
			return this.response;
		} catch (Exception ex) {
			this.calloutException = ex;
			throw new CalloutBuilderException('Callout execution failed: ' + ex.getMessage());
		}
	}

	/**
	 * @description : Execute and return the builder for method chaining
	 */
	public CalloutBuilder executeAndReturnBuilder() {
		execute();
		return this;
	}

	/**
	 * @description : Check if callout was successful (2xx status)
	 */
	public Boolean isSuccess() {
		return this.response != null && this.response.getStatusCode() >= 200 && this.response.getStatusCode() < 300;
	}

	/**
	 * @description : Get the HttpResponse
	 */
	public HttpResponse getResponse() {
		return this.response;
	}

	/**
	 * @description : Get the HttpRequest
	 */
	public HttpRequest getRequest() {
		return this.request;
	}

	/**
	 * @description : Get response body as deserialized object
	 */
	public Object getBodyAsObject() {
		if (this.response == null || String.isBlank(this.response.getBody())) {
			return null;
		}
		return JSON.deserializeUntyped(this.response.getBody());
	}

	/**
	 * @description : Get response body as typed object
	 */
	public Object getBodyAsType(Type targetType) {
		if (this.response == null || String.isBlank(this.response.getBody())) {
			return null;
		}
		return JSON.deserialize(this.response.getBody(), targetType);
	}

	/**
	 * @description : Get response body as map
	 */
	public Map<String, Object> getBodyAsMap() {
		if (this.response == null || String.isBlank(this.response.getBody())) {
			return new Map<String, Object>();
		}
		return (Map<String, Object>) JSON.deserializeUntyped(this.response.getBody());
	}

	/**
	 * @description : Get response status code
	 */
	public Integer getStatusCode() {
		return this.response != null ? this.response.getStatusCode() : null;
	}

	/**
	 * @description : Get exception if callout failed
	 */
	public Exception getException() {
		return this.calloutException;
	}

	/**
	 * @description : Build and return the HttpRequest without executing (for testing/mocking)
	 */
	public HttpRequest build() {
		validate();
		return this.request;
	}

	private void validate() {
		if (String.isBlank(this.request.getMethod())) {
			throw new CalloutBuilderException('HTTP method is required');
		}
		if (String.isBlank(this.request.getEndpoint())) {
			throw new CalloutBuilderException('Endpoint is required');
		}
	}

	public class CalloutBuilderException extends Exception {
	}
}