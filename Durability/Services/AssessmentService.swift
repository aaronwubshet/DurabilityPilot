import Foundation
import Supabase

@MainActor
class AssessmentService: ObservableObject {
    private let supabase = SupabaseManager.shared.client
    
    /// Creates an assessment record and uploads the video to private bucket
    func createAssessmentWithVideo(
        profileId: String,
        videoURL: URL
    ) async throws -> Assessment {
        // First, create the assessment record
        let assessmentId = UUID().uuidString
        let assessment = Assessment(
            id: assessmentId,
            profileId: profileId,
            videoURL: nil, // Will be updated after video upload
            createdAt: Date()
        )
        
        // Insert assessment record
        try await supabase
            .from("assessments")
            .insert(assessment)
            .execute()
        
        // Upload video to private bucket
        let videoFilePath = try await uploadVideoToPrivateBucket(
            videoURL: videoURL,
            profileId: profileId,
            assessmentId: assessmentId
        )
        
        // Update assessment with video path
        try await supabase
            .from("assessments")
            .update(["video_url": videoFilePath])
            .eq("id", value: assessmentId)
            .execute()
        
        // Return updated assessment
        var updatedAssessment = assessment
        updatedAssessment.videoURL = videoFilePath
        return updatedAssessment
    }
    
    /// Uploads video to private bucket and returns the file path
    private func uploadVideoToPrivateBucket(
        videoURL: URL,
        profileId: String,
        assessmentId: String
    ) async throws -> String {
        // Use the new StorageService method for private bucket uploads
        let storageService = StorageService()
        return try await storageService.uploadAssessmentVideo(
            from: videoURL,
            profileId: profileId,
            assessmentId: assessmentId
        )
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
    
    // MARK: - Legacy Methods (keeping for backward compatibility)
    
    func createAssessment(profileId: String, videoURL: String?) async throws -> Assessment {
        let assessment = Assessment(
            id: UUID().uuidString,
            profileId: profileId,
            videoURL: videoURL,
            createdAt: Date()
        )
        
        try await supabase
            .from("assessments")
            .insert(assessment)
            .execute()
        
        return assessment
    }
    
    func generateAssessmentResults(assessmentId: String) async throws -> [AssessmentResult] {
        // For now, generate random scores
        // In a real implementation, this would use AI/ML to analyze the video
        
        let bodyAreas = ["Overall", "Shoulder", "Torso", "Hips", "Knees", "Ankles", "Elbows"]
        var results: [AssessmentResult] = []
        
        for area in bodyAreas {
            let result = AssessmentResult(
                id: UUID().uuidString,
                assessmentId: assessmentId,
                bodyArea: area,
                durabilityScore: Double.random(in: 0.6...0.9),
                rangeOfMotionScore: Double.random(in: 0.5...0.9),
                flexibilityScore: Double.random(in: 0.4...0.8),
                functionalStrengthScore: Double.random(in: 0.6...0.9),
                mobilityScore: Double.random(in: 0.5...0.8),
                aerobicCapacityScore: Double.random(in: 0.7...0.9)
            )
            results.append(result)
        }
        
        // Save results to database
        try await supabase
            .from("assessment_results")
            .insert(results)
            .execute()
        
        return results
    }
    
    func getAssessmentHistory(profileId: String) async throws -> [Assessment] {
        let response: [Assessment] = try await supabase
            .from("assessments")
            .select("*")
            .eq("profile_id", value: profileId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    func getAssessmentResults(assessmentId: String) async throws -> [AssessmentResult] {
        let response: [AssessmentResult] = try await supabase
            .from("assessment_results")
            .select("*")
            .eq("assessment_id", value: assessmentId)
            .execute()
            .value
        
        return response
    }
}
