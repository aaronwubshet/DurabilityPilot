import SwiftUI

struct MovementDetailView: View {
    let movement: Movement
    @StateObject private var vm = MovementDetailViewModel()
    @State private var resolvedMovement: Movement?
    @State private var isResolving = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text(isResolving ? "Loading..." : (resolvedMovement?.name ?? movement.name))
                    .font(.largeTitle)
                    .bold()

                // Video placeholder
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 200)
                        .cornerRadius(12)
                    VStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("Video coming soon")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                }

                // Long description (from movement_content)
                if let longText = vm.longDescription, !longText.isEmpty {
                    Text(longText)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                } else if !movement.description.isEmpty {
                    Text(movement.description)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                } else if vm.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading description...")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                } else if vm.hasError {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Failed to load detailed description")
                            .font(.body)
                            .foregroundColor(.red)
                        Text("Using basic description instead")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("No detailed description available for this movement.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                }

                				                // Required Equipment
				if isResolving {
					VStack(alignment: .leading, spacing: 12) {
						Text("Required Equipment")
							.font(.headline)
						HStack {
							ProgressView()
								.scaleEffect(0.8)
							Text("Loading equipment details...")
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}
				} else if !(resolvedMovement?.requiredEquipment ?? movement.requiredEquipment).isEmpty {
					VStack(alignment: .leading, spacing: 12) {
						Text("Required Equipment")
							.font(.headline)
						
						LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
							ForEach(resolvedMovement?.requiredEquipment ?? movement.requiredEquipment, id: \.self) { equipment in
								Text(equipment)
									.font(.caption)
									.padding(.horizontal, 12)
									.padding(.vertical, 6)
									.background(Color.blue.opacity(0.15))
									.foregroundColor(.blue)
									.cornerRadius(8)
									.frame(maxWidth: .infinity, alignment: .center)
							}
						}
					}
				}
				
				// Impact Vectors
				if isResolving {
					VStack(alignment: .leading, spacing: 16) {
						Text("Impact Vectors")
							.font(.headline)
						HStack {
							ProgressView()
								.scaleEffect(0.8)
							Text("Loading impact details...")
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}
				} else if hasAnyImpacts {
					VStack(alignment: .leading, spacing: 16) {
						Text("Impact Vectors")
							.font(.headline)
						
						if !(resolvedMovement?.goalImpacts ?? movement.goalImpacts).isEmpty {
							tagSection(title: "Goals Impacted", tags: resolvedMovement?.goalImpacts ?? movement.goalImpacts, color: .green)
						}
						
						if !(resolvedMovement?.bodyPartImpacts ?? movement.bodyPartImpacts).isEmpty {
							tagSection(title: "Body Parts Impacted", tags: resolvedMovement?.bodyPartImpacts ?? movement.bodyPartImpacts, color: .purple)
						}
						
						if !(resolvedMovement?.superMetricsImpacted ?? movement.superMetricsImpacted).isEmpty {
							tagSection(title: "Super Metrics", tags: resolvedMovement?.superMetricsImpacted ?? movement.superMetricsImpacted, color: .orange)
						}
						
						if !(resolvedMovement?.sportsImpacted ?? movement.sportsImpacted).isEmpty {
							tagSection(title: "Sports", tags: resolvedMovement?.sportsImpacted ?? movement.sportsImpacted, color: .blue)
						}
					}
				}
				
				// Injury Considerations
				if isResolving {
					VStack(alignment: .leading, spacing: 16) {
						Text("Injury Considerations")
							.font(.headline)
						HStack {
							ProgressView()
								.scaleEffect(0.8)
							Text("Loading injury details...")
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}
				} else if hasAnyInjuryFlags {
					VStack(alignment: .leading, spacing: 16) {
						Text("Injury Considerations")
							.font(.headline)
						
						if !movement.injuryIndications.isEmpty {
							tagSection(title: "May Help With", tags: movement.injuryIndications, color: .green)
						}
						
						if !movement.injuryContraindications.isEmpty {
							tagSection(title: "Avoid If You Have", tags: movement.injuryContraindications, color: .red)
						}
					}
				}
				
				// Tags organized by category
				if isResolving {
					VStack(alignment: .leading, spacing: 16) {
						Text("Movement Details")
							.font(.headline)
						HStack {
							ProgressView()
								.scaleEffect(0.8)
							Text("Loading movement details...")
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}
				} else if hasAnyTags {
					VStack(alignment: .leading, spacing: 16) {
						Text("Movement Details")
							.font(.headline)
						
						if !movement.jointsImpacted.isEmpty {
							tagSection(title: "Joints Impacted", tags: movement.jointsImpacted, color: .blue)
						}
						
						if !movement.musclesImpacted.isEmpty {
							tagSection(title: "Muscles Impacted", tags: movement.musclesImpacted, color: .purple)
						}
						
						if !movement.intensityOptions.isEmpty {
							tagSection(title: "Intensity Options", tags: movement.intensityOptions, color: .red)
						}
					}
				}

                // Module score breakdown
                VStack(alignment: .leading, spacing: 8) {
                    Text("Module Scores")
                        .font(.headline)
                    if isResolving {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading scores...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        ModuleScoreRow(label: "Recovery", score: movement.recoveryImpactScore, tint: .blue)
                        ModuleScoreRow(label: "Resilience", score: movement.resilienceImpactScore, tint: .purple)
                        ModuleScoreRow(label: "Results", score: movement.resultsImpactScore, tint: .green)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(isResolving ? "Loading..." : (resolvedMovement?.name ?? movement.name))
        .task { 
            await vm.loadLongDescription(name: movement.name)
            await resolveMovementDetails()
        }
    }

    	private var hasAnyTags: Bool {
		if isResolving { return false }
		return !(movement.jointsImpacted.isEmpty && movement.musclesImpacted.isEmpty && movement.intensityOptions.isEmpty)
	}
	
	    	private var hasAnyImpacts: Bool {
		if isResolving { return false }
		return !((resolvedMovement?.goalImpacts ?? movement.goalImpacts).isEmpty && 
		  (resolvedMovement?.bodyPartImpacts ?? movement.bodyPartImpacts).isEmpty && 
		  (resolvedMovement?.superMetricsImpacted ?? movement.superMetricsImpacted).isEmpty && 
		  (resolvedMovement?.sportsImpacted ?? movement.sportsImpacted).isEmpty)
	}
	
	    	private var hasAnyInjuryFlags: Bool {
		if isResolving { return false }
		return !(movement.injuryIndications.isEmpty && movement.injuryContraindications.isEmpty)
	}

    private func resolveMovementDetails() async {
        guard !isResolving else { return }
        isResolving = true
        
        do {
            let movementService = MovementLibraryService()
            if let resolved = try await movementService.getMovementWithDetails(byId: movement.name) {
                await MainActor.run {
                    self.resolvedMovement = resolved
                }
            }
        } catch {
            print("Failed to resolve movement details: \(error)")
        }
        
        await MainActor.run {
            self.isResolving = false
        }
    }
    
    @ViewBuilder
    private func tagSection(title: String, tags: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.15))
                        .foregroundColor(color)
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
}

private struct ModuleScoreRow: View {
    let label: String
    let score: Double
    let tint: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(String(format: "%.0f%%", score * 100))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(tint)
                
                ProgressView(value: min(max(score, 0), 1))
                    .progressViewStyle(LinearProgressViewStyle(tint: tint))
                    .frame(width: 140)
            }
        }
        .padding(.vertical, 4)
    }
}

