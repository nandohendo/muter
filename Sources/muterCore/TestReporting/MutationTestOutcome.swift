import Foundation

struct MutationTestOutcome {
    let mutations: [Mutation]
    let coverage: Coverage
    let testDuration: TimeInterval
    let newVersion: String
	let totalFoundedMutation: Int

    init(
        mutations: [Mutation] = [],
        coverage: Coverage = .null,
        testDuration: TimeInterval = 0,
        newVersion: String = "",
		totalFoundedMutation: Int = 0
    ) {
        self.mutations = mutations
        self.coverage = coverage
        self.testDuration = testDuration
        self.newVersion = newVersion
		self.totalFoundedMutation = totalFoundedMutation
    }
}

extension MutationTestOutcome: Equatable {}

extension MutationTestOutcome {
    struct Mutation: Equatable {
        let testSuiteOutcome: TestSuiteOutcome
        let point: MutationPoint
        let snapshot: MutationOperator.Snapshot
        let originalProjectPath: String

        init(
            testSuiteOutcome: TestSuiteOutcome,
            mutationPoint: MutationPoint,
            mutationSnapshot: MutationOperator.Snapshot,
            originalProjectDirectoryUrl: URL,
            mutatedProjectDirectoryURL: URL
        ) {
            self.testSuiteOutcome = testSuiteOutcome
            point = mutationPoint
            snapshot = mutationSnapshot

            let splitTempFilePath = mutationPoint.filePath.split(separator: "/")
            let tempProjectDirectoryName = mutatedProjectDirectoryURL.lastPathComponent
            let numberOfDirectoriesToDrop = splitTempFilePath.map(String.init)
                .firstIndex(of: tempProjectDirectoryName) ?? 0
            let pathSuffix = splitTempFilePath.dropFirst(numberOfDirectoriesToDrop + 1).joined(separator: "/")

            originalProjectPath = originalProjectDirectoryUrl
                .appendingPathComponent(pathSuffix, isDirectory: true)
                .path
        }
    }
}
