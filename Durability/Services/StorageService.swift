import Foundation
import Supabase

@MainActor
class StorageService {
    private let supabase = SupabaseManager.shared.client

    enum StorageError: Error {
        case uploadFailed(Error)
        case invalidFileURL
        case noData
        case bucketNotFound
        case unauthorized
    }
    
    /// Uploads assessment video to private bucket with user-specific organization (simple version)
    func uploadAssessmentVideo(
        from fileURL: URL,
        profileId: String,
        fileName: String? = nil
    ) async throws -> String {
        let videoData: Data
        do {
            videoData = try Data(contentsOf: fileURL)
        } catch {
            throw StorageError.invalidFileURL
        }
        
        // Create organized file path: profileId/filename (same pattern as training plan images)
        let finalFileName = fileName ?? "\(UUID().uuidString).mp4"
        let filePath = "\(profileId)/\(finalFileName)"
        
        do {
            // Upload to private assessment-videos bucket
            _ = try await supabase.storage
                .from(Config.assessmentVideosBucket)
                .upload(
                    filePath,
                    data: videoData,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: "video/mp4"
                    )
                )
            
            // Return the storage path (not public URL since bucket is private)
            // This path will be stored in the database and used for later access
            return filePath
            
        } catch {
            throw StorageError.uploadFailed(error)
        }
    }
    
    /// Gets a signed URL for accessing a private assessment video
    /// This allows temporary access to the video without making the bucket public
    func getSignedVideoURL(filePath: String, expiresIn seconds: Int = 3600) async throws -> String {
        do {
            let signedURL = try await supabase.storage
                .from(Config.assessmentVideosBucket)
                .createSignedURL(path: filePath, expiresIn: seconds)
            return signedURL.absoluteString
        } catch {
            throw StorageError.uploadFailed(error)
        }
    }
    
    /// Deletes an assessment video from the private bucket
    func deleteAssessmentVideo(filePath: String) async throws {
        do {
            try await supabase.storage
                .from(Config.assessmentVideosBucket)
                .remove(paths: [filePath])
        } catch {
            throw StorageError.uploadFailed(error)
        }
    }

    // MARK: - Training Plan Image Upload (Private Bucket)
    
    /// Uploads training plan image to private bucket with user-specific organization
    func uploadTrainingPlanImage(
        from data: Data?,
        profileId: String,
        fileName: String? = nil
    ) async throws -> String {
        guard let imageData = data else {
            throw StorageError.noData
        }
        
        // Create organized file path: profileId/filename
        let finalFileName = fileName ?? "\(UUID().uuidString).jpg"
        let filePath = "\(profileId)/\(finalFileName)"
        
        do {
            // Upload to private training-plan-images bucket
            _ = try await supabase.storage
                .from(Config.trainingPlanImagesBucket)
                .upload(
                    filePath,
                    data: imageData,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: "image/jpeg"
                    )
                )
            
            // Return the storage path (not public URL since bucket is private)
            // This path will be stored in the database and used for later access
            return filePath
            
        } catch {
            throw StorageError.uploadFailed(error)
        }
    }
    
    /// Gets a signed URL for accessing a private training plan image
    /// This allows temporary access to the image without making the bucket public
    func getSignedTrainingPlanImageURL(filePath: String, expiresIn seconds: Int = 3600) async throws -> String {
        do {
            let signedURL = try await supabase.storage
                .from(Config.trainingPlanImagesBucket)
                .createSignedURL(path: filePath, expiresIn: seconds)
            return signedURL.absoluteString
        } catch {
            throw StorageError.uploadFailed(error)
        }
    }
    
    /// Deletes a training plan image from the private bucket
    func deleteTrainingPlanImage(filePath: String) async throws {
        do {
            try await supabase.storage
                .from(Config.trainingPlanImagesBucket)
                .remove(paths: [filePath])
        } catch {
            throw StorageError.uploadFailed(error)
        }
    }
}

