import Foundation

struct CreateMuterTestPlan: MutationStep {
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter
    @Dependency(\.writeFile)
    private var writeFile: WriteFile

    func run(with state: AnyMutationTestState) async throws -> [MutationTestState.Change] {
		
		let startDuration = Date()
		
        let testPlan = MuterTestPlan(
            mutatedProjectPath: state.mutatedProjectDirectoryURL.path,
            projectCoverage: state.projectCoverage.percent,
            mappings: state.mutationMapping
        )

        let jsonData = try JSONEncoder().encode(testPlan)

        guard let json = String(data: jsonData, encoding: .utf8) else {
            throw MuterError.literal(reason: "Could not convert test plan data to string.")
        }

        let jsonUrl = state.projectDirectoryURL
            .appendingPathComponent("muter-mappings")
            .appendingPathExtension("json")

        try writeFile(
            json,
            jsonUrl.path
        )

        notificationCenter.post(
            name: .testPlanFileCreated,
            object: jsonUrl.path
        )

		let endDuration = Double((Date().timeIntervalSince(startDuration) * 1000).rounded())
		print("Muter Duration: Create Muter Test Plan \(endDuration)")
		
        return []
    }
}
