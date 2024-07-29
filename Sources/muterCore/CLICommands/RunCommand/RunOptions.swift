import Foundation

typealias ReportOptions = (reporter: Reporter, path: String?)

enum StepCommand {
	case createMutationWorkspace
	case discoverMutation
	case runApplySchemata
	case runApplyMutation
	case all
}

extension Run {
    struct Options {
        let reportOptions: ReportOptions
        let filesToMutate: [String]
		let unitTestFile: [String]
        let mutationOperatorsList: MutationOperatorList
        let skipCoverage: Bool
        let skipUpdateCheck: Bool
        let configurationURL: URL?
        let testPlanURL: URL?
        let createTestPlan: Bool
		let stepCommand: StepCommand
        var isUsingTestPlan: Bool {
            testPlanURL != nil
        }

        init(
            filesToMutate: [String] = [],
			unitTestFile: [String] = [],
            reportFormat: ReportFormat = .plain,
            reportURL: URL? = nil,
            mutationOperatorsList: MutationOperatorList = .allOperators,
            skipCoverage: Bool,
            skipUpdateCheck: Bool,
            configurationURL: URL?,
            testPlanURL: URL? = nil,
            createTestPlan: Bool = false,
			stepCommand: StepCommand = .all
        ) {
            self.skipCoverage = skipCoverage
            self.skipUpdateCheck = skipUpdateCheck
            self.createTestPlan = createTestPlan
            self.mutationOperatorsList = mutationOperatorsList
            self.configurationURL = URL(string: "/Users/jonathanm/Documents/DANA-Project/card_binding_flow_ios")
			self.testPlanURL = URL(string: "/Users/jonathanm/Documents/DANA-Project/card_binding_flow_ios/muter-mappings.json")
			self.stepCommand = stepCommand

            self.filesToMutate = filesToMutate.reduce(into: []) { accum, next in
                accum.append(
                    contentsOf: next.components(separatedBy: ",")
                        .exclude { $0.isEmpty }
                )
            }
			
			self.unitTestFile = unitTestFile.reduce(into: []) { accum, next in
				accum.append(
					contentsOf: next.components(separatedBy: ",")
						.exclude { $0.isEmpty }
				)
			}

            reportOptions = ReportOptions(
                reporter: reportFormat.reporter,
                path: reportURL?.path
            )
        }
    }
}
extension Run.Options: Equatable {
    static func == (lhs: Run.Options, rhs: Run.Options) -> Bool {
        lhs.filesToMutate == rhs.filesToMutate &&
		lhs.unitTestFile == rhs.unitTestFile &&
            lhs.mutationOperatorsList == rhs.mutationOperatorsList &&
            lhs.skipCoverage == rhs.skipCoverage &&
            lhs.skipUpdateCheck == rhs.skipUpdateCheck &&
            lhs.configurationURL == rhs.configurationURL &&
            lhs.testPlanURL == rhs.testPlanURL &&
            lhs.reportOptions.path == rhs.reportOptions.path &&
            "\(lhs.reportOptions.reporter)" == "\(rhs.reportOptions.reporter)"
    }
}

extension Run.Options: Nullable {
    static var null: Run.Options {
        .init(
            filesToMutate: [],
			unitTestFile: [],
            reportFormat: .plain,
            reportURL: nil,
            mutationOperatorsList: [],
            skipCoverage: false,
            skipUpdateCheck: false,
            configurationURL: nil,
            testPlanURL: nil,
            createTestPlan: false
        )
    }
}
