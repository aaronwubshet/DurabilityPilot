import Foundation
import Supabase

@MainActor
class AssessmentService: ObservableObject {
    private let supabase = SupabaseManager.shared.client
    private let networkService = NetworkService()
    
    /// Creates an assessment record and uploads the video to private bucket
    func createAssessmentWithVideo(
        profileId: String,
        videoURL: URL
    ) async throws -> Assessment {
        // Debug: Check current session before database operation
        do {
            _ = try await self.supabase.auth.session
        } catch {
            throw AssessmentError.failedToCreate
        }
        
        // Upload video to private bucket first
        let videoFilePath = try await uploadVideoToPrivateBucket(
            videoURL: videoURL,
            profileId: profileId
        )
        
        // Create assessment record with video URL (don't provide assessment_id - let DB generate it)
        let assessment = Assessment(
            assessmentId: nil, // Let database auto-generate this
            profileId: profileId,
            videoURL: videoFilePath,
            createdAt: Date()
        )
        
        // Insert assessment record - let database generate the assessment_id
        
        let result = await networkService.performWithRetry(
            operation: {
                let response: [Assessment] = try await self.supabase
                    .from("assessments")
                    .insert(assessment)
                    .select()
                    .execute()
                    .value
                
                guard let createdAssessment = response.first else {
                    throw AssessmentError.failedToCreate
                }
                
                return createdAssessment
            },
            operationName: "Create Assessment with Video"
        )
        
        switch result {
        case .success(let createdAssessment):
            return createdAssessment
        case .failure(let error, _, _):
            throw error
        case .noConnection:
            throw AssessmentError.failedToCreate
        }
    }
    
    /// Creates an assessment record without video
    func createAssessmentWithoutVideo(profileId: String) async throws -> Assessment {
        let assessment = Assessment(
            assessmentId: nil, // Let database auto-generate this
            profileId: profileId,
            videoURL: nil,
            createdAt: Date()
        )
        
        let result = await networkService.performWithRetry(
            operation: {
                let response: [Assessment] = try await self.supabase
                    .from("assessments")
                    .insert(assessment)
                    .select()
                    .execute()
                    .value
                
                guard let createdAssessment = response.first else {
                    throw AssessmentError.failedToCreate
                }
                
                return createdAssessment
            },
            operationName: "Create Assessment without Video"
        )
        
        switch result {
        case .success(let createdAssessment):
            return createdAssessment
        case .failure(let error, _, _):
            throw error
        case .noConnection:
            throw AssessmentError.failedToCreate
        }
    }
    
    /// Uploads video to private bucket and returns the file path
    private func uploadVideoToPrivateBucket(
        videoURL: URL,
        profileId: String
    ) async throws -> String {
        // Use the StorageService method for private bucket uploads
        let storageService = StorageService()
        return try await storageService.uploadAssessmentVideo(
            from: videoURL,
            profileId: profileId
        )
    }
    
    /// Updates existing assessment results for a retake
    func updateAssessmentResults(
        assessmentId: Int,
        results: [AssessmentResult]
    ) async throws {
        // First, delete existing results for this assessment
        try await self.supabase
            .from("assessment_results")
            .delete()
            .eq("assessment_id", value: assessmentId)
            .execute()
        
        // Then insert the new results
        try await self.supabase
            .from("assessment_results")
            .insert(results)
            .execute()
    }
    
    /// Gets the most recent assessment for a user
    func getLatestAssessment(profileId: String) async throws -> Assessment? {
        let result = await networkService.performWithRetry(
            operation: {
                let response: [Assessment] = try await self.supabase
                    .from("assessments")
                    .select("*")
                    .eq("profile_id", value: profileId)
                    .order("created_at", ascending: false)
                    .limit(1)
                    .execute()
                    .value
                
                return response.first
            },
            operationName: "Get Latest Assessment"
        )
        
        switch result {
        case .success(let assessment):
            return assessment
        case .failure(let error, _, _):
            throw error
        case .noConnection:
            throw AssessmentError.failedToCreate
        }
    }
    
    /// Creates assessment results for a specific assessment
    func createAssessmentResults(
        assessmentId: Int,
        results: [AssessmentResult]
    ) async throws {
        // Insert all assessment results
        
        let result = await networkService.performWithRetry(
            operation: {
                try await self.supabase
                    .from("assessment_results")
                    .insert(results)
                    .execute()
            },
            operationName: "Create Assessment Results"
        )
        
        switch result {
        case .success:
            break
        case .failure(let error, _, _):
            throw error
        case .noConnection:
            throw AssessmentError.failedToCreate
        }
    }
    
    /// Gets a signed URL for viewing a private assessment video
    func getVideoSignedURL(videoPath: String) async throws -> String {
        let storageService = StorageService()
        return try await storageService.getSignedVideoURL(filePath: videoPath)
    }
    
    /// Deletes an assessment video from private bucket
    func deleteAssessmentVideo(videoPath: String) async throws {
        let storageService = StorageService()
        try await storageService.deleteAssessmentVideo(filePath: videoPath)
    }
    
    func getAssessmentHistory(profileId: String) async throws -> [Assessment] {
        let result = await networkService.performWithRetry(
            operation: {
                let response: [Assessment] = try await self.supabase
                    .from("assessments")
                    .select("*")
                    .eq("profile_id", value: profileId)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
                
                return response
            },
            operationName: "Get Assessment History"
        )
        
        switch result {
        case .success(let assessments):
            return assessments
        case .failure(let error, _, _):
            throw error
        case .noConnection:
            throw AssessmentError.failedToCreate
        }
    }
    
    func getAssessmentResults(assessmentId: Int) async throws -> [AssessmentResult] {
        let result = await networkService.performWithRetry(
            operation: {
                let response: [AssessmentResult] = try await self.supabase
                    .from("assessment_results")
                    .select("*")
                    .eq("assessment_id", value: assessmentId)
                    .execute()
                    .value
                
                return response
            },
            operationName: "Get Assessment Results"
        )
        
        switch result {
        case .success(let results):
            return results
        case .failure(let error, _, _):
            throw error
        case .noConnection:
            throw AssessmentError.failedToCreate
        }
    }
}

enum AssessmentError: Error, LocalizedError {
    case failedToCreate
    case failedToUpload
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .failedToCreate:
            return "Failed to create assessment record"
        case .failedToUpload:
            return "Failed to upload assessment video"
        case .invalidData:
            return "Invalid assessment data"
        }
    }
}