@MainActor
private class MovementDetailViewModel: ObservableObject {
    @Published var longDescription: String?
    @Published var isLoading = false
    @Published var hasError = false
    private let service = MovementLibraryService()
    
    func loadLongDescription(name: String) async {
        isLoading = true
        hasError = false
        
        do {
            let description = try await service.getMovementLongDescription(byName: name)
            self.longDescription = description
        } catch {
            print("Failed to load movement description: \(error)")
            self.hasError = true
            self.longDescription = nil
        }
        
        isLoading = false
    }
}

#Preview {
	NavigationStack {
		MovementDetailView(movement: Movement(
			id: 1,
			name: "Sample Movement",
			description: "A sample movement for testing",
			videoURL: nil,
			jointsImpacted: ["Knee", "Hip"],
			musclesImpacted: ["Quadriceps", "Glutes"],
			superMetricsImpacted: ["Strength", "Power"],
			sportsImpacted: ["Basketball", "Soccer"],
			intensityOptions: ["Light", "Medium", "Heavy"],
			recoveryImpactScore: 0.7,
			resilienceImpactScore: 0.8,
			resultsImpactScore: 0.6,
			requiredEquipment: ["Dumbbells", "Bench"],
			goalImpacts: ["Strength", "Muscle Building"],
			bodyPartImpacts: ["Legs", "Core"],
			injuryIndications: ["Knee Pain", "Back Pain"],
			injuryContraindications: ["Shoulder Injury", "Wrist Pain"]
		))
	}
}
