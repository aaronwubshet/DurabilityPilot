import Foundation
import Network
import Combine
import Supabase

/// Centralized network service for handling connectivity, retries, and resilience
@MainActor
class NetworkService: ObservableObject {
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    init() {
        startMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(path) ?? .unknown
            }
        }
        monitor.start(queue: queue)
    }
    
    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
}

/// Retry configuration for network operations
struct RetryConfig {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let backoffMultiplier: Double
    
    static let `default` = RetryConfig(
        maxAttempts: 3,
        baseDelay: 1.0,
        maxDelay: 10.0,
        backoffMultiplier: 2.0
    )
}

/// Network operation result with retry information
enum NetworkResult<T> {
    case success(T)
    case failure(Error, attempt: Int, maxAttempts: Int)
    case noConnection
}

/// Extension for retry logic
extension NetworkService {
    
    /// Performs a network operation with retry logic and comprehensive logging
    func performWithRetry<T>(
        operation: @escaping () async throws -> T,
        config: RetryConfig = .default,
        operationName: String = "Database Operation"
    ) async -> NetworkResult<T> {
        
        print("🔍 [\(operationName)] Starting operation...")
        
        guard isConnected else {
            print("❌ [\(operationName)] No network connection")
            return .noConnection
        }
        
        var lastError: Error?
        
        for attempt in 1...config.maxAttempts {
            do {
                print("🔄 [\(operationName)] Attempt \(attempt)/\(config.maxAttempts)")
                let result = try await operation()
                print("✅ [\(operationName)] Success on attempt \(attempt)")
                return .success(result)
            } catch {
                lastError = error
                print("❌ [\(operationName)] Attempt \(attempt) failed: \(error.localizedDescription)")
                
                // Log specific error details
                if let supabaseError = error as? PostgrestError {
                    print("   📊 Supabase Error Code: \(supabaseError.code)")
                    print("   📊 Supabase Error Message: \(supabaseError.message)")
                }
                
                // Don't retry on certain errors
                if !shouldRetry(error) {
                    print("🛑 [\(operationName)] Not retrying - error is not recoverable")
                    return .failure(error, attempt: attempt, maxAttempts: config.maxAttempts)
                }
                
                // If this is the last attempt, return failure
                if attempt == config.maxAttempts {
                    print("🛑 [\(operationName)] All attempts exhausted")
                    return .failure(error, attempt: attempt, maxAttempts: config.maxAttempts)
                }
                
                // Calculate delay with exponential backoff
                let delay = min(
                    config.baseDelay * pow(config.backoffMultiplier, Double(attempt - 1)),
                    config.maxDelay
                )
                
                print("⏳ [\(operationName)] Waiting \(String(format: "%.1f", delay))s before retry...")
                
                // Wait before retrying
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        return .failure(lastError ?? NetworkError.unknown, attempt: config.maxAttempts, maxAttempts: config.maxAttempts)
    }
    
    /// Determines if an error should trigger a retry
    private func shouldRetry(_ error: Error) -> Bool {
        // Retry on network-related errors
        if let supabaseError = error as? PostgrestError {
            return supabaseError.code == "PGRST304" || // Database connection error
                   supabaseError.code == "PGRST305"    // Request timeout
        }
        
        // Retry on general network errors
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain &&
               (nsError.code == NSURLErrorNetworkConnectionLost ||
                nsError.code == NSURLErrorTimedOut ||
                nsError.code == NSURLErrorCannotConnectToHost)
    }
}

enum NetworkError: Error, LocalizedError {
    case unknown
    case noConnection
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "An unknown network error occurred"
        case .noConnection:
            return "No internet connection available"
        case .timeout:
            return "Request timed out"
        }
    }
}
