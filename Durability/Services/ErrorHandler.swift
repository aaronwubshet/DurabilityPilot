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
        } else {
            return error.localizedDescription
        }
    }
    
    /// Maps Supabase Postgrest errors to user-friendly messages
    private static func mapSupabaseError(_ error: PostgrestError) -> String {
        switch error.code {
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
        } else {
            return "Authentication error: \(error.localizedDescription)"
        }
    }
    
    /// Logs errors for debugging
    static func logError(_ error: Error, context: String) {
        print("\(context): \(error.localizedDescription)")
        
        #if DEBUG
        if let supabaseError = error as? PostgrestError {
            print("Supabase Error Code: \(supabaseError.code)")
            print("Supabase Error Message: \(supabaseError.message)")
        }
        #endif
    }
    
    /// Determines if an error is recoverable
    static func isRecoverable(_ error: Error) -> Bool {
        if let supabaseError = error as? PostgrestError {
            // Network errors and timeouts are recoverable
            return supabaseError.code == "PGRST304" || supabaseError.code == "PGRST305"
        }
        
        if let authError = error as? AuthError {
            // Most auth errors are not recoverable without user action
            let errorMessage = authError.localizedDescription.lowercased()
            return errorMessage.contains("network")
        }
        
        return false
    }
}
