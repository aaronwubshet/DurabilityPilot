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
		let description: String?
		let video_url: String?
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
		// Select only columns we know exist to avoid server errors if optional columns differ
		let rows: [LibraryMovementRow] = try await supabase
			.from("movements")
			.select("id,name,default_module_impact_vector")
			.order("name", ascending: true)
			.execute()
			.value
		return mapRowsToMovements(rows)
	}

	private func mapRowsToMovements(_ rows: [LibraryMovementRow]) -> [Movement] {
		return rows.map { row in
			let vector = row.default_module_impact_vector ?? [:]
			let recovery = vector["recovery"] ?? 0.0
			let resilience = vector["resilience"] ?? 0.0
			let results = vector["results"] ?? 0.0
			return Movement(
				id: Self.stableIntId(from: row.id),
				name: row.name,
				description: row.description ?? "",
				videoURL: row.video_url,
				jointsImpacted: [],
				musclesImpacted: [],
				superMetricsImpacted: [],
				sportsImpacted: [],
				intensityOptions: [],
				recoveryImpactScore: recovery,
				resilienceImpactScore: resilience,
				resultsImpactScore: results
			)
		}
	}
	
	/// Fetch long description for a movement by name from public.movement_content
	func getMovementLongDescription(byName name: String) async throws -> String? {
		struct MovementContentRow: Decodable { let long_description: String? }
		// Use OR filter to support both name and movement_name
		let orFilter = "name.eq.\(name),movement_name.eq.\(name)"
		do {
			let rows: [MovementContentRow] = try await supabase
				.from("movement_content")
				.select("long_description")
				.or(orFilter)
				.limit(1)
				.execute()
				.value
			return rows.first?.long_description
		} catch {
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
}
