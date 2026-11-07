import Foundation
import Network

/// Lightweight local HTTP REST server running on localhost:31415 using Network.framework.
/// Allows the OpenLid web dashboard or local automations to query telemetry and toggle awake state.
public final class ControlServer {
    public static let shared = ControlServer()
    public static let defaultPort: UInt16 = 31415
    
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.openlid.controlserver", qos: .utility)
    
    private init() {}
    
    public func start(port: UInt16 = defaultPort) {
        guard listener == nil else { return }
        
        do {
            let tcpOptions = NWProtocolTCP.Options()
            let params = NWParameters(tls: nil, tcp: tcpOptions)
            params.allowLocalEndpointReuse = true
            
            listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
            listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("OpenLid ControlServer listening on 127.0.0.1:\(port)")
                case .failed(let error):
                    print("ControlServer listener failed: \(error.localizedDescription)")
                default:
                    break
                }
            }
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            
            listener?.start(queue: queue)
        } catch {
            print("Failed to start ControlServer: \(error.localizedDescription)")
        }
    }
    
    public func stop() {
        listener?.cancel()
        listener = nil
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, _, error in
            guard let self = self, let data = data, error == nil else {
                connection.cancel()
                return
            }
            
            let requestString = String(data: data, encoding: .utf8) ?? ""
            let responseData = self.processRequest(requestString)
            
            connection.send(content: responseData, completion: .contentProcessed({ _ in
                connection.cancel()
            }))
        }
    }
    
    private func processRequest(_ request: String) -> Data {
        let lines = request.components(separatedBy: "\r\n")
        guard let firstLine = lines.first else {
            return makeHTTPResponse(status: 400, json: ["error": "Bad Request"])
        }
        
        let parts = firstLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            return makeHTTPResponse(status: 400, json: ["error": "Bad Request"])
        }
        
        let method = parts[0].uppercased()
        let path = parts[1]
        
        // Handle CORS preflight
        if method == "OPTIONS" {
            return makeCORSResponse()
        }
        
        let powerManager = PowerManager.shared
        
        switch path {
        case "/api/status":
            let json: [String: Any] = [
                "isEnabled": powerManager.isEnabled,
                "isLidClosed": powerManager.clamshell.isLidClosed,
                "batteryPercent": powerManager.battery.batteryPercent,
                "isOnACPower": powerManager.battery.isOnACPower,
                "isCharging": powerManager.battery.isCharging,
                "thermalState": powerManager.thermal.stateDescription,
                "remainingTime": Int(powerManager.timer.remainingSeconds)
            ]
            return makeHTTPResponse(status: 200, json: json)
            
        case "/api/toggle":
            DispatchQueue.main.async {
                powerManager.toggle()
            }
            return makeHTTPResponse(status: 200, json: ["success": true, "action": "toggle"])
            
        case "/api/awake":
            DispatchQueue.main.async {
                powerManager.enable(preset: .indefinite)
            }
            return makeHTTPResponse(status: 200, json: ["success": true, "action": "awake"])
            
        case "/api/sleep":
            DispatchQueue.main.async {
                powerManager.disable()
            }
            return makeHTTPResponse(status: 200, json: ["success": true, "action": "sleep"])
            
        default:
            return makeHTTPResponse(status: 404, json: ["error": "Not Found"])
        }
    }
    
    private func makeCORSResponse() -> Data {
        let headers = [
            "HTTP/1.1 204 No Content",
            "Access-Control-Allow-Origin: *",
            "Access-Control-Allow-Methods: GET, POST, OPTIONS",
            "Access-Control-Allow-Headers: Content-Type",
            "Connection: close",
            "",
            ""
        ].joined(separator: "\r\n")
        return headers.data(using: .utf8) ?? Data()
    }
    
    private func makeHTTPResponse(status: Int, json: [String: Any]) -> Data {
        let statusText = status == 200 ? "OK" : (status == 404 ? "Not Found" : "Error")
        let bodyData = (try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])) ?? Data()
        
        let headers = [
            "HTTP/1.1 \(status) \(statusText)",
            "Content-Type: application/json",
            "Content-Length: \(bodyData.count)",
            "Access-Control-Allow-Origin: *",
            "Access-Control-Allow-Methods: GET, POST, OPTIONS",
            "Access-Control-Allow-Headers: Content-Type",
            "Connection: close",
            "",
            ""
        ].joined(separator: "\r\n")
        
        var fullData = headers.data(using: .utf8) ?? Data()
        fullData.append(bodyData)
        return fullData
    }
}
