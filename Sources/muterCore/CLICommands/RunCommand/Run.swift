import ArgumentParser
import Foundation

struct Run: RunCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Performs mutation testing for the Swift project contained within the current directory."
    )

    @Option(help: "Only mutate a given list of source code files.")
    var filesToMutate: [String] = []
	
	@Option(help: "Only include selected unit test")
	var unitTestFile: [String] = []
	
	@Option(help: "Limit of mutation to be tested")
	var mutationLimit: Int = 25
	
	@Option(help: "Option to enable mutation to run random or not")
	var randomizeTest: Bool = true
	
    @Option(
        parsing: .upToNextOption,
        help: "The list of mutant operators to be used: \(MutationOperator.Id.description)",
        transform: {
            guard let `operator` = MutationOperator.Id(rawValue: $0) else {
                throw MuterError.literal(reason: MutationOperator.Id.description)
            }

            return `operator`
        }
    )
	var operators: [MutationOperator.Id] = [.logicalOperator]

    @OptionGroup var options: RunArguments
    @OptionGroup var reportOptions: ReportArguments

    init() {}

    func run() async throws {
        let mutationOperatorsList = !operators.isEmpty
            ? operators
            : .allOperators

        let options = Run.Options(
            filesToMutate: filesToMutate,
			unitTestFile: unitTestFile,
            reportFormat: reportOptions.reportFormat,
            reportURL: reportOptions.reportURL,
            mutationOperatorsList: mutationOperatorsList,
            skipCoverage: options.skipCoverage,
            skipUpdateCheck: options.skipUpdateCheck,
			configurationURL: options.configurationURL,
			mutationLimit: mutationLimit,
			randomizeTest: randomizeTest
        )

        try await run(with: options)
    }
}
