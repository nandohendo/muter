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
	var filesToMutate: [String] = []
	
	@Option(help: "Only include selected unit test")
	var unitTestFile: [String] = []
	
	@OptionGroup var options: RunArguments
	@OptionGroup var reportOptions: ReportArguments
	
	@Option(help: "Add test plan URL")
	var testPlanURL: URL?
	
	init() {}

	func run() async throws {
		let options = Run.Options(
			filesToMutate: filesToMutate,
			unitTestFile: unitTestFile,
			reportFormat: reportOptions.reportFormat,
			reportURL: reportOptions.reportURL,
			skipCoverage: options.skipCoverage,
			skipUpdateCheck: options.skipUpdateCheck,
			configurationURL: options.configurationURL,
			testPlanURL: testPlanURL,
			stepCommand: .runApplyMutation
		)
		
		try await run(with: options)
	}
}
