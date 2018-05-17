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
class PacketTunnelProvider: NEPacketTunnelProvider, ClientTunnelConnectionDelegate
{
	/// A reference to the tunnel object.
	//var tunnel: ClientTunnel?
    
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
        
        let endpoint = NWHostEndpoint(hostname: serverAddress, port: "80")
        guard let tcpConnection: TCPConnection = self.createTCPConnectionThroughTunnel(to: endpoint, enableTLS: false, tlsParameters: nil, delegate: nil)
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
        
        connection!.observeState
        {
            (connectionState, maybeError) in
            
            // Handle connection state callback
            self.logQueue.enqueue("Connection state callback: \(connectionState), \(String(describing: maybeError))")
            
            /// FIX ME
            // self.didChange(connectionState: connectionState, maybeError: maybeError)
            
            //connection!.addObserver(self, forKeyPath: "state", options: .initial, context: &connection)
        }

        // Save the completion handler for when the tunnel is fully established.
        pendingStartCompletion = completionHandler
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
    }

	/// Handle IPC messages from the app.
	override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?)
    {
		guard let messageString = NSString(data: messageData, encoding: String.Encoding.utf8.rawValue)
        else
        {
			completionHandler?(nil)
			return
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
        
        logQueue.enqueue("Got a message from the app: \(messageString)")

		let responseData = responseString.data(using: String.Encoding.utf8)
		completionHandler?(responseData)
	}

	// MARK: TunnelDelegate

	/// Handle the event of the tunnel connection being established.
	func tunnelDidOpen()
    {
		// Open the logical flow of packets through the tunnel.
		let newConnection = ClientTunnelConnection(clientPacketFlow: packetFlow, connectionDelegate: self)
		newConnection.open()
		tunnelConnection = newConnection
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

	/// Handle the event of the logical flow of packets being torn down.
	func tunnelConnectionDidClose(_ connection: ClientTunnelConnection, error: Error?)
    {
		tunnelConnection = nil
		closeTunnelWithError(error)
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
