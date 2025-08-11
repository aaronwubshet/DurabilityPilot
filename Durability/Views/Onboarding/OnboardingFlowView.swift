import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                // Progress indicator
                ProgressView(value: viewModel.currentStepProgress)
                    .padding()
                
                // Step content
                TabView(selection: $viewModel.currentStep) {
                    HealthKitView(viewModel: viewModel)
                        .tag(OnboardingStep.healthKit)
                    
                    BasicInfoView(viewModel: viewModel)
                        .tag(OnboardingStep.basicInfo)
                    
                    EquipmentView(viewModel: viewModel)
                        .tag(OnboardingStep.equipment)
                    
                    InjuryHistoryView(viewModel: viewModel)
                        .tag(OnboardingStep.injuries)
                    
                    TrainingPlanView(viewModel: viewModel)
                        .tag(OnboardingStep.trainingPlan)
                    
                    SportsView(viewModel: viewModel)
                        .tag(OnboardingStep.sports)
                    
                    GoalsView(viewModel: viewModel)
                        .tag(OnboardingStep.goals)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Navigation buttons
                HStack {
                    if viewModel.currentStep != .basicInfo {
                        Button("Back") {
                            viewModel.previousStep()
                        }
                    }
                    
                    Spacer()
                    
                    Button(viewModel.currentStep == OnboardingStep.allCases.last ? "Complete" : "Next") {
                        if viewModel.currentStep == OnboardingStep.allCases.last {
                            Task {
                                await viewModel.completeOnboarding(appState: appState)
                            }
                        } else {
                            viewModel.nextStep()
                        }
                    }
                    .disabled(!viewModel.canProceed)
                }
                .padding()
            }
            .navigationTitle("Setup Your Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


