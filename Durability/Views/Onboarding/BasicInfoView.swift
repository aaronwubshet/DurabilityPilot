import SwiftUI

struct BasicInfoView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    // Local selectors synchronized with viewModel.dateOfBirth
    @State private var selectedDay: Int = 1
    @State private var selectedMonth: Int = 1
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    // Height & Weight pickers
    @State private var selectedFeet: Int = 5
    @State private var selectedInches: Int = 8
    @State private var selectedWeight: Int = 170
    
    private let feetRange = Array(3...7)
    private let inchesRange = Array(0...11)
    private let weightRange = Array(60...400) // lbs
    
    private var monthNames: [String] {
        DateFormatter().monthSymbols
    }
    
    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }
    private var years: [Int] { stride(from: currentYear, through: 1900, by: -1).map { $0 } }
    private var daysInSelectedMonth: Int { numberOfDays(in: selectedMonth, year: selectedYear) }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Tell us about yourself")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("This helps us personalize your experience")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Name fields
                VStack(alignment: .leading, spacing: 10) {
                    Text("Name")
                        .font(.headline)
                    
                    HStack {
                        TextField("First Name", text: $viewModel.firstName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Last Name", text: $viewModel.lastName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                // Date of Birth (Day / Month / Year selectors)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Date of Birth")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        // Day
                        Picker("Day", selection: $selectedDay) {
                            ForEach(1...daysInSelectedMonth, id: \.self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .onChange(of: selectedDay) { _, _ in
                            syncDateOfBirth()
                        }
                        
                        // Month
                        Picker("Month", selection: $selectedMonth) {
                            ForEach(1...12, id: \.self) { month in
                                Text(monthNames[month - 1]).tag(month)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .onChange(of: selectedMonth) { _, _ in
                            clampDayIfNeeded()
                            syncDateOfBirth()
                        }
                        
                        // Year
                        Picker("Year", selection: $selectedYear) {
                            ForEach(years, id: \.self) { year in
                                Text(verbatim: String(year)).tag(year)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .onChange(of: selectedYear) { _, _ in
                            clampDayIfNeeded()
                            syncDateOfBirth()
                        }
                    }
                    
                    if viewModel.calculatedAge > 0 {
                        Text("Age: \(viewModel.calculatedAge) years old")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Sex
                VStack(alignment: .leading, spacing: 10) {
                    Text("Sex")
                        .font(.headline)
                    
                    Menu {
                        Button("—", action: { viewModel.sex = nil })
                        ForEach(UserProfile.Sex.allCases, id: \.self) { sex in
                            Button(action: { viewModel.sex = sex }) {
                                HStack {
                                    Text(sex.displayName)
                                    if viewModel.sex == sex {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.sex?.displayName ?? "Select…")
                                .foregroundColor(viewModel.sex == nil ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                
                // Height
                VStack(alignment: .leading, spacing: 10) {
                    Text("Height")
                        .font(.headline)
                    
                    HStack(alignment: .center, spacing: 12) {
                        // Feet wheel
                        Picker("Feet", selection: $selectedFeet) {
                            ForEach(feetRange, id: \.self) { feet in
                                Text("\(feet) ft").tag(feet)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 120, height: 120)
                        .clipped()
                        .onChange(of: selectedFeet) { _, _ in
                            viewModel.heightFeet = String(selectedFeet)
                        }
                        
                        // Inches wheel
                        Picker("Inches", selection: $selectedInches) {
                            ForEach(inchesRange, id: \.self) { inch in
                                Text("\(inch) in").tag(inch)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 120, height: 120)
                        .clipped()
                        .onChange(of: selectedInches) { _, _ in
                            viewModel.heightInches = String(selectedInches)
                        }
                    }
                }
                
                // Weight
                VStack(alignment: .leading, spacing: 10) {
                    Text("Weight")
                        .font(.headline)
                    
                    HStack(alignment: .center, spacing: 12) {
                        Picker("Weight", selection: $selectedWeight) {
                            ForEach(weightRange, id: \.self) { w in
                                Text("\(w) lbs").tag(w)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                        .clipped()
                        .onChange(of: selectedWeight) { _, _ in
                            viewModel.weight = String(selectedWeight)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            initializeDOBSelectors()
            initializePhysicalSelectors()
        }
    }
    
    private func initializeDOBSelectors() {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.day, .month, .year], from: viewModel.dateOfBirth)
        selectedDay = comps.day ?? 1
        selectedMonth = comps.month ?? 1
        selectedYear = comps.year ?? currentYear
        clampDayIfNeeded()
    }
    
    private func initializePhysicalSelectors() {
        // Height defaults from viewModel if present
        if let feet = Int(viewModel.heightFeet), feetRange.contains(feet) {
            selectedFeet = feet
        }
        if let inches = Int(viewModel.heightInches), inchesRange.contains(inches) {
            selectedInches = inches
        }
        // Weight defaults from viewModel if present
        if let w = Int(viewModel.weight), weightRange.contains(w) {
            selectedWeight = w
        }
        // Write initial values back if empty
        if viewModel.heightFeet.isEmpty { viewModel.heightFeet = String(selectedFeet) }
        if viewModel.heightInches.isEmpty { viewModel.heightInches = String(selectedInches) }
        if viewModel.weight.isEmpty { viewModel.weight = String(selectedWeight) }
    }
    
    private func syncDateOfBirth() {
        var comps = DateComponents()
        comps.day = selectedDay
        comps.month = selectedMonth
        comps.year = selectedYear
        if let date = Calendar.current.date(from: comps) {
            viewModel.dateOfBirth = date
        }
    }
    
    private func clampDayIfNeeded() {
        let maxDay = daysInSelectedMonth
        if selectedDay > maxDay {
            selectedDay = maxDay
        }
    }
    
    private func numberOfDays(in month: Int, year: Int) -> Int {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        let calendar = Calendar.current
        guard let date = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 31
        }
        return range.count
    }
}



#Preview {
    BasicInfoView(viewModel: OnboardingViewModel())
}
