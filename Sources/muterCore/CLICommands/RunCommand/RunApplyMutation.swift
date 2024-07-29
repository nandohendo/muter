//
//  File.swift
//  
//
//  Created by Michael Jonathan on 29/07/24.
//

import Foundation
import ArgumentParser

struct RunApplyMutation: RunCommand {
	public static let configuration = CommandConfiguration(
		commandName: "run-apply-mutation",
		abstract: "Perform mutation testing"
	)
	
	@Option(help: "Only mutate a given list of source code files.")
	var filesToMutate: [String] = [
		"Sources/ViewModels/RiskChallengeViewModel.swift"
	]
	
	@Option(help: "Only include selected unit test")
	var unitTestFile: [String] = [
		"CardBindingTests/RiskChallengeViewModelSpec.swift"
	]
	
	@OptionGroup var options: RunArguments

	init() {}

	func run() async throws {
		let options = Run.Options(
			filesToMutate: filesToMutate,
			unitTestFile: unitTestFile,
			skipCoverage: options.skipCoverage,
			skipUpdateCheck: options.skipUpdateCheck,
			configurationURL: options.configurationURL,
			stepCommand: .runApplyMutation
		)
		
		try await run(with: options)
	}
}
