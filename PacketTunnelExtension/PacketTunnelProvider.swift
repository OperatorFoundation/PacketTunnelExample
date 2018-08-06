/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the PacketTunnelProvider class. The PacketTunnelProvider class is a sub-class of NEPacketTunnelProvider, and is the integration point between the Network Extension framework and the SimpleTunnel tunneling protocol.
*/

import NetworkExtension
import SwiftQueue
import Transport

/*
 TODO:
    - Set remote host
    - Set lastError
    - Implement didChange(connectionState: connectionState, maybeError: maybeError)
 */

/// A packet tunnel provider object.
class PacketTunnelProvider: NEPacketTunnelProvider
{
    /// Use this to create connections
    var connectionFactory: NetworkConnectionFactory?
    
    /// The tunnel connection.
    open var connection: Connection?

	/// The single logical flow of packets through the tunnel.
	var tunnelConnection: ClientTunnelConnection?

	/// The completion handler to call when the tunnel is fully established.
	var pendingStartCompletion: ((Error?) -> Void)?

	/// The completion handler to call when the tunnel is fully disconnected.
	var pendingStopCompletion: (() -> Void)?
    
    /// The last error that occurred on the tunnel.
    var lastError: Error?
    
    /// A Queue of Log Messages
    var logQueue = Queue<String>()
    
    /// The address of the tunnel server.
    open var remoteHost: String?
    
    /// To make sure that we don't try connecting repeatedly and unintentionally
    var connectionAttemptStatus: ConnectionAttemptStatus = .initialized

	// MARK: NEPacketTunnelProvider

	/// Start the TCP connection to the tunnel server.
	override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void)
    {
        switch connectionAttemptStatus
        {
        case .initialized:
            connectionAttemptStatus = .started
        case .started:
            logQueue.enqueue("start tunnel called when tunnel was already started.")
        case .connecting:
            connectionAttemptStatus = .started
        }
        
        logQueue.enqueue("startTunnel called")
        
        // Save the completion handler for when the tunnel is fully established.
        pendingStartCompletion = completionHandler
        
        guard let serverAddress: String = self.protocolConfiguration.serverAddress
            else
        {
            logQueue.enqueue("Unable to resolve server address.")
            completionHandler(SimpleTunnelError.badConfiguration)
            return
        }
        self.remoteHost = serverAddress
        self.logQueue.enqueue("Server address: \(serverAddress)")
        
        //FIXME: Needs to be the server address not hard-coded
        guard let ipv4Address = IPv4Address("166.78.129.122")
            else
        {
            logQueue.enqueue("Unable to resolve host address.")
            return
        }
        
        let host = NWEndpoint.Host.ipv4(ipv4Address)
        let portString = "8080"
        
        guard let portUInt = UInt16(portString), let port = NWEndpoint.Port(rawValue: portUInt)
            else
        {
            logQueue.enqueue("Unable to resolve host port.")
            return
        }
        
        connectionFactory = NetworkConnectionFactory(host: host, port: port)
        logQueue.enqueue("Connection Factory Created")
    }

	/// Begin the process of stopping the tunnel.
	override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void)
    {
        logQueue.enqueue("closeTunnel Called")
        
		// Clear out any pending start completion handler.
        pendingStartCompletion?(SimpleTunnelError.internalError)
        pendingStartCompletion = nil

        // Close the tunnel connection.
        if let TCPConnection = connection
        {
            TCPConnection.cancel()
        }
        
        connectionAttemptStatus = .initialized
        pendingStopCompletion?()
	}
    
    /// Close the tunnel.
    open func closeTunnelWithError(_ error: Error?)
    {
        logQueue.enqueue("Closing the tunnel with error: \(String(describing: error))")
        lastError = error
        pendingStartCompletion?(error)
       
        // Close the tunnel connection.
        if let TCPConnection = connection
        {
            TCPConnection.cancel()
        }
        
        tunnelConnection = nil
        connectionAttemptStatus = .initialized
    }

	/// Handle IPC messages from the app.
	override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?)
    {
        switch connectionAttemptStatus
        {
            case .initialized:
                logQueue.enqueue("handleAppMessage called before start tunnel. Doing nothing...")
            case .started:
                connectionAttemptStatus = .connecting
                setTunnelSettings(configuration: [:])
            case .connecting:
                break
        }
        
        var responseString = "Nothing to see here!"

        if let logMessage = self.logQueue.dequeue()
        {
            responseString = "\n*******\(logMessage)*******\n"
        }
        else
        {
            responseString = ""
        }
        
		let responseData = responseString.data(using: String.Encoding.utf8)
        
		completionHandler?(responseData)
	}

	/// Handle the event of the tunnel connection being closed.
	func tunnelDidClose()
    {
		if pendingStartCompletion != nil
        {
			// Closed while starting, call the start completion handler with the appropriate error.
			pendingStartCompletion?(lastError)
			pendingStartCompletion = nil
		}
		else if pendingStopCompletion != nil
        {
			// Closed as the result of a call to stopTunnelWithReason, call the stop completion handler.
            pendingStopCompletion?()
			pendingStopCompletion = nil
		}
		else
        {
			// Closed as the result of an error on the tunnel connection, cancel the tunnel.
			cancelTunnelWithError(lastError)
		}
	}

	// MARK: ClientTunnelConnectionDelegate

	/// Handle the event of the logical flow of packets being established through the tunnel.
	func setTunnelSettings(configuration: [NSObject: AnyObject])
    {
        logQueue.enqueue("\n🚀 tunnelConnectionDidOpen  🚀\n")
        
        // Create the virtual interface settings.
        guard let settings = createTunnelSettingsFromConfiguration(configuration)
        else
        {
            connectionAttemptStatus = .initialized
            pendingStartCompletion?(SimpleTunnelError.internalError)
            pendingStartCompletion = nil
            return
        }

        // Set the virtual interface settings.
        setTunnelNetworkSettings(settings, completionHandler: tunnelSettingsCompleted)
	}
    
    func tunnelSettingsCompleted(maybeError: Error?)
    {
        logQueue.enqueue("Tunnel settings updated.")
        if let error = maybeError
        {
            self.logQueue.enqueue("Failed to set the tunnel network settings: \(error)")
            connectionAttemptStatus = .initialized
            self.pendingStartCompletion?(error)
            self.pendingStartCompletion = nil
        }
        else
        {
            connectToServer()
        }
    }

	/// Create the tunnel network settings to be applied to the virtual interface.
	func createTunnelSettingsFromConfiguration(_ configuration: [NSObject: AnyObject]) -> NEPacketTunnelNetworkSettings?
    {
        let newSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "166.78.129.122")
        let address = "192.168.2.1"
        let netmask = "255.255.255.0"

        //FIXME: tunnelAddress should be remoteHost,
        // configuration argument is ignored
