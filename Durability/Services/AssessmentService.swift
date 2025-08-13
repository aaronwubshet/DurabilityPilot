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
        print("🔍 AssessmentService.createAssessmentWithVideo() - Starting")
        print("   - profileId: \(profileId)")
        print("   - videoURL: \(videoURL)")
        print("   - This creates a new assessment record (works for both initial and retake)")
        
        // Debug: Check current session before database operation
        do {
            let session = try await self.supabase.auth.session
            print("✅ AssessmentService: Session verified before database operation")
            print("   - Session user ID: \(session.user.id.uuidString)")
            print("   - Profile ID matches session: \(session.user.id.uuidString == profileId)")
        } catch {
            print("❌ AssessmentService: No valid session found: \(error)")
            throw AssessmentError.failedToCreate
        }
        
        // Upload video to private bucket first
        print("🔍 Uploading video to private bucket...")
        let videoFilePath = try await uploadVideoToPrivateBucket(
            videoURL: videoURL,
            profileId: profileId
        )
        print("✅ Video uploaded successfully to: \(videoFilePath)")
        
        // Create assessment record with video URL (don't provide assessment_id - let DB generate it)
        let assessment = Assessment(
            assessmentId: nil, // Let database auto-generate this
            profileId: profileId,
            videoURL: videoFilePath,
            createdAt: Date()
        )
        
        print("🔍 Created assessment object:")
        print("   - assessmentId: \(assessment.assessmentId?.description ?? "nil")")
        print("   - profileId: \(assessment.profileId)")
        print("   - videoURL: \(assessment.videoURL?.description ?? "nil")")
        
        // Insert assessment record - let database generate the assessment_id
        print("🔍 Writing to assessments table in Supabase...")
        
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
            print("✅ Successfully created assessment with ID: \(createdAssessment.assessmentId ?? -1)")
            print("   - Generated assessmentId: \(createdAssessment.assessmentId?.description ?? "nil")")
            print("   - Generated assessmentId type: \(type(of: createdAssessment.assessmentId))")
            return createdAssessment
        case .failure(let error, _, _):
            print("❌ Failed to create assessment record: \(error)")
            throw error
        case .noConnection:
            throw AssessmentError.failedToCreate
        }
    }
    
    /// Creates an assessment record without video
    func createAssessmentWithoutVideo(profileId: String) async throws -> Assessment {
        print("🔍 AssessmentService.createAssessmentWithoutVideo() - Starting")
        print("   - profileId: \(profileId)")
        print("   - This creates a new assessment record (works for both initial and retake)")
        
        let assessment = Assessment(
            assessmentId: nil, // Let database auto-generate this
            profileId: profileId,
            videoURL: nil,
            createdAt: Date()
        )
        
        print("🔍 Created assessment object:")
        print("   - assessmentId: \(assessment.assessmentId?.description ?? "nil")")
        print("   - profileId: \(assessment.profileId)")
        print("   - videoURL: \(assessment.videoURL?.description ?? "nil")")
        
        print("🔍 Writing to assessments table in Supabase...")
        
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
            print("✅ Successfully created assessment with ID: \(createdAssessment.assessmentId ?? -1)")
            print("   - Generated assessmentId: \(createdAssessment.assessmentId?.description ?? "nil")")
            print("   - Generated assessmentId type: \(type(of: createdAssessment.assessmentId))")
            return createdAssessment
        case .failure(let error, _, _):
            print("❌ Failed to create assessment record: \(error)")
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
        print("🔍 AssessmentService.createAssessmentResults() - Starting")
        print("   - assessmentId: \(assessmentId)")
        print("   - results count: \(results.count)")
        print("   - assessmentId type: \(type(of: assessmentId))")
        print("   - This creates new assessment results (works for both initial and retake)")
        
        // Debug: Print the exact data being sent
        print("🔍 Data being sent to assessment_results table:")
        for (index, result) in results.enumerated() {
            print("   Result \(index + 1):")
            print("     - assessment_id: \(result.assessmentId) (type: \(type(of: result.assessmentId)))")
            print("     - profile_id: \(result.profileId) (type: \(type(of: result.profileId)))")
            print("     - body_area: \(result.bodyArea) (type: \(type(of: result.bodyArea)))")
            print("     - durability_score: \(result.durabilityScore) (type: \(type(of: result.durabilityScore)))")
            print("     - flexibility_score: \(result.flexibilityScore) (type: \(type(of: result.flexibilityScore)))")
            print("     - functional_strength_score: \(result.functionalStrengthScore) (type: \(type(of: result.functionalStrengthScore)))")
            print("     - mobility_score: \(result.mobilityScore) (type: \(type(of: result.mobilityScore)))")
            print("     - range_of_motion_score: \(result.rangeOfMotionScore) (type: \(type(of: result.rangeOfMotionScore)))")
            print("     - aerobic_capacity_score: \(result.aerobicCapacityScore) (type: \(type(of: result.aerobicCapacityScore)))")
        }
        
        // Insert all assessment results
        print("🔍 Writing to assessment_results table in Supabase...")
        
        let result = await networkService.performWithRetry(
            operation: {
                print("🔍 Using authenticated user session...")
                
                // Debug: Check current user session
                if let user = try? await self.supabase.auth.session.user {
                    print("   - Current user ID: \(user.id)")
                    print("   - User email: \(user.email ?? "no email")")
                } else {
                    print("   ❌ No authenticated user found!")
                }
                
                // Debug: Check if we can access the assessment_results table
                print("🔍 Testing table access...")
                do {
                    let testQuery: [AssessmentResult] = try await self.supabase
                        .from("assessment_results")
                        .select("*")
                        .limit(1)
                        .execute()
                        .value
                    print("   ✅ Can access assessment_results table, found \(testQuery.count) existing records")
                } catch {
                    print("   ❌ Cannot access assessment_results table: \(error)")
                }
                
                // Insert all results at once
                print("🔍 Inserting all \(results.count) results...")
                try await self.supabase
                    .from("assessment_results")
                    .insert(results)
                    .execute()
            },
            operationName: "Create Assessment Results"
        )
        
        switch result {
        case .success:
            print("✅ Successfully wrote \(results.count) results to assessment_results table")
        case .failure(let error, _, _):
            print("❌ Failed to create assessment results: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error details: \(error.localizedDescription)")
            if let postgrestError = error as? PostgrestError {
                print("❌ PostgrestError code: \(postgrestError.code ?? "nil")")
                print("❌ PostgrestError message: \(postgrestError.message)")
            }
            throw error
        case .noConnection:
            print("❌ No network connection available")
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
