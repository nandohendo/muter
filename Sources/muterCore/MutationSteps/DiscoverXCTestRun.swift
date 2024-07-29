//
//  File.swift
//  
//
//  Created by Michael Jonathan on 29/07/24.
//

import Foundation

struct DiscoverXCTestRun: MutationStep {
	
	@Dependency(\.fileManager)
	private var fileManager: FileSystemManager
	
	func run(with state: AnyMutationTestState) async throws -> [MutationTestState.Change] {
		do {
			let tempPath = state.mutatedProjectDirectoryURL.appendingPathComponent("Debug")
			let xcTestRun = try parseXCTestRunAt(tempPath, unitTestFiles: state.unitTestFiles)
			return [.projectXCTestRun(xcTestRun)]
		} catch {
			throw MuterError.literal(reason: "\(error)")
		}
	}
	
	private func parseXCTestRunAt(_ url: URL, unitTestFiles: [String]) throws -> XCTestRun {
		let xcTestRunPath = try findMostRecentXCTestRunAtURL(url)
		guard let contents = fileManager.contents(atPath: xcTestRunPath),
			  let stringContents = String(data: contents, encoding: .utf8)
		else {
			throw MuterError.literal(reason: "Could not parse xctestrun at path: \(xcTestRunPath)")
		}

		guard let replaced = stringContents.replacingOccurrences(
			of: "__TESTROOT__/",
			with: "__TESTROOT__/Debug/"
		).data(using: .utf8)
		else {
			throw MuterError.literal(reason: "Error error")
		}
		
		guard var plist = try PropertyListSerialization.propertyList(
			from: replaced,
			format: nil
		) as? [String: AnyHashable]
		else {
			throw MuterError.literal(reason: "Could not parse xctestrun as plist at path: \(xcTestRunPath)")
		}
		
		if var testConfiguration = plist["TestConfigurations"] as? [[String: AnyHashable]],
		   var testTargets = (testConfiguration.first)?["TestTargets"] as? [[String: AnyHashable]],
		   var testTargetItem = testTargets.first {
			
			var onlyTestIdentifiers: [String] = []
			
			unitTestFiles.forEach { filePath in
				guard let getLastPath = filePath.split(separator: "/").last else {
					return
				}
				
				let filename = String(getLastPath).replacingOccurrences(of: ".swift", with: "")
				onlyTestIdentifiers.append(filename)
			}
			
			testTargetItem["OnlyTestIdentifiers"] = onlyTestIdentifiers
			testTargets[0] = testTargetItem
			testConfiguration[0]["TestTargets"] = testTargets
			plist["TestConfigurations"] = testConfiguration
		}
		
		let data = try PropertyListSerialization.data(
			fromPropertyList: plist,
			format: .xml,
			options: 0
		)
		
		return XCTestRun(plist)
	}

	private func findMostRecentXCTestRunAtURL(_ url: URL) throws -> String {
		guard let xctestrun = try fileManager.contents(
			atPath: url.path,
			sortedByDate: .orderedDescending
		).first(where: { $0.hasSuffix(".xctestrun") })
		else {
			throw MuterError.literal(reason: "Could not find xctestrun file at path: \(url.path)")
		}

		return xctestrun
	}
}
