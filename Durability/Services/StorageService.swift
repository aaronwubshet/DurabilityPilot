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
    
    // MARK: - Assessment Video Upload (Private Bucket)
    
    /// Uploads assessment video to private bucket with user-specific organization
    func uploadAssessmentVideo(
        from fileURL: URL,
        profileId: String,
        assessmentId: String,
        fileName: String? = nil
    ) async throws -> String {
        let videoData: Data
        do {
            videoData = try Data(contentsOf: fileURL)
        } catch {
            throw StorageError.invalidFileURL
        }
        
        // Validate file size (10MB limit as per your config)
        let maxSize: Int64 = 10 * 1024 * 1024 // 10MB
        if Int64(videoData.count) > maxSize {
            throw StorageError.uploadFailed(NSError(domain: "StorageError", code: 413, userInfo: [NSLocalizedDescriptionKey: "Video file too large. Maximum size is 10MB."]))
        }
        
        // Create organized file path: profileId/assessmentId/filename
        let finalFileName = fileName ?? "\(UUID().uuidString).mp4"
        let filePath = "\(profileId)/\(assessmentId)/\(finalFileName)"
        
        do {
            // Upload to private assessment-videos bucket
            _ = try await supabase.storage
                .from("assessment-videos")
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
            print("Video upload failed: \(error)")
            throw StorageError.uploadFailed(error)
        }
    }
    
    /// Gets a signed URL for accessing a private assessment video
    /// This allows temporary access to the video without making the bucket public
    func getSignedVideoURL(filePath: String, expiresIn seconds: Int = 3600) async throws -> String {
        do {
            let signedURL = try await supabase.storage
                .from("assessment-videos")
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
                .from("assessment-videos")
                .remove(paths: [filePath])
        } catch {
            throw StorageError.uploadFailed(error)
        }
    }

    // MARK: - General Video Upload (Legacy - keeping for backward compatibility)
    
    func uploadVideo(
        from fileURL: URL,
        bucket: String,
        fileName: String? = nil,
        makeSignedURL: Bool = true,
        signedURLExpiresIn seconds: Int = 60 * 60
    ) async throws -> String {
        let videoData: Data
        do {
            videoData = try Data(contentsOf: fileURL)
        } catch {
            throw StorageError.invalidFileURL
        }

        let finalFileName = fileName ?? "\(UUID().uuidString).mp4"
        let filePath = "\(finalFileName)"

        do {
            _ = try await supabase.storage
                .from(bucket)
                .upload(
                    filePath,
                    data: videoData,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: "video/mp4"
                    )
                )

            if makeSignedURL {
                let signed = try await supabase.storage
                    .from(bucket)
                    .createSignedURL(path: filePath, expiresIn: seconds)
                return signed.absoluteString
            } else {
                // Return storage path for later server-side signing
                return filePath
            }

        } catch {
            throw StorageError.uploadFailed(error)
        }
    }

    func uploadImage(from data: Data?, bucket: String, fileName: String? = nil) async throws -> String {
        guard let imageData = data else {
            throw StorageError.noData
        }

        let finalFileName = fileName ?? "\(UUID().uuidString).jpg"
        let filePath = "\(finalFileName)"
        
        do {
            _ = try await supabase.storage
                .from(bucket)
                .upload(filePath, data: imageData, options: FileOptions(cacheControl: "3600"))
            
            let urlResponse = try supabase.storage
                .from(bucket)
                .getPublicURL(path: filePath)

            return urlResponse.absoluteString
        } catch {
             throw StorageError.uploadFailed(error)
        }
    }
}

