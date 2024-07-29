import ArgumentParser
import Foundation

struct RunApplySchemata: RunCommand {
	public static let configuration = CommandConfiguration(
		commandName: "run-apply-schemata",
		abstract: "Perform apply schemata step"
	)
	
	@Option(help: "Only mutate a given list of source code files.")
	var filesToMutate: [String] = []
	
	@Option(help: "Only include selected unit test")
	var unitTestFile: [String] = []
	
	@OptionGroup var options: RunArguments
	
	init() {}

	func run() async throws {
		let options = Run.Options(
			filesToMutate: filesToMutate,
			unitTestFile: unitTestFile,
			skipCoverage: options.skipCoverage,
			skipUpdateCheck: options.skipUpdateCheck,
			configurationURL: options.configurationURL,
			stepCommand: .runApplySchemata
		)
		
		try await run(with: options)
	}
}
