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
	
	@OptionGroup var options: RunArguments

	init() {}

	func run() async throws {
		let options = Run.Options(
			filesToMutate: filesToMutate,
			skipCoverage: options.skipCoverage,
			skipUpdateCheck: options.skipUpdateCheck,
			configurationURL: options.configurationURL,
			stepCommand: .discoverMutation
		)
		
		try await run(with: options)
	}
}
