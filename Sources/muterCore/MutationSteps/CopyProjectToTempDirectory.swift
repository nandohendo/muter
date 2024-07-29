import Foundation

class CopyProjectToTempDirectory: MutationStep {
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter

    func run(
        with state: AnyMutationTestState
    ) async throws -> [MutationTestState.Change] {
        do {
			let startDuration = Date()
            notificationCenter.post(
                name: .projectCopyStarted,
                object: nil
            )

            try fileManager.copyItem(
                atPath: state.projectDirectoryURL.path,
                toPath: state.mutatedProjectDirectoryURL.path
            )

            notificationCenter.post(
                name: .projectCopyFinished,
                object: state.mutatedProjectDirectoryURL.path
            )
			
			let endDuration = Double((Date().timeIntervalSince(startDuration) * 1000).rounded())
			print("Muter Duration: Copy Project To Temp Directory \(endDuration)")
			
            return []
        } catch {
            throw MuterError.projectCopyFailed(
                reason: error.localizedDescription
            )
        }
    }
}
