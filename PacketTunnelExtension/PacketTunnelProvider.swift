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

extension NWTCPConnectionState: CustomStringConvertible
{
    public var description: String
    {
        switch self
        {
        case .disconnected: return "Disconnected"
        case .invalid: return "Invalid"
        case .connected: return "Connected"
        case .connecting: return "Connecting"
        case .cancelled: return "Cancelled"
        case .waiting: return "Waiting"
        }
    }
}

/// A packet tunnel provider object.
class PacketTunnelProvider: NEPacketTunnelProvider
{
    /// The tunnel connection.
    open var connection: TCPConnection?

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

	// MARK: NEPacketTunnelProvider

	/// Start the TCP connection to the tunnel server.
	override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void)
    {
        self.logQueue.enqueue("startTunnel called")
        
        // Save the completion handler for when the tunnel is fully established.
        pendingStartCompletion = completionHandler
        
        guard let serverAddress: String = self.protocolConfiguration.serverAddress
            else
        {
            logQueue.enqueue("Unable to resolve server address.")
            completionHandler(SimpleTunnelError.badConfiguration)
            return
        }
        
        self.logQueue.enqueue("Server address: \(serverAddress)")
        
        let frontURL = URL(string: "https://www.google.com")
        guard let serverURL = URL(string: "https://\(serverAddress)/")
            else
        {
            logQueue.enqueue("Unable to resolve front url.")
            completionHandler(SimpleTunnelError.badConfiguration)
            return
        }
        
        // Kick off the connection to the server
        logQueue.enqueue("Kicking off the connections to the server.")
        //        guard let meekConnection = createMeekTCPConnection(provider: provider, to: frontURL!, serverURL: serverURL)
        //        else
        //        {
        //            logQueue.enqueue("Unable to establish Meek TCP connection.")
        //            return .badConfiguration
        //        }
        //
        //        connection = meekConnection
        //        logQueue.enqueue("MeekTCPConnection created.")
        
        let endpoint = NWHostEndpoint(hostname: "www.google.com", port: "443")
        guard let tcpConnection: NWTCPConnection = self.createTCPConnectionThroughTunnel(to: endpoint, enableTLS: true, tlsParameters: nil, delegate: nil)
            else
        {
            logQueue.enqueue("Unable to establish TCP connection.")
            completionHandler(SimpleTunnelError.badConfiguration)
            return
        }
        
        connection = tcpConnection
        logQueue.enqueue("TCPConnection created")
        
        // Register for notificationes when the connection status changes.
        logQueue.enqueue("Registering for connection status change notifications.")
        logQueue.enqueue("CURRENT STATE = \(tcpConnection.state.description)")
        if connection?.state == .waiting
        {
            logQueue.enqueue("CONNECTION STATE IS ALREADY WAITING")
            completionHandler(SimpleTunnelError.badConnection)
        }
        
        tcpConnection.observe(\NWTCPConnection.state)
        {
            (nwtcpConnection, observedChange) in
            
            self.logQueue.enqueue("Received state change from NWTCPConnection: \(String(describing: observedChange.newValue))")
        }

        connection!.observeState
        {
            (connectionState, maybeError) in
            
            // Handle connection state callback
            self.logQueue.enqueue("Connection state callback: \(connectionState), \(String(describing: maybeError))")
            
            self.logQueue.enqueue(">>Tunnel connection state changed to \(self.connection!.state)<<")
            
            switch self.connection!.state
            {
                case .connected:
                    if let remoteAddress = self.connection!.remoteAddress as? NWHostEndpoint
                    {
                        self.remoteHost = remoteAddress.hostname
                    }
                    
                    // Start reading messages from the tunnel connection.
                    self.tunnelConnection?.startHandlingPackets()
                    
                    // Open the logical flow of packets through the tunnel.
                    let newConnection = ClientTunnelConnection(clientPacketFlow: self.packetFlow)

                    self.tunnelConnectionDidOpen(newConnection, configuration: [:])
                    self.logQueue.enqueue("\n🚀 open() called on tunnel connection  🚀\n")
                    self.tunnelConnection = newConnection
                    completionHandler(nil)
                
                case .disconnected:
                    self.closeTunnelWithError(self.connection!.error)
                    completionHandler(SimpleTunnelError.disconnected)
                
                case .cancelled:
                    //TODO: connection!.removeObserver(self, forKeyPath:"state", context:&connection)
                    self.connection = nil
                    self.tunnelDidClose()
                    completionHandler(SimpleTunnelError.cancelled)
                
                default:
                    completionHandler(SimpleTunnelError.badConnection)
                    break
                }
            
            //connection!.addObserver(self, forKeyPath: "state", options: .initial, context: &connection)
        }

        logQueue.enqueue("CURRENT STATE = \(tcpConnection.state.description)")
        
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
    }

	/// Handle IPC messages from the app.
	override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?)
    {
        let state = connection?.state
        self.logQueue.enqueue("^^^connections state: \(state?.description)")
        self.logQueue.enqueue("error: \(String(describing: connection?.error))")
        self.logQueue.enqueue("endpoint: \(String(describing: connection?.endpoint))")
        
        
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
	func tunnelConnectionDidOpen(_ connection: ClientTunnelConnection, configuration: [NSObject: AnyObject])
    {
        logQueue.enqueue("\n🚀 tunnelConnectionDidOpen  🚀\n")
		// Create the virtual interface settings.
		guard let settings = createTunnelSettingsFromConfiguration(configuration)
        else
        {
			pendingStartCompletion?(SimpleTunnelError.internalError)
			pendingStartCompletion = nil
			return
		}

		// Set the virtual interface settings.
		setTunnelNetworkSettings(settings)
        {
            error in
			
            var startError: Error?
			if let error = error
            {
                self.logQueue.enqueue("Failed to set the tunnel network settings: \(error)")
				startError = SimpleTunnelError.badConfiguration
			}
			else
            {
				// Now we can start reading and writing packets to/from the virtual interface.
				self.tunnelConnection?.startHandlingPackets()
			}

            //TODO: This causes the status to be changed to connected
			// Now the tunnel is fully established, call the start completion handler.
			self.pendingStartCompletion?(startError)
			self.pendingStartCompletion = nil
		}
	}

	/// Create the tunnel network settings to be applied to the virtual interface.
	func createTunnelSettingsFromConfiguration(_ configuration: [NSObject: AnyObject]) -> NEPacketTunnelNetworkSettings?
    {
        let address = "192.168.2.1"
        let netmask = "255.255.255.0"
        
		guard let tunnelAddress = remoteHost
        else { return nil }

		let newSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: tunnelAddress)
        newSettings.ipv4Settings = NEIPv4Settings(addresses: [address], subnetMasks: [netmask])
        newSettings.ipv4Settings?.includedRoutes = [NEIPv4Route.default()]
        newSettings.dnsSettings = NEDNSSettings(servers: ["8.8.8.8"])
		newSettings.tunnelOverheadBytes = 150

		return newSettings
	}
}
