import XCTest
import TestingExtensions

@testable import muterCore

final class JsonReporterTests: ReporterTestCase {
    func test_report() throws {
        let json = JsonReporter()
            .report(
                from: .make(mutations: outcomes)
            )

        let data = try XCTUnwrap(json.data(using: .utf8))
        let actualReport = try XCTUnwrap(try JSONDecoder().decode(MuterTestReport.self, from: data))

        // The reports differ and can't be equated easily as we do not persist the path of a file report.
        // Basically, when we deserialize it, it's missing a field (`path`).
        XCTAssertEqual(actualReport.totalAppliedMutationOperators, 1)
        XCTAssertEqual(actualReport.fileReports.first?.fileName, "file3.swift")
    }
}