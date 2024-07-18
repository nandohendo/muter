import Foundation
import SwiftSyntax

struct PerformMutationTesting: MutationStep {
    @Dependency(\.ioDelegate)
    private var ioDelegate: MutationTestingIODelegate
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager
    @Dependency(\.now)
    private var now: Now

    private let buildErrorsThreshold: Int = 5

    func run(
        with state: AnyMutationTestState
    ) async throws -> [MutationTestState.Change] {
        fileManager.changeCurrentDirectoryPath(state.mutatedProjectDirectoryURL.path)

        let (mutationOutcome, testDuration) = try await benchmarkMutationTesting {
            try await performMutationTesting(using: state)
        }

        let mutationTestOutcome = MutationTestOutcome(
            mutations: mutationOutcome,
            coverage: state.projectCoverage,
            testDuration: testDuration,
            newVersion: state.newVersion
        )

        notificationCenter.post(
            name: .mutationTestingFinished,
            object: mutationTestOutcome
        )

        return [.mutationTestOutcomeGenerated(mutationTestOutcome)]
    }

    private func benchmarkMutationTesting<T>(
        _ work: () async throws -> T
    ) async throws -> (result: T, duration: TimeInterval) {
        let initialTime = now()
        let result = try await work()
        let duration = DateInterval(
            start: initialTime,
            end: now()
        ).duration

        return (result, duration)
    }
}

private extension PerformMutationTesting {
    func performMutationTesting(
        using state: AnyMutationTestState
    ) async throws -> [MutationTestOutcome.Mutation] {
        notificationCenter.post(name: .mutationTestingStarted, object: nil)

        let initialTime = Date()
        let (testSuiteOutcome, testLog) = ioDelegate.runTestSuite(
            withSchemata: .null,
            using: state.muterConfiguration,
            savingResultsIntoFileNamed: "baseline run"
        )

        let timeAfterRunningTestSuite = Date()
        let timePerBuildTestCycle = DateInterval(
            start: initialTime,
            end: timeAfterRunningTestSuite
        ).duration

        guard testSuiteOutcome == .passed else {
            throw MuterError.mutationTestingAborted(
                reason: .baselineTestFailed(log: testLog)
            )
        }

        let mutationLog = MutationTestLog(
            mutationPoint: .none,
            testLog: testLog,
            timePerBuildTestCycle: timePerBuildTestCycle,
            remainingMutationPointsCount: state.mutationPoints.count
        )

        notificationCenter.post(
            name: .newTestLogAvailable,
            object: mutationLog
        )

        return try await testMutation(using: state)
    }

    func testMutation(using state: AnyMutationTestState) async throws -> [MutationTestOutcome.Mutation] {
        var outcomes: [MutationTestOutcome.Mutation] = []
        outcomes.reserveCapacity(state.mutationPoints.count)
        var buildErrors = 0

        for mutationMap in state.mutationMapping {
            for mutationSchema in mutationMap.mutationSchemata {

				guard let modifiedXCTestRun = try parseXCTestRunAt(state.projectXCTestRun, unitTestFiles: state.unitTestFiles) else {
					throw MuterError.literal(reason: "Could not parse modified xctestrun at path")
				}
				
				print("Modify xctestrun")
                try? ioDelegate.switchOn(
                    schemata: mutationSchema,
                    for: modifiedXCTestRun,
                    at: state.mutatedProjectDirectoryURL
                )

                let (testSuiteOutcome, testLog) = ioDelegate.runTestSuite(
                    withSchemata: mutationSchema,
                    using: state.muterConfiguration,
                    savingResultsIntoFileNamed: logFileName(
                        for: mutationMap.fileName,
                        schemata: mutationSchema
                    )
                )

                let mutationPoint = MutationPoint(
                    mutationOperatorId: mutationSchema.mutationOperatorId,
                    filePath: mutationSchema.filePath,
                    position: mutationSchema.position
                )

                let outcome = MutationTestOutcome.Mutation(
                    testSuiteOutcome: testSuiteOutcome,
                    mutationPoint: mutationPoint,
                    mutationSnapshot: mutationSchema.snapshot,
                    originalProjectDirectoryUrl: state.projectDirectoryURL,
                    mutatedProjectDirectoryURL: state.mutatedProjectDirectoryURL
                )

                outcomes.append(outcome)

                let mutationLog = MutationTestLog(
                    mutationPoint: mutationPoint,
                    testLog: testLog,
                    timePerBuildTestCycle: .none,
                    remainingMutationPointsCount: .none
                )

                notificationCenter.post(
                    name: .newMutationTestOutcomeAvailable,
                    object: outcome
                )

                notificationCenter.post(
                    name: .newTestLogAvailable,
                    object: mutationLog
                )

                buildErrors = testSuiteOutcome == .buildError ? (buildErrors + 1) : 0
                if buildErrors >= buildErrorsThreshold {
                    throw MuterError.mutationTestingAborted(reason: .tooManyBuildErrors)
                }
            }
        }

        return outcomes
    }
	
	private func parseXCTestRunAt(_ xcTestRun: XCTestRun, unitTestFiles: [String]) throws -> XCTestRun? {
//		let xcTestRunPath = try findMostRecentXCTestRunAtURL(url)
//		guard let contents = fileManager.contents(atPath: xcTestRunPath),
//			  let stringContents = String(data: contents, encoding: .utf8)
//		else {
//			throw MuterError.literal(reason: "Could not parse xctestrun at path: \(xcTestRunPath)")
//		}
//		
//		
//
//		guard let replaced = stringContents.replacingOccurrences(
//			of: "__TESTROOT__/",
//			with: "__TESTROOT__/Debug/"
//		).data(using: .utf8)
//		else {
//			throw MuterError.literal(reason: "Error error")
//		}
		
		var modifiedPlist = xcTestRun.plist
//		guard var plist = try xcTestRun.plist
//		else {
//			throw MuterError.literal(reason: "Could not parse xctestrun as plist at path: \(xcTestRunPath)")
//		}
		
		if var testConfiguration = modifiedPlist["TestConfigurations"] as? [[String: AnyHashable]],
		   var testTargets = (testConfiguration.first)?["TestTargets"] as? [[String: AnyHashable]],
		   var testTargetItem = testTargets.first {
			
			var onlyTestIdentifiers: [String] = []
			
			unitTestFiles.forEach { filePath in
				guard let getLastPath = filePath.split(separator: "/").last else {
					return
				}
				
				let filename = String(getLastPath).replacingOccurrences(of: ".swift", with: "")
				onlyTestIdentifiers.append(filename)
			}
			
			testTargetItem["OnlyTestIdentifiers"] = onlyTestIdentifiers
			testTargets[0] = testTargetItem
			testConfiguration[0]["TestTargets"] = testTargets
			modifiedPlist["TestConfigurations"] = testConfiguration
		}
		
		let data = try PropertyListSerialization.data(
			fromPropertyList: modifiedPlist,
			format: .xml,
			options: 0
		)

		return XCTestRun(modifiedPlist)
	}
	
	private func findMostRecentXCTestRunAtURL(_ url: URL) throws -> String {
		guard let xctestrun = try fileManager.contents(
			atPath: url.path,
			sortedByDate: .orderedDescending
		).first(where: { $0.hasSuffix(".xctestrun") })
		else {
			throw MuterError.literal(reason: "Could not find xctestrun file at path: \(url.path)")
		}

		return xctestrun
	}

    func logFileName(
        for fileName: FileName,
        schemata: MutationSchema
    ) -> String {
        "\(fileName)_\(schemata.mutationOperatorId.rawValue)_\(schemata.position).log"
    }
}
