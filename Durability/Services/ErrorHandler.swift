import Foundation
import Supabase

/// Centralized error handling for the app
class ErrorHandler {
    
    /// Maps Supabase errors to user-friendly messages
    static func userFriendlyMessage(for error: Error) -> String {
        if let supabaseError = error as? PostgrestError {
            return mapSupabaseError(supabaseError)
        } else if let authError = error as? AuthError {
            return mapAuthError(authError)
        } else if let storageError = error as? StorageService.StorageError {
            return mapStorageError(storageError)
        } else {
            return error.localizedDescription
        }
    }
    
    /// Maps Supabase Postgrest errors to user-friendly messages
    private static func mapSupabaseError(_ error: PostgrestError) -> String {
        switch error.code {
        case "PGRST100":
            return "Invalid data format. Please try again."
        case "PGRST116":
            return "You don't have permission to access this data"
        case "PGRST301":
            return "The requested data was not found"
        case "PGRST302":
            return "The data already exists"
        case "PGRST303":
            return "Invalid data provided"
        case "PGRST304":
            return "Database connection error"
        case "PGRST305":
            return "Request timeout"
        case "PGRST306":
            return "Too many requests. Please try again later"
        case "PGRST307":
            return "Service temporarily unavailable"
        case "PGRST308":
            return "Invalid request format"
        case "PGRST309":
            return "Database constraint violation"
        default:
            return "Database error: \(error.message)"
        }
    }
    
    /// Maps Supabase Auth errors to user-friendly messages
    private static func mapAuthError(_ error: AuthError) -> String {
        // Use the error description directly to avoid compilation issues
        let errorMessage = error.localizedDescription.lowercased()
        
        if errorMessage.contains("invalid") && errorMessage.contains("credential") {
            return "Invalid email or password"
        } else if errorMessage.contains("email") && errorMessage.contains("confirm") {
            return "Please confirm your email address"
        } else if errorMessage.contains("weak") && errorMessage.contains("password") {
            return "Password is too weak"
        } else if errorMessage.contains("email") && errorMessage.contains("use") {
            return "An account with this email already exists"
        } else if errorMessage.contains("invalid") && errorMessage.contains("email") {
            return "Please enter a valid email address"
        } else if errorMessage.contains("too many") || errorMessage.contains("rate limit") {
            return "Too many attempts. Please try again later"
        } else if errorMessage.contains("network") {
            return "Network connection error"
        } else if errorMessage.contains("token") && errorMessage.contains("expired") {
            return "Session expired. Please sign in again"
        } else if errorMessage.contains("invalid") && errorMessage.contains("token") {
            return "Invalid session. Please sign in again"
        } else {
            return "Authentication error: \(error.localizedDescription)"
        }
    }
    
    /// Maps custom Storage errors to user-friendly messages
    private static func mapStorageError(_ error: StorageService.StorageError) -> String {
        switch error {
        case .bucketNotFound:
            return "Storage bucket not found"
        case .unauthorized:
            return "You don't have permission to access this file"
        case .uploadFailed(let underlyingError):
            return "Upload failed: \(underlyingError.localizedDescription)"
        case .invalidFileURL:
            return "Invalid file format"
        case .noData:
            return "No file data provided"
        }
    }
    
    /// Logs errors for debugging
    static func logError(_ error: Error, context: String) {
        // Error logging removed for cleaner console output
    }
    
    /// Determines if an error is recoverable
    static func isRecoverable(_ error: Error) -> Bool {
        if let supabaseError = error as? PostgrestError {
            // Network errors and timeouts are recoverable
            return supabaseError.code == "PGRST304" || 
                   supabaseError.code == "PGRST305" ||
                   supabaseError.code == "PGRST307"
        }
        
        if let authError = error as? AuthError {
            // Most auth errors are not recoverable without user action
            let errorMessage = authError.localizedDescription.lowercased()
            return errorMessage.contains("network") ||
                   errorMessage.contains("timeout")
        }
        
        // Network errors are generally recoverable
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return nsError.code == NSURLErrorNetworkConnectionLost ||
                   nsError.code == NSURLErrorTimedOut ||
                   nsError.code == NSURLErrorCannotConnectToHost ||
                   nsError.code == NSURLErrorNotConnectedToInternet
        }
        
        return false
    }
    
    /// Categorizes errors for different handling strategies
    static func categorizeError(_ error: Error) -> ErrorCategory {
        if let supabaseError = error as? PostgrestError {
            switch supabaseError.code {
            case "PGRST116":
                return .permission
            case "PGRST301":
                return .notFound
            case "PGRST302":
                return .conflict
            case "PGRST303":
                return .validation
            case "PGRST304", "PGRST305", "PGRST307":
                return .network
            case "PGRST306":
                return .rateLimit
            default:
                return .unknown
            }
        }
        
        if let authError = error as? AuthError {
            let errorMessage = authError.localizedDescription.lowercased()
            if errorMessage.contains("token") || errorMessage.contains("session") {
                return .authentication
            } else if errorMessage.contains("network") {
                return .network
            } else {
                return .validation
            }
        }
        
        return .unknown
    }
}

enum ErrorCategory {
    case network
    case authentication
    case permission
    case validation
    case notFound
    case conflict
    case rateLimit
    case unknown
}
