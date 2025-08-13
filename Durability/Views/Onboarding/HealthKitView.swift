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
            
            // Debug button for troubleshooting
            Button(action: {
                Task {
                    await debugHealthKitData()
                }
            }) {
                HStack {
                    Image(systemName: "ladybug.fill")
                        .foregroundColor(.white)
                    Text("Debug HealthKit Data")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.top, 10)
            
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
        .autoDismissKeyboard()
    }
    

    
    private func requestHealthKitPermission() async {
        print("HealthKitView: Starting HealthKit permission request")
        let granted = await appState.healthKitService.requestAuthorization()
        print("HealthKitView: HealthKit authorization granted: \(granted)")
        viewModel.healthKitAuthorized = granted
        guard granted else { 
            print("HealthKitView: HealthKit authorization denied, returning")
            return 
        }
        
        // Prefill onboarding fields from HealthKit when available
        print("HealthKitView: Fetching today's health data")
        await appState.healthKitService.fetchTodayHealthData()
        
        print("HealthKitView: Attempting to populate fields from HealthKit data")
        
        var retrievedData: [String] = []
        var missingData: [String] = []
        
        if let kg = appState.healthKitService.healthData?.weight {
            let lbs = Int((kg * 2.20462).rounded())
            viewModel.weight = String(lbs)
            print("HealthKitView: Set weight to: \(lbs) lbs")
            retrievedData.append("Weight")
        } else {
            print("HealthKitView: No weight data available from HealthKit")
            missingData.append("Weight")
        }
        
        if let meters = appState.healthKitService.healthData?.height {
            let totalInches = meters * 39.3700787
            let feet = Int(totalInches / 12.0)
            let inches = Int((totalInches - Double(feet) * 12.0).rounded())
            viewModel.heightFeet = String(max(0, feet))
            viewModel.heightInches = String(max(0, min(inches, 11)))
            print("HealthKitView: Set height to: \(feet)' \(inches)\"")
            retrievedData.append("Height")
        } else {
            print("HealthKitView: No height data available from HealthKit")
            missingData.append("Height")
        }
        
        if let dob = appState.healthKitService.getDateOfBirth() {
            viewModel.dateOfBirth = dob
            print("HealthKitView: Set dateOfBirth to: \(dob)")
            retrievedData.append("Date of Birth")
        } else {
            print("HealthKitView: No date of birth available from HealthKit")
            missingData.append("Date of Birth")
        }
        
        if let sex = appState.healthKitService.getBiologicalSex() {
            switch sex {
            case .female: 
                viewModel.sex = .female
                print("HealthKitView: Set sex to: female")
            case .male: 
                viewModel.sex = .male
                print("HealthKitView: Set sex to: male")
            case .other: 
                viewModel.sex = .other
                print("HealthKitView: Set sex to: other")
            case .notSet: 
                viewModel.sex = nil
                print("HealthKitView: Sex not set in HealthKit")
            @unknown default: 
                viewModel.sex = nil
                print("HealthKitView: Unknown sex value from HealthKit")
            }
            retrievedData.append("Biological Sex")
        } else {
            print("HealthKitView: No biological sex available from HealthKit")
            missingData.append("Biological Sex")
        }
        
        // Log summary of retrieved vs missing data
        print("HealthKitView: Successfully retrieved: \(retrievedData.joined(separator: ", "))")
        if !missingData.isEmpty {
            print("HealthKitView: Missing data (will need manual entry): \(missingData.joined(separator: ", "))")
        }
        
        // Persist to Supabase, then load latest profile values to ensure UI shows DB-backed values
        print("HealthKitView: Persisting HealthKit data to Supabase")
        await appState.healthKitService.upsertProfileFromHealthData(appState: appState)
        
        print("HealthKitView: Loading profile data from database to update UI")
        if let userId = appState.authService.user?.id.uuidString,
           let profile = try? await appState.profileService.getProfile(userId: userId) {
            print("HealthKitView: Profile loaded from database:")
            print("   - heightCm: \(profile.heightCm?.description ?? "nil")")
            print("   - weightKg: \(profile.weightKg?.description ?? "nil")")
            
            // Map DB back to onboarding fields in the same units as UI
            if let cm = profile.heightCm {
                let inches = cm / 2.54
                let feet = Int(inches / 12.0)
                let remInches = Int((inches - Double(feet) * 12.0).rounded())
                viewModel.heightFeet = String(max(0, feet))
                viewModel.heightInches = String(max(0, min(remInches, 11)))
                print("HealthKitView: Updated height from database: \(feet)' \(remInches)\" (\(cm) cm)")
            } else {
                print("HealthKitView: No height data in profile")
            }
            
            if let kg = profile.weightKg {
                let lbs = Int((kg * 2.20462).rounded())
                viewModel.weight = String(lbs)
                print("HealthKitView: Updated weight from database: \(lbs) lbs (\(kg) kg)")
            } else {
                print("HealthKitView: No weight data in profile")
            }
            if let profileDob = profile.dateOfBirth {
                viewModel.dateOfBirth = profileDob
                print("HealthKitView: Updated dateOfBirth from database: \(profileDob)")
            }
            if let sex = profile.sex { 
                viewModel.sex = sex
                print("HealthKitView: Updated sex from database: \(sex.rawValue)")
            }
        } else {
            print("HealthKitView: Could not load profile from database")
        }
        
        // Auto-advance to the next onboarding step after granting access
        print("HealthKitView: Auto-advancing to next step")
        await viewModel.nextStep()
    }
    
    private func debugHealthKitData() async {
        print("🔍 HealthKitView: Starting HealthKit debug...")
        
        // Check authorization status
        appState.healthKitService.debugAuthorizationStatus()
        
        // Force refresh health data
        await appState.healthKitService.forceRefreshHealthData()
        
        // Try to read individual values
        print("🔍 HealthKitView: Testing individual HealthKit reads...")
        
        // Test weight reading
        do {
            let weight = try await appState.healthKitService.fetchWeight()
            print("🔍 HealthKitView: Direct weight fetch result: \(weight?.description ?? "nil")")
        } catch {
            print("❌ HealthKitView: Direct weight fetch failed: \(error.localizedDescription)")
        }
        
        // Test height reading
        do {
            let height = try await appState.healthKitService.fetchHeight()
            print("🔍 HealthKitView: Direct height fetch result: \(height?.description ?? "nil")")
        } catch {
            print("❌ HealthKitView: Direct height fetch failed: \(error.localizedDescription)")
        }
        
        // Test date of birth
        let dob = appState.healthKitService.getDateOfBirth()
        print("🔍 HealthKitView: Direct date of birth fetch result: \(dob?.description ?? "nil")")
        
        // Test biological sex
        let sex = appState.healthKitService.getBiologicalSex()
        print("🔍 HealthKitView: Direct biological sex fetch result: \(sex?.rawValue.description ?? "nil")")
        
        print("🔍 HealthKitView: Debug complete")
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