//        guard let tunnelAddress = remoteHost
//        else
//        {
//            logQueue.enqueue("Unable to resolve tunnelAddress for NEPacketTunnelNetworkSettings")
//            return nil
//
//        }
//
//        let newSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: tunnelAddress)
        newSettings.ipv4Settings = NEIPv4Settings(addresses: [address], subnetMasks: [netmask])
        newSettings.ipv4Settings?.includedRoutes = [NEIPv4Route.default()]
        newSettings.dnsSettings = NEDNSSettings(servers: ["8.8.8.8"])
        newSettings.tunnelOverheadBytes = 150

		return newSettings
	}
    
    //MARK: Helper Functions
    
    func connectToServer()
    {
        logQueue.enqueue("Connect to server called.")
        guard let connectionFactory = connectionFactory
        else
        {
            logQueue.enqueue("Unable to find connection facotory.")
            return
        }
        
        let parameters = NWParameters()
        let connectQueue = DispatchQueue(label: "connectQueue")
        connection = connectionFactory.connect(parameters)
        connection?.stateUpdateHandler = handleStateUpdate
        
        // Kick off the connection to the server
        logQueue.enqueue("Kicking off the connection to the server.")
        connection?.start(queue: connectQueue)
    }
    
    func handleStateUpdate(newState: NWConnection.State)
    {
        self.logQueue.enqueue("CURRENT STATE = \(newState))")
        
        guard let startCompletion = pendingStartCompletion
            else
        {
            logQueue.enqueue("pendingStartCompletion is nil?")
            return
        }
        
        switch newState
        {
        case .ready:
            // Start reading messages from the tunnel connection.
            self.tunnelConnection?.startHandlingPackets()

            // Open the logical flow of packets through the tunnel.
            let newConnection = ClientTunnelConnection(clientPacketFlow: self.packetFlow)
            self.logQueue.enqueue("\n🚀 open() called on tunnel connection  🚀\n")
            self.tunnelConnection = newConnection
            startCompletion(nil)

        case .cancelled:
            self.logQueue.enqueue("\n🙅‍♀️  Connection Canceled  🙅‍♀️\n")
            self.connection = nil
            self.tunnelDidClose()
            startCompletion(SimpleTunnelError.cancelled)

        case .failed(let error):
            self.logQueue.enqueue("\n🐒💨  Connection Failed  🐒💨\n")
            self.closeTunnelWithError(error)
            startCompletion(error)

        default:
            self.logQueue.enqueue("\n🤷‍♀️  Unexpected State: \(newState))  🤷‍♀️\n")
        }
    }
    
    
}

enum ConnectionAttemptStatus
{
    case initialized
    case started
    case connecting
}
