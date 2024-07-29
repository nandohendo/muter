import Foundation

struct PreviousRunCleanUp: MutationStep {
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager

    func run(
        with state: AnyMutationTestState
    ) async throws -> [MutationTestState.Change] {
		let startDuration = Date()
        guard fileManager.fileExists(
            atPath: state.mutatedProjectDirectoryURL.path
        )
        else {
            return []
        }

        do {
            try fileManager.removeItem(
                atPath: state.mutatedProjectDirectoryURL.path
            )
			let endDuration = Double((Date().timeIntervalSince(startDuration) * 1000).rounded())
			print("Muter Duration: Previous Run Clean Up \(endDuration)")
            return []
        } catch {
            throw MuterError.removeProjectFromPreviousRunFailed(
                reason: error.localizedDescription
            )
        }
    }
}
