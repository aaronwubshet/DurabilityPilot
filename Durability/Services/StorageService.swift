import Foundation
import Supabase

@MainActor
class StorageService {
    private let supabase = SupabaseManager.shared.client

    enum StorageError: Error {
        case uploadFailed(Error)
        case invalidFileURL
        case noData
    }

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

