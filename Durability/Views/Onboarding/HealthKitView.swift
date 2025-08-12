import SwiftUI
import HealthKit

struct HealthKitView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "heart.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            Text("Connect Apple Health")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Durability can read and write health data to provide personalized insights and track your progress.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("We'll access:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    HealthKitPermissionRow(icon: "figure.walk", text: "Steps and activity")
                    HealthKitPermissionRow(icon: "flame.fill", text: "Active energy burned")
                    HealthKitPermissionRow(icon: "heart.fill", text: "Heart rate")
                    HealthKitPermissionRow(icon: "scalemass.fill", text: "Weight and height")
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)
            
            Button(action: {
                Task {
                    await requestHealthKitPermission()
                }
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                    Text("Allow Health Access")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(appState.healthKitService.isAuthorized)
            

            
            if appState.healthKitService.isAuthorized {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Health access granted")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    

    
    private func requestHealthKitPermission() async {
        let granted = await appState.healthKitService.requestAuthorization()
        viewModel.healthKitAuthorized = granted
        guard granted else { return }
        // Prefill onboarding fields from HealthKit when available
        await appState.healthKitService.fetchTodayHealthData()
        if let kg = appState.healthKitService.healthData?.weight {
            let lbs = Int((kg * 2.20462).rounded())
            viewModel.weight = String(lbs)
        }
        if let meters = appState.healthKitService.healthData?.height {
            let totalInches = meters * 39.3700787
            let feet = Int(totalInches / 12.0)
            let inches = Int((totalInches - Double(feet) * 12.0).rounded())
            viewModel.heightFeet = String(max(0, feet))
            viewModel.heightInches = String(max(0, min(inches, 11)))
        }
        if let dob = appState.healthKitService.getDateOfBirth() {
            viewModel.dateOfBirth = dob
        }
        if let sex = appState.healthKitService.getBiologicalSex() {
            switch sex {
            case .female: viewModel.sex = .female
            case .male: viewModel.sex = .male
            case .other: viewModel.sex = .other
            case .notSet: viewModel.sex = nil
            @unknown default: viewModel.sex = nil
            }
        }
        // Persist to Supabase, then load latest profile values to ensure UI shows DB-backed values
        await appState.healthKitService.upsertProfileFromHealthData(appState: appState)
        if let userId = appState.authService.user?.id.uuidString,
           let profile = try? await appState.profileService.getProfile(userId: userId) {
            // Map DB back to onboarding fields in the same units as UI
            if let cm = profile.heightCm {
                let inches = cm / 2.54
                let feet = Int(inches / 12.0)
                let remInches = Int((inches - Double(feet) * 12.0).rounded())
                viewModel.heightFeet = String(max(0, feet))
                viewModel.heightInches = String(max(0, min(remInches, 11)))
            }
            if let kg = profile.weightKg {
                let lbs = Int((kg * 2.20462).rounded())
                viewModel.weight = String(lbs)
            }
            if let profileDob = profile.dateOfBirth {
                viewModel.dateOfBirth = profileDob
            }
            if let sex = profile.sex { viewModel.sex = sex }
        }
        // Auto-advance to the next onboarding step after granting access
        viewModel.nextStep()
    }
}

struct HealthKitPermissionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

#Preview {
    HealthKitView(viewModel: OnboardingViewModel())
        .environmentObject(AppState())
}
