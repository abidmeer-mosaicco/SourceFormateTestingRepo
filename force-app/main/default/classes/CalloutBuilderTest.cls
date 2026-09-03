/**
 * @description Test class for CalloutBuilder
 * @author Raphael Ferreira de Holanda Soares
 */
@isTest
private class CalloutBuilderTest {

	/**
	 * @description Mock HTTP callout class for testing
	 */
	private class MockHttpResponse implements HttpCalloutMock {
		private Integer statusCode;
		private String body;

		public MockHttpResponse(Integer statusCode, String body) {
			this.statusCode = statusCode;
			this.body = body;
		}

		public HttpResponse respond(HttpRequest req) {
			HttpResponse res = new HttpResponse();
			res.setStatusCode(this.statusCode);
			res.setBody(this.body);
			res.setHeader('Content-Type', 'application/json');
			return res;
		}
	}

	@isTest
	static void testBasicGetRequest() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{"status":"success"}'));

		Test.startTest();
		CalloutBuilder builder = new CalloutBuilder();
		HttpResponse response = builder
			.withMethod('GET')
			.withEndpoint('https://api.example.com/test')
			.execute();
		Test.stopTest();

		builder.isSuccess();
		builder.getResponse();
		builder.getStatusCode();
	}

	@isTest
	static void testPostWithJsonBody() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(201, '{"id":"123"}'));

		Test.startTest();
		Map<String, Object> requestBody = new Map<String, Object>{
			'name' => 'Test',
			'value' => 100
		};

		CalloutBuilder builder = new CalloutBuilder();
		HttpResponse response = builder
			.withMethod('POST')
			.withEndpoint('https://api.example.com/create')
			.withJsonBody(requestBody)
			.execute();
		Test.stopTest();

		builder.getBodyAsObject();
		builder.getBodyAsMap();
	}

	@isTest
	static void testPutWithHeaders() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{"updated":true}'));

		Test.startTest();
		Map<String, String> headers = new Map<String, String>{
			'X-Custom-Header' => 'CustomValue',
			'X-Request-ID' => '12345'
		};

		CalloutBuilder builder = new CalloutBuilder();
		HttpResponse response = builder
			.withMethod('PUT')
			.withEndpoint('https://api.example.com/update')
			.withHeaders(headers)
			.withHeader('X-Another-Header', 'AnotherValue')
			.withBody('{"test":"data"}')
			.execute();
		Test.stopTest();

		builder.getRequest();
	}

	@isTest
	static void testDeleteRequest() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(204, ''));

		Test.startTest();
		CalloutBuilder builder = new CalloutBuilder();
		HttpResponse response = builder
			.withMethod('DELETE')
			.withEndpoint('https://api.example.com/delete/123')
			.withTimeout(30000)
			.execute();
		Test.stopTest();
	}

	@isTest
	static void testBearerTokenAuth() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{"data":"secure"}'));

		Test.startTest();
		CalloutBuilder builder = new CalloutBuilder();
		HttpResponse response = builder
			.withMethod('GET')
			.withEndpoint('https://api.example.com/secure')
			.withBearerToken('test-token-12345')
			.execute();
		Test.stopTest();
	}

	@isTest
	static void testBasicAuth() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{"authenticated":true}'));

		Test.startTest();
		CalloutBuilder builder = new CalloutBuilder();
		HttpResponse response = builder
			.withMethod('GET')
			.withEndpoint('https://api.example.com/auth')
			.withBasicAuth('username', 'password')
			.execute();
		Test.stopTest();
	}

	@isTest
	static void testCustomAuth() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{"custom":"auth"}'));

		Test.startTest();
		CalloutBuilder builder = new CalloutBuilder();
		HttpResponse response = builder
			.withMethod('GET')
			.withEndpoint('https://api.example.com/custom')
			.withCustomAuth('Custom auth-token-here')
			.execute();
		Test.stopTest();
	}

	@isTest
	static void testApiKeyAuth() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{"apikey":"valid"}'));

		Test.startTest();
		CalloutBuilder builder = new CalloutBuilder();
		HttpResponse response = builder
			.withMethod('GET')
			.withEndpoint('https://api.example.com/api')
			.withApiKey('api-key-123456', 'X-API-Key')
			.execute();
		Test.stopTest();
	}

	@isTest
	static void testFormBody() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{"form":"submitted"}'));

		Test.startTest();
		Map<String, String> formData = new Map<String, String>{
			'username' => 'testuser',
			'password' => 'testpass',
			'grant_type' => 'password'
		};

		CalloutBuilder builder = new CalloutBuilder();
		HttpResponse response = builder
			.withMethod('POST')
			.withEndpoint('https://api.example.com/token')
			.withFormBody(formData)
			.execute();
		Test.stopTest();
	}

	@isTest
	static void testExecuteAndReturnBuilder() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{"chained":true}'));

		Test.startTest();
		CalloutBuilder builder = new CalloutBuilder()
			.withMethod('GET')
			.withEndpoint('https://api.example.com/chain')
			.executeAndReturnBuilder();
		Test.stopTest();

		builder.isSuccess();
		builder.getStatusCode();
	}

	@isTest
	static void testSuccessStatusCodes() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(201, '{"created":true}'));

		Test.startTest();
		CalloutBuilder builder = new CalloutBuilder();
		HttpResponse response = builder
			.withMethod('POST')
			.withEndpoint('https://api.example.com/success')
			.execute();
		Test.stopTest();

		builder.isSuccess();
	}

	@isTest
	static void testErrorStatusCodes() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(404, '{"error":"not found"}'));

		Test.startTest();
		CalloutBuilder builder = new CalloutBuilder();
		HttpResponse response = builder
			.withMethod('GET')
			.withEndpoint('https://api.example.com/notfound')
			.execute();
		Test.stopTest();

		builder.isSuccess();
	}

	@isTest
	static void testBuildWithoutExecute() {
		Test.startTest();
		CalloutBuilder builder = new CalloutBuilder();
		HttpRequest request = builder
			.withMethod('POST')
			.withEndpoint('https://api.example.com/build')
			.withHeader('Content-Type', 'application/json')
			.withBody('{"build":"test"}')
			.build();
		Test.stopTest();
	}

	@isTest
	static void testValidationMissingMethod() {
		Test.startTest();
		try {
			CalloutBuilder builder = new CalloutBuilder();
			HttpRequest request = builder
				.withEndpoint('https://api.example.com/error')
				.build();
		} catch (CalloutBuilder.CalloutBuilderException e) {
			// Expected exception
		}
		Test.stopTest();
	}

	@isTest
	static void testValidationMissingEndpoint() {
		Test.startTest();
		try {
			CalloutBuilder builder = new CalloutBuilder();
			HttpRequest request = builder
				.withMethod('GET')
				.build();
		} catch (CalloutBuilder.CalloutBuilderException e) {
			// Expected exception
		}
		Test.stopTest();
	}

	@isTest
	static void testGetBodyAsObjectWithNullResponse() {
		Test.startTest();
		CalloutBuilder builder = new CalloutBuilder();
		Object result = builder.getBodyAsObject();
		Test.stopTest();
	}

	@isTest
	static void testGetBodyAsMapWithNullResponse() {
		Test.startTest();
		CalloutBuilder builder = new CalloutBuilder();
		Map<String, Object> result = builder.getBodyAsMap();
		Test.stopTest();
	}

	@isTest
	static void testGetBodyAsTypeWithNullResponse() {
		Test.startTest();
		CalloutBuilder builder = new CalloutBuilder();
		Object result = builder.getBodyAsType(Map<String, Object>.class);
		Test.stopTest();
	}

	@isTest
	static void testGetStatusCodeWithNullResponse() {
		Test.startTest();
		CalloutBuilder builder = new CalloutBuilder();
		Integer statusCode = builder.getStatusCode();
		Test.stopTest();
	}

	@isTest
	static void testIsSuccessWithNullResponse() {
		Test.startTest();
		CalloutBuilder builder = new CalloutBuilder();
		Boolean success = builder.isSuccess();
		Test.stopTest();
	}

	@isTest
	static void testGetException() {
		Test.startTest();
		CalloutBuilder builder = new CalloutBuilder();
		Exception ex = builder.getException();
		Test.stopTest();
	}

	@isTest
	static void testWithHeadersNull() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{"test":true}'));

		Test.startTest();
		CalloutBuilder builder = new CalloutBuilder();
		HttpResponse response = builder
			.withMethod('GET')
			.withEndpoint('https://api.example.com/nullheaders')
			.withHeaders(null)
			.execute();
		Test.stopTest();
	}

	@isTest
	static void testGetBodyAsObjectEmptyBody() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, ''));

		Test.startTest();
		CalloutBuilder builder = new CalloutBuilder();
		HttpResponse response = builder
			.withMethod('GET')
			.withEndpoint('https://api.example.com/empty')
			.execute();

		Object result = builder.getBodyAsObject();
		Test.stopTest();
	}

	@isTest
	static void testGetBodyAsMapEmptyBody() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, ''));

		Test.startTest();
		CalloutBuilder builder = new CalloutBuilder();
		HttpResponse response = builder
			.withMethod('GET')
			.withEndpoint('https://api.example.com/empty')
			.execute();

		Map<String, Object> result = builder.getBodyAsMap();
		Test.stopTest();
	}

	@isTest
	static void testGetBodyAsTypeEmptyBody() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, ''));

		Test.startTest();
		CalloutBuilder builder = new CalloutBuilder();
		HttpResponse response = builder
			.withMethod('GET')
			.withEndpoint('https://api.example.com/empty')
			.execute();

		Object result = builder.getBodyAsType(Map<String, Object>.class);
		Test.stopTest();
	}

	@isTest
	static void testComplexChainedCallout() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{"complex":"response","data":{"nested":"value"}}'));

		Test.startTest();
		CalloutBuilder builder = new CalloutBuilder();
		HttpResponse response = builder
			.withMethod('POST')
			.withEndpoint('https://api.example.com/complex')
			.withTimeout(60000)
			.withHeader('Accept', 'application/json')
			.withHeader('User-Agent', 'CalloutBuilder/1.0')
			.withBearerToken('complex-token')
			.withJsonBody(new Map<String, Object>{
				'param1' => 'value1',
				'param2' => 123,
				'param3' => true
			})
			.execute();
		Test.stopTest();

		builder.getResponse();
		builder.getRequest();
		builder.isSuccess();
		builder.getStatusCode();
		builder.getBodyAsMap();
		builder.getBodyAsObject();
	}

	@isTest
	static void testServerError() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(500, '{"error":"internal server error"}'));

		Test.startTest();
		CalloutBuilder builder = new CalloutBuilder();
		HttpResponse response = builder
			.withMethod('GET')
			.withEndpoint('https://api.example.com/error')
			.execute();
		Test.stopTest();

		builder.isSuccess();
	}

	@isTest
	static void testMultipleHeaders() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{"headers":"received"}'));

		Test.startTest();
		Map<String, String> headers1 = new Map<String, String>{
			'Header1' => 'Value1',
			'Header2' => 'Value2'
		};

		Map<String, String> headers2 = new Map<String, String>{
			'Header3' => 'Value3',
			'Header4' => 'Value4'
		};

		CalloutBuilder builder = new CalloutBuilder();
		HttpResponse response = builder
			.withMethod('GET')
			.withEndpoint('https://api.example.com/headers')
			.withHeaders(headers1)
			.withHeaders(headers2)
			.withHeader('Header5', 'Value5')
			.execute();
		Test.stopTest();
	}
}