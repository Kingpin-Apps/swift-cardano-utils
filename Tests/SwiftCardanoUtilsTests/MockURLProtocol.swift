import Foundation

/// A `URLProtocol` subclass that intercepts URL requests and returns preset responses.
/// Register it via `MockURLProtocol.makeSession()` and pass the session to methods under test.
final class MockURLProtocol: URLProtocol {
    /// Keyed by URL string → `Result<Data, Error>`.
    nonisolated(unsafe) static var responses: [String: Result<Data, Error>] = [:]

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let key = request.url?.absoluteString ?? ""
        switch MockURLProtocol.responses[key] {
        case .success(let data):
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        case nil:
            client?.urlProtocol(self, didFailWithError: URLError(.fileDoesNotExist))
        }
    }

    override func stopLoading() {}

    /// Creates a `URLSession` that routes all requests through `MockURLProtocol`.
    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}
