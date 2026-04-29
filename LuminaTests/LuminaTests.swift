@testable import Lumina
import XCTest

final class LuminaTests: XCTestCase {
    private static let sampleBirthData: BirthData = {
        let formatter = ISO8601DateFormatter()
        let birthDate = formatter.date(from: "1990-06-15T00:00:00Z") ?? Date()
        let birthTime = formatter.date(from: "1990-06-15T12:30:00Z") ?? Date()
        return BirthData(
            birthDate: birthDate,
            birthTime: birthTime,
            placeName: "Stockholm",
            latitude: 59.3293,
            longitude: 18.0686,
            timeZoneIdentifier: "Europe/Stockholm"
        )
    }()

    func testSpacingTokensAreOnEightPointGrid() {
        XCTAssertEqual(LuminaSpacing.xs, 4)
        XCTAssertEqual(LuminaSpacing.sm, 8)
        XCTAssertEqual(LuminaSpacing.md, 16)
        XCTAssertEqual(LuminaSpacing.lg, 24)
        XCTAssertEqual(LuminaSpacing.xl, 32)
        XCTAssertEqual(LuminaSpacing.xxl, 48)
    }

    func testHouseSystemDefaultIncludesPlacidus() {
        XCTAssertTrue(HouseSystem.allCases.contains(.placidus))
    }

    func testEphemerisServiceMissingConfigurationThrows() async {
        let service = EphemerisService(infoPlist: [:])
        do {
            _ = try await service.chart(for: Self.sampleBirthData)
            XCTFail("expected ServiceError.missingConfiguration")
        } catch EphemerisService.ServiceError.missingConfiguration {
            // expected
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testBirthDataAlwaysEmitsBirthTimeKey() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let withTime = try encoder.encode(Self.sampleBirthData)
        XCTAssertTrue(stringify(withTime).contains("\"birthTime\":\"1990-06-15T12:30:00Z\""))

        let withoutTime = try encoder.encode(BirthData(
            birthDate: Self.sampleBirthData.birthDate,
            birthTime: nil,
            placeName: "Stockholm",
            latitude: 59.3293,
            longitude: 18.0686,
            timeZoneIdentifier: "Europe/Stockholm"
        ))
        XCTAssertTrue(stringify(withoutTime).contains("\"birthTime\":null"))
    }

    func testEphemerisServiceRoundTripDecodesNatalChart() async throws {
        let chartJSON = Data("""
        {
          "calculatedAt": "2026-04-29T15:40:12.600Z",
          "houseSystem": "placidus",
          "planets": [
            { "planet": "Sun",     "longitude": 84.15,  "latitude": 0.0,   "isRetrograde": false },
            { "planet": "Moon",    "longitude": 345.64, "latitude": 3.15,  "isRetrograde": false },
            { "planet": "Mercury", "longitude": 65.73,  "latitude": -1.66, "isRetrograde": false }
          ]
        }
        """.utf8)

        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.absoluteString, "https://eph.test.lumina/chart")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Lumina-Secret"), "test-secret")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            let body = request.bodyData() ?? Data()
            let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            XCTAssertEqual(json?["placeName"] as? String, "Stockholm")
            XCTAssertNotNil(json?["birthTime"], "birthTime key must always be present")
            let response = try makeHTTPResponse(
                url: request.url ?? URL(fileURLWithPath: "/"),
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
            return (response, chartJSON)
        }

        let service = EphemerisService(
            session: MockURLProtocol.session(),
            baseURL: URL(string: "https://eph.test.lumina") ?? URL(fileURLWithPath: "/"),
            apiSecret: "test-secret"
        )
        let chart = try await service.chart(for: Self.sampleBirthData)

        XCTAssertEqual(chart.houseSystem, .placidus)
        XCTAssertEqual(chart.planets.count, 3)
        XCTAssertEqual(chart.planets.first?.planet, "Sun")
        XCTAssertEqual(chart.planets.first?.longitude ?? 0, 84.15, accuracy: 0.001)
    }

    func testEphemerisServiceSurfacesHTTPErrors() async {
        MockURLProtocol.handler = { request in
            let response = try makeHTTPResponse(
                url: request.url ?? URL(fileURLWithPath: "/"),
                statusCode: 401
            )
            return (response, Data("unauthorized".utf8))
        }
        let service = EphemerisService(
            session: MockURLProtocol.session(),
            baseURL: URL(string: "https://eph.test.lumina") ?? URL(fileURLWithPath: "/"),
            apiSecret: "wrong"
        )
        do {
            _ = try await service.chart(for: Self.sampleBirthData)
            XCTFail("expected ServiceError.httpError")
        } catch EphemerisService.ServiceError.httpError(let status, let body) {
            XCTAssertEqual(status, 401)
            XCTAssertEqual(body, "unauthorized")
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    private func stringify(_ data: Data) -> String {
        String(data: data, encoding: .utf8) ?? ""
    }
}

// MARK: - URL protocol mock

class MockURLProtocol: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    nonisolated(unsafe) static var handler: Handler?

    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private enum MockResponseError: Error {
    case couldNotConstructResponse
}

private func makeHTTPResponse(
    url: URL,
    statusCode: Int,
    headers: [String: String]? = nil
) throws -> HTTPURLResponse {
    guard let response = HTTPURLResponse(
        url: url,
        statusCode: statusCode,
        httpVersion: "HTTP/1.1",
        headerFields: headers
    ) else {
        throw MockResponseError.couldNotConstructResponse
    }
    return response
}

extension URLRequest {
    /// `httpBody` is nil when the request was created via a stream — the
    /// MockURLProtocol gets streamed bodies, so reach into `httpBodyStream`.
    func bodyData() -> Data? {
        if let body = httpBody { return body }
        guard let stream = httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 4_096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }
}
