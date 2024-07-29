import Foundation

final class MutationTestHandler {
    @Dependency(\.notificationCenter)
    private var notificationCenter

    private lazy var observer: MutationTestObserver = .init(runOptions: options)

    let steps: [MutationStep]
    var state: AnyMutationTestState

    private let options: Run.Options

    init(
        options: Run.Options = .null,
        steps: [MutationStep] = .allSteps,
        state: MutationTestState = .init()
    ) {
        self.steps = steps
        self.state = state
        self.options = options
    }

    convenience init(
        options: Run.Options,
        steps: [MutationStep] = .allSteps
    ) {
        self.init(
            options: options,
            steps: steps.filtering(with: options),
            state: MutationTestState(from: options)
        )
    }

    func run() async throws {
        startObserver()
        notifyMuterLaunched()
        try await runMutationsSteps()
    }

    private func startObserver() {
        observer.start()
    }

    private func notifyMuterLaunched() {
        notificationCenter.post(name: .muterLaunched, object: nil)
    }

    private func runMutationsSteps() async throws {
        for step in steps {
            let changes = try await step.run(with: state)
            state.apply(changes)
        }
    }
}

private extension [MutationStep] {
    static let allSteps: [MutationStep] = [
//        UpdateCheck(),
        LoadConfiguration(),
        CreateMutatedProjectDirectoryURL(),
        PreviousRunCleanUp(),
        CopyProjectToTempDirectory(),
//        DiscoverProjectCoverage(),
        DiscoverSourceFiles(),
        DiscoverMutationPoints(),
        CreateMuterTestPlan(),
        GenerateSwapFilePaths(),
        ApplySchemata(),
        BuildForTesting(),
		DiscoverXCTestRun(),
        ProjectMappings(),
        PerformMutationTesting(),
    ]

    static let testPlanSteps: [MutationStep] = [
//        UpdateCheck(),
        LoadConfiguration(),
        LoadMuterTestPlan(),
        BuildForTesting(),
		DiscoverXCTestRun(),
        ProjectMappings(),
        PerformMutationTesting(),
    ]

    static let createTestPlanSteps: [MutationStep] = [
//        UpdateCheck(),
        LoadConfiguration(),
        CreateMutatedProjectDirectoryURL(),
        PreviousRunCleanUp(),
        CopyProjectToTempDirectory(),
//        DiscoverProjectCoverage(),
        DiscoverSourceFiles(),
        DiscoverMutationPoints(),
        ApplySchemata(),
        CreateMuterTestPlan(),
    ]
	
	static let createMutationWorkspace: [MutationStep] = [
		LoadConfiguration(),
		CreateMutatedProjectDirectoryURL(),
		PreviousRunCleanUp(),
		CopyProjectToTempDirectory()
	]
	
	static let discoverMutation: [MutationStep] = [
		LoadConfiguration(),
		CreateMutatedProjectDirectoryURL(),
		DiscoverSourceFiles(),
		DiscoverMutationPoints(),
		ApplySchemata(),
		CreateMuterTestPlan()
	]
	
	static let applySchemata: [MutationStep] = [
		LoadConfiguration(),
		LoadMuterTestPlan(),
		BuildForTesting(),
		ProjectMappings(),
	]
	
	static let applyMutation: [MutationStep] = [
		LoadConfiguration(),
		LoadMuterTestPlan(),
		DiscoverXCTestRun(),
		ProjectMappings(),
		PerformMutationTesting(),
	]

    func filtering(with options: Run.Options) -> [MutationStep] {
        var copy: [any MutationStep] = self
		
		guard options.stepCommand == .all else {
			if options.stepCommand == .createMutationWorkspace {
				copy = [MutationStep].createMutationWorkspace
			} else if options.stepCommand == .discoverMutation {
				copy = [MutationStep].discoverMutation
			} else if options.stepCommand == .runApplySchemata {
				copy = [MutationStep].applySchemata
			} else if options.stepCommand == .runApplyMutation {
				copy = [MutationStep].applyMutation
			}
			
			return copy
		}
		
        if options.isUsingTestPlan {
            copy = [MutationStep].testPlanSteps
        } else {
            copy.removeAll { $0 is ProjectMappings }
        }

        if options.createTestPlan {
            copy = [MutationStep].createTestPlanSteps
        } else {
            copy.removeAll { $0 is CreateMuterTestPlan }
        }

        if options.skipCoverage {
            copy.removeAll { $0 is DiscoverProjectCoverage }
        }

        if options.skipUpdateCheck {
            copy.removeAll { $0 is UpdateCheck }
        }

        return copy
    }
}
