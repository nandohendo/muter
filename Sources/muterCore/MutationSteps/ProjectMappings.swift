import Foundation

struct ProjectMappings: MutationStep {
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter

    func run(with state: AnyMutationTestState) async throws -> [MutationTestState.Change] {
		let startDuration = Date()
        notificationCenter.post(
            name: .mutationsDiscoveryFinished,
            object: state.mutationMapping
        )
		
		let endDuration = Double((Date().timeIntervalSince(startDuration) * 1000).rounded())
		print("Muter Duration: Project Mappings \(endDuration)")
		
        return []
    }
}
