//
//  File.swift
//  
//
//  Created by Michael Jonathan on 25/07/24.
//

import Foundation
import ArgumentParser

struct CreateMuterWorkspace: RunCommand {
	public static let configuration = CommandConfiguration(
		commandName: "create-muter-workspace",
		abstract: "Clean up and create muter workspace"
	)
	
	@OptionGroup var options: RunArguments

	init() {}

	func run() async throws {
		let options = Run.Options(
			skipCoverage: options.skipCoverage,
			skipUpdateCheck: options.skipUpdateCheck,
			configurationURL: options.configurationURL,
			stepCommand: .createMutationWorkspace
		)
		
		try await run(with: options)
	}
}
