import Foundation
import Supabase

@MainActor
class MovementLibraryService: ObservableObject {
	private let supabase = SupabaseManager.shared.client
	
	private enum DecodableId: Decodable {
		case string(String)
		case int(Int)
		
		init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			if let intValue = try? container.decode(Int.self) {
				self = .int(intValue)
				return
			}
			let stringValue = try container.decode(String.self)
			self = .string(stringValue)
		}
	}
	
	private struct LibraryMovementRow: Decodable {
		let id: DecodableId
		let name: String
		let default_module_impact_vector: [String: Double]?
		let video_url: String?
		let default_sport_impact_vector: [String: Double]?
		let default_goal_impact_vector: [String: Double]?
		let default_body_part_impact_vector: [String: Double]?
		let default_injury_flags: [String: [String]]?
		let default_super_metric_impact_vector: [String: Double]?
		let required_equipment: [DecodableId]?
	}
	
	enum MovementLibraryError: Error, LocalizedError {
		case notFound
		
		var errorDescription: String? {
			switch self {
			case .notFound:
				return "No movements found."
			}
		}
	}
	
	/// Fetch all movements from public.movements and map to app Movement model
	func getAllMovements() async throws -> [Movement] {
		// Select comprehensive columns to ensure all movement details are available
		let rows: [LibraryMovementRow] = try await supabase
			.from("movements")
			.select("id,name,default_module_impact_vector,default_sport_impact_vector,default_goal_impact_vector,default_body_part_impact_vector,default_injury_flags,default_super_metric_impact_vector,required_equipment")
			.order("name", ascending: true)
			.execute()
			.value
		
		// Return movements with raw IDs for now - they'll be resolved when needed
		return mapRowsToMovements(rows)
	}
	
	/// Fetch a single movement by ID from public.movements
	func getMovement(byId movementId: String) async throws -> Movement? {
		print("🔍 [getMovement] Searching for movement with ID: \(movementId)")
		
		// Try to convert string ID to int, or search by name if it's a string
		if let intId = Int(movementId) {
			print("🔍 [getMovement] Converting to int ID: \(intId)")
			// Search by numeric ID
			let rows: [LibraryMovementRow] = try await supabase
				.from("movements")
				.select("id,name,default_module_impact_vector,default_sport_impact_vector,default_goal_impact_vector,default_body_part_impact_vector,default_injury_flags,default_super_metric_impact_vector,required_equipment")
				.eq("id", value: intId)
				.limit(1)
				.execute()
				.value
			
			print("🔍 [getMovement] Found \(rows.count) rows for int ID \(intId)")
			guard let row = rows.first else { 
				print("❌ [getMovement] No rows found for int ID \(intId)")
				return nil 
			}
			print("✅ [getMovement] Found movement: \(row.name)")
			return mapRowsToMovements([row]).first
		} else {
			print("🔍 [getMovement] Searching by name: \(movementId)")
			// Search by name if ID is a string
			let rows: [LibraryMovementRow] = try await supabase
				.from("movements")
				.select("id,name,default_module_impact_vector,default_sport_impact_vector,default_goal_impact_vector,default_body_part_impact_vector,default_injury_flags,default_super_metric_impact_vector,required_equipment")
				.eq("name", value: movementId)
				.limit(1)
				.execute()
				.value
			
			print("🔍 [getMovement] Found \(rows.count) rows for name \(movementId)")
			guard let row = rows.first else { 
				print("❌ [getMovement] No rows found for name \(movementId)")
				return nil 
			}
			print("✅ [getMovement] Found movement: \(row.name)")
			return mapRowsToMovements([row]).first
		}
	}

	private func mapRowsToMovements(_ rows: [LibraryMovementRow]) -> [Movement] {
		return rows.map { row in
			let vector = row.default_module_impact_vector ?? [:]
			let recovery = vector["recovery"] ?? 0.0
			let resilience = vector["resilience"] ?? 0.0
			let results = vector["results"] ?? 0.0
			
			// Extract impact vectors
			let sportImpacts = row.default_sport_impact_vector?.keys.map { String($0) } ?? []
			let goalImpacts = row.default_goal_impact_vector?.keys.map { String($0) } ?? []
			let bodyPartImpacts = row.default_body_part_impact_vector?.keys.map { String($0) } ?? []
			let superMetricImpacts = row.default_super_metric_impact_vector?.keys.map { String($0) } ?? []
			
			// Extract injury flags
			let injuryFlags = row.default_injury_flags ?? [:]
			let injuryIndications = injuryFlags["indication"] ?? []
			let injuryContraindications = injuryFlags["contraindication"] ?? []
			
			// Extract equipment IDs
			let equipmentIds = row.required_equipment ?? []
			
			return Movement(
				id: Self.stableIntId(from: row.id),
				name: row.name,
				description: "", // Description not available in movements table
				videoURL: row.video_url,
				jointsImpacted: [],
				musclesImpacted: [],
				superMetricsImpacted: superMetricImpacts,
				sportsImpacted: sportImpacts,
				intensityOptions: [],
				recoveryImpactScore: recovery,
				resilienceImpactScore: resilience,
				resultsImpactScore: results,
				requiredEquipment: equipmentIds.map { equipmentId in
					switch equipmentId {
					case .int(let value):
						return String(value)
					case .string(let stringValue):
						return stringValue
					}
				},
				goalImpacts: goalImpacts,
				bodyPartImpacts: bodyPartImpacts,
				injuryIndications: injuryIndications,
				injuryContraindications: injuryContraindications
			)
		}
	}
	
	/// Fetch a single movement with full details including equipment and impact names
	func getMovementWithDetails(byId movementId: String) async throws -> Movement? {
		print("🔍 [MovementLibraryService] Getting movement with details for ID: \(movementId)")
		
		guard let movement = try await getMovement(byId: movementId) else { 
			print("❌ [MovementLibraryService] No movement found for ID: \(movementId)")
			return nil 
		}
		
		print("✅ [MovementLibraryService] Found movement: \(movement.name)")
		print("📊 [MovementLibraryService] Movement data: equipment=\(movement.requiredEquipment), sports=\(movement.sportsImpacted), goals=\(movement.goalImpacts)")
		
		// Resolve IDs to names for better display
		return try await resolveMovementDetails(movement)
	}
	
	/// Fetch long description for a movement by name from public.movement_content
	func getMovementLongDescription(byName name: String) async throws -> String? {
		struct MovementContentRow: Decodable { let long_description: String? }
		struct MovementIdRow: Decodable { let id: DecodableId }
		
		do {
			// Join movements table with movement_content to get description by movement name
			// First get the movement_id from movements table
			let movementRows: [MovementIdRow] = try await supabase
				.from("movements")
				.select("id")
				.eq("name", value: name)
				.limit(1)
				.execute()
				.value
			
			guard let movementId = movementRows.first?.id else {
				print("Movement not found: \(name)")
				return nil
			}
			
			// Then get the content from movement_content using the movement_id
			// Extract the UUID string from the DecodableId
			let movementIdString: String
			switch movementId {
			case .int(let value):
				movementIdString = String(value)
			case .string(let uuidString):
				movementIdString = uuidString
			}
			
			let contentRows: [MovementContentRow] = try await supabase
				.from("movement_content")
				.select("long_description")
				.eq("movement_id", value: movementIdString)
				.limit(1)
				.execute()
				.value
			
			return contentRows.first?.long_description
		} catch {
			print("Error fetching movement content: \(error)")
			return nil
		}
	}
	
	private static func stableIntId(from id: DecodableId) -> Int {
		switch id {
		case .int(let value):
			return value
		case .string(let uuidString):
			var hasher = Hasher()
			hasher.combine(uuidString)
			let hash = hasher.finalize()
			return Int(bitPattern: UInt(bitPattern: hash))
		}
	}
	
	// MARK: - Lookup Methods
	
	/// Get equipment names from equipment IDs
	private func getEquipmentNames(from ids: [String]) async throws -> [String] {
		guard !ids.isEmpty else { return [] }
		
		// Convert string IDs to integers for database query
		let intIds = ids.compactMap { Int($0) }
		guard !intIds.isEmpty else { return [] }
		
		let rows: [EquipmentRow] = try await supabase
			.from("equipment")
			.select("id,name")
			.in("id", values: intIds)
			.execute()
			.value
		
		return rows.map { $0.name }
	}
	
	/// Get sport names from sport IDs
	private func getSportNames(from ids: [String]) async throws -> [String] {
		guard !ids.isEmpty else { return [] }
		
		// Convert string IDs to integers for database query
		let intIds = ids.compactMap { Int($0) }
		guard !intIds.isEmpty else { return [] }
		
		let rows: [SportRow] = try await supabase
			.from("sports")
			.select("id,name")
			.in("id", values: intIds)
			.execute()
			.value
		
		return rows.map { $0.name }
	}
	
	/// Get goal names from goal IDs
	private func getGoalNames(from ids: [String]) async throws -> [String] {
		guard !ids.isEmpty else { return [] }
		
		// Convert string IDs to integers for database query
		let intIds = ids.compactMap { Int($0) }
		guard !intIds.isEmpty else { return [] }
		
		let rows: [GoalRow] = try await supabase
			.from("goals")
			.select("id,name")
			.in("id", values: intIds)
			.execute()
			.value
		
		return rows.map { $0.name }
	}
	
	/// Get body part names from body part IDs
	private func getBodyPartNames(from ids: [String]) async throws -> [String] {
		guard !ids.isEmpty else { return [] }
		
		// Convert string IDs to integers for database query
		let intIds = ids.compactMap { Int($0) }
		guard !intIds.isEmpty else { return [] }
		
		let rows: [BodyPartRow] = try await supabase
			.from("body_parts")
			.select("id,body_part")
			.in("id", values: intIds)
			.execute()
			.value
		
		return rows.map { $0.name }
	}
	
	/// Get injury names from injury IDs
	private func getInjuryNames(from ids: [String]) async throws -> [String] {
		guard !ids.isEmpty else { return [] }
		
		// Convert string IDs to integers for database query
		let intIds = ids.compactMap { Int($0) }
		guard !intIds.isEmpty else { return [] }
		
		let rows: [InjuryRow] = try await supabase
			.from("injuries")
			.select("id,name")
			.in("id", values: intIds)
			.execute()
			.value
		
		return rows.map { $0.name }
	}
	
	/// Get super metric names from super metric IDs
	private func getSuperMetricNames(from ids: [String]) async throws -> [String] {
		guard !ids.isEmpty else { return [] }
		
		// Convert string IDs to integers for database query
		let intIds = ids.compactMap { Int($0) }
		guard !intIds.isEmpty else { return [] }
		
		let rows: [SuperMetricRow] = try await supabase
			.from("super_metrics")
			.select("id,name")
			.in("id", values: intIds)
			.execute()
			.value
		
		return rows.map { $0.name }
	}
	
	/// Resolve movement detail IDs to names for better display
	private func resolveMovementDetails(_ movement: Movement) async throws -> Movement {
		// Convert equipment IDs to names
		let equipmentNames = try await getEquipmentNames(from: movement.requiredEquipment)
		
		// Convert goal IDs to names
		let goalNames = try await getGoalNames(from: movement.goalImpacts)
		
		// Convert body part IDs to names
		let bodyPartNames = try await getBodyPartNames(from: movement.bodyPartImpacts)
		
		// Convert super metric IDs to names
		let superMetricNames = try await getSuperMetricNames(from: movement.superMetricsImpacted)
		
		// Convert sport IDs to names
		let sportNames = try await getSportNames(from: movement.sportsImpacted)
		
		// Create new movement with resolved names
		return Movement(
			id: movement.id,
			name: movement.name,
			description: movement.description,
			videoURL: movement.videoURL,
			jointsImpacted: movement.jointsImpacted,
			musclesImpacted: movement.musclesImpacted,
			superMetricsImpacted: superMetricNames,
			sportsImpacted: sportNames,
			intensityOptions: movement.intensityOptions,
			recoveryImpactScore: movement.recoveryImpactScore,
			resilienceImpactScore: movement.resilienceImpactScore,
			resultsImpactScore: movement.resultsImpactScore,
			requiredEquipment: equipmentNames,
			goalImpacts: goalNames,
			bodyPartImpacts: bodyPartNames,
			injuryIndications: movement.injuryIndications,
			injuryContraindications: movement.injuryContraindications
		)
	}
	
	// MARK: - Helper Structs
	
	private struct EquipmentRow: Codable {
		let id: Int
		let name: String
	}
	
	private struct SportRow: Codable {
		let id: Int
		let name: String
	}
	
	private struct GoalRow: Codable {
		let id: Int
		let name: String
	}
	
	private struct BodyPartRow: Codable {
		let id: Int
		let name: String
		
		enum CodingKeys: String, CodingKey {
			case id
			case name = "body_part"
		}
	}
	
	private struct InjuryRow: Codable {
		let id: Int
		let name: String
	}
	
	private struct SuperMetricRow: Codable {
		let id: Int
		let name: String
	}
}
