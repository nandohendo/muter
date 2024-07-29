//
//  File.swift
//
//
//  Created by Michael Jonathan on 25/07/24.
//

import Foundation
import ArgumentParser

struct DiscoverMutation: RunCommand {
	public static let configuration = CommandConfiguration(
		commandName: "discover-mutation",
		abstract: "Discover mutation point"
	)
	
	@Option(help: "Only mutate a given list of source code files.")
	var filesToMutate: [String] = []
	
	@Option(help: "Only include selected unit test")
	var unitTestFile: [String] = []
	
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

	init() {}

	func run() async throws {
		let mutationOperatorsList = !operators.isEmpty
			? operators
			: .allOperators
		
		let options = Run.Options(
			filesToMutate: filesToMutate,
			mutationOperatorsList: mutationOperatorsList,
			skipCoverage: options.skipCoverage,
			skipUpdateCheck: options.skipUpdateCheck,
			configurationURL: options.configurationURL,
			stepCommand: .discoverMutation
		)
		
		try await run(with: options)
	}
}
