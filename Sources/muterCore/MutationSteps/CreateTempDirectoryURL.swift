import Foundation

struct CreateMutatedProjectDirectoryURL: MutationStep {
    func run(
        with state: AnyMutationTestState
    ) async throws -> [MutationTestState.Change] {
		let startDuration = Date()
        let destinationPath = destinationPath(
            with: state.projectDirectoryURL
        )
		
		let endDuration = Double((Date().timeIntervalSince(startDuration) * 1000).rounded())
		print("Muter Duration: Create Mutated Project Directory URL \(endDuration)")
		
        return [
            .tempDirectoryUrlCreated(URL(fileURLWithPath: destinationPath))
        ]
    }

    private func destinationPath(
        with projectDirectoryURL: URL
    ) -> String {
        let lastComponent = projectDirectoryURL.lastPathComponent
        let modifiedDirectory = projectDirectoryURL.deletingLastPathComponent()
        let destination = modifiedDirectory.appendingPathComponent(lastComponent + "_mutated")
        return destination.path
    }
}
