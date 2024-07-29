import Foundation

struct ApplySchemata: MutationStep {
    @Dependency(\.writeFile)
    private var writeFile: WriteFile
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter

    func run(
        with state: AnyMutationTestState
    ) async throws -> [MutationTestState.Change] {
		let startDuration = Date()
        for mutationMap in state.mutationMapping {
            guard let sourceCode = state.sourceCodeByFilePath[mutationMap.filePath] else {
                // TODO: log?
                continue
            }

            let rewriter = MuterRewriter(mutationMap)

            let newFile = rewriter.visit(sourceCode)

            do {
                try writeFile(
                    newFile.description,
                    mutationMap.filePath
                )
            } catch {
                throw MuterError.literal(reason: error.localizedDescription)
            }
        }
		
		let endDuration = Double((Date().timeIntervalSince(startDuration) * 1000).rounded())
		print("Muter Duration: Apply Schemata \(endDuration)")
		
        return []
    }
}
