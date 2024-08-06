import ArgumentParser
import Foundation

protocol RunCommand: AsyncParsableCommand {
    func run(with options: Run.Options) async throws
    func validate() throws
}

extension RunCommand {
    func run(with options: Run.Options) async throws {
        do {
            try await MutationTestHandler(options: options).run()
        } catch {
			
			if let error = error as? MuterError,
			   error == MuterError.noMutationPointsDiscovered {
				print("No mutation point discovered")
				Foundation.exit(0)
			}
			
            print(
                """
                ⚠️ ⚠️ ⚠️ ⚠️ ⚠️  Muter has encountered an error  ⚠️ ⚠️ ⚠️ ⚠️ ⚠️
                \(error)


                ⚠️ ⚠️ ⚠️ ⚠️ ⚠️  See the Muter error log above this line  ⚠️ ⚠️ ⚠️ ⚠️ ⚠️

                If you think this is a bug, or want help figuring out what could be happening, please open an issue at
                https://github.com/muter-mutation-testing/muter/issues
                """
            )

            Foundation.exit(-1)
        }
    }

    func validate() throws {}
}
