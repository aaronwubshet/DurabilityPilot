import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var showingCompletionConfirmation = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // Progress indicator
                ProgressView(value: viewModel.currentStepProgress)
                    .padding()
                    .tint(.electricGreen)
                
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
                .overlay(
                    // Transition loading indicator
                    Group {
                        if viewModel.isTransitioningToSports {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(.electricGreen)
                                Text("Loading sports options...")
                                    .font(.subheadline)
                                    .foregroundColor(.lightText)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.darkSpaceGrey.opacity(0.8))
                        }
                    }
                )
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .allowsHitTesting(!viewModel.isLoading && !viewModel.isTransitioningToSports) // Prevent swiping while loading
                
                // Navigation buttons
                HStack {
                    if viewModel.currentStep != .basicInfo {
                                            Button("Back") {
                        viewModel.previousStep()
                    }
                    .foregroundColor(.lightText)
                    .disabled(viewModel.isLoading || viewModel.isTransitioningToSports)
                    }
                    
                    Spacer()
                    
                    Button(viewModel.currentStep == OnboardingStep.allCases.last ? "Complete" : "Next") {
                        if viewModel.currentStep == OnboardingStep.allCases.last {
                            // Show confirmation dialog for completion
                            showingCompletionConfirmation = true
                        } else {
                            Task {
                                await viewModel.nextStep()
                            }
                        }
                    }
                    .foregroundColor(.electricGreen)
                    .disabled(!viewModel.canProceed || viewModel.isLoading || viewModel.isTransitioningToSports)

                }
                .padding()
            }
            .background(Color.darkSpaceGrey)
            .navigationTitle("Setup Your Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.setAppState(appState)
            }
            .alert("Complete Onboarding?", isPresented: $showingCompletionConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Complete") {
                    Task {
                        await viewModel.completeOnboarding()
                    }
                }
            } message: {
                Text("Are you sure you want to complete the onboarding process? You can always update your profile later.")
            }
        }
        .background(Color.darkSpaceGrey)
    }
}


