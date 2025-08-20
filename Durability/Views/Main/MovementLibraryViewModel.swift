import Foundation
import SwiftUI

@MainActor
class MovementLibraryViewModel: ObservableObject {
	@Published var searchText: String = ""
	@Published var selectedFilters: [String] = []
	@Published var movements: [Movement] = []
	@Published var isLoading: Bool = false
	@Published var errorMessage: String?
	
	private let service = MovementLibraryService()
	
	func fetch() async {
		isLoading = true
		errorMessage = nil
		do {
			let items = try await service.getAllMovements()
			self.movements = items
		} catch {
			self.errorMessage = error.localizedDescription
		}
		isLoading = false
	}
	
	var filteredMovements: [Movement] {
		movements.filter { movement in
			searchText.isEmpty || movement.name.localizedCaseInsensitiveContains(searchText)
		}
	}
}
