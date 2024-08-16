import Foundation

struct BuildForTesting: MutationStep {
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter
    @Dependency(\.process)
    private var process: ProcessFactory

    func run(
        with state: AnyMutationTestState
    ) async throws -> [MutationTestState.Change] {
		let startDuration = Date()
        guard state.muterConfiguration.buildSystem == .xcodebuild else {
            return []
        }

        let currentDirectoryPath = fileManager.currentDirectoryPath

        defer {
			let endDuration = Double((Date().timeIntervalSince(startDuration) * 1000).rounded())
			print("Muter Duration: Build For Testing \(endDuration)")
			
            fileManager.changeCurrentDirectoryPath(currentDirectoryPath)
        }

        fileManager.changeCurrentDirectoryPath(state.mutatedProjectDirectoryURL.path)
		
		state.muterConfiguration.isCleanBuild = state.isCleanBuild
		
        do {
			let buildDirectory = try buildDirectory(state.muterConfiguration, projectDirectory: state.projectDirectoryURL.absoluteString, useSourceDerivedData: state.runOptions.useSourceDerivedData)
			let derivedDataPath = buildDirectory.replacingOccurrences(of: "/Build/Products", with: "")
			try runBuildForTestingCommand(state.muterConfiguration, derivedDataPath: derivedDataPath, useSourceDerivedData: state.runOptions.useSourceDerivedData, unitTestFiles: state.unitTestFiles)
            let tempDebugURL = debugURLForTempDirectory(state.mutatedProjectDirectoryURL)
            try copyBuildArtifactsAtPath(buildDirectory, to: tempDebugURL.path)
			
			if state.runOptions.useSourceDerivedData {
				return [.projectDerivedData(derivedDataPath)]
			} else {
				return []
			}
        } catch {
            throw MuterError.literal(reason: "\(error)")
        }
    }

	private func buildDirectory(_ configuration: MuterConfiguration, projectDirectory: String, useSourceDerivedData: Bool) throws -> String {
		
		var arguments: [String] = ["-showBuildSettings"]
		
		if useSourceDerivedData {
			arguments = configuration.buildForTestingArguments
			
			if let projectIndex = arguments.firstIndex(where: { $0 == "-project" }) {
				let projectName = arguments[projectIndex + 1]
				let previousProjectName = "\(projectDirectory)/\(projectName)"
				arguments[projectIndex + 1] = previousProjectName
				arguments.append("-showBuildSettings")
			}
		}
		
//		let arguments = ["-project", "\(projectDirectory)/CardBinding.xcodeproj", "-scheme", "CardBinding", "-destination", "platform=iOS Simulator,name=iPhone 15", "-showBuildSettings"]
		
        guard let buildSettings = process()
            .runProcess(url: configuration.testCommandExecutable, arguments: arguments)
            .flatMap(\.nilIfEmpty)
        else {
            throw MuterError.literal(reason: "Could not find `BUILD_DIR`")
        }

        print("testing: \(buildSettings)")

        guard let buildDirectory = buildSettings
            .firstMatchOf("BUILD_DIR = (.+)")?
            .replacingOccurrences(of: "BUILD_DIR = ", with: "")
            .trimmed
        else {
            throw MuterError.literal(reason: "Could not extract `BUILD_DIR` from project settings")
        }

        return buildDirectory
    }

    private func runBuildForTestingCommand(
        _ configuration: MuterConfiguration,
		derivedDataPath: String,
		useSourceDerivedData: Bool,
		unitTestFiles: [String] = []
    ) throws {
		
		var arguments = configuration.buildForTestingArguments
		
		if useSourceDerivedData {
			arguments.append("-derivedDataPath")
			arguments.append(derivedDataPath)
		}
		
		print(arguments)
		
        guard let result: String = process().runProcess(
            url: configuration.testCommandExecutable,
            arguments: arguments
        ).flatMap(\.nilIfEmpty)
        else {
            throw MuterError.literal(reason: "Could not run test with -build-for-testing argument")
        }
		
		print(result)
    }

    private func findBuildRequestJsonPath(_ output: String) throws -> String {
        guard let buildRequestFolder = output.firstMatchOf("Build description path: .*(\\n)")?
            .replacingOccurrences(of: "Build description path: ", with: "")
            .trimmed
        else {
            throw MuterError.literal(reason: "Could not parse buildRequest.json from build description path")
        }

        return "\(buildRequestFolder)/build-request.json"
    }

    private func parseBuildRequest(_ path: String) throws -> XCTestBuildRequest {
        guard let jsonContent = fileManager.contents(atPath: path) else {
            throw MuterError.literal(reason: "Could not parse build request json at path: \(path)")
        }

        return try JSONDecoder().decode(XCTestBuildRequest.self, from: jsonContent)
    }

    private func copyBuildArtifactsAtPath(_ buildPath: String, to destination: String) throws {
        try? fileManager.removeItem(
            atPath: destination
        )

        try fileManager.copyItem(
            atPath: buildPath,
            toPath: destination
        )
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

    private func debugURLForTempDirectory(_ tempURL: URL) -> URL {
        tempURL.appendingPathComponent("Debug")
    }
}

private struct XCTestBuildRequest: Codable {
    var buildProductsPath: String {
        parameters.arenaInfo.buildProductsPath
    }

    private let parameters: Parameters
}

extension XCTestBuildRequest {
    struct Parameters: Codable {
        let arenaInfo: ArenaInfo
    }
}

extension XCTestBuildRequest.Parameters {
    struct ArenaInfo: Codable {
        let buildProductsPath: String
    }
}
