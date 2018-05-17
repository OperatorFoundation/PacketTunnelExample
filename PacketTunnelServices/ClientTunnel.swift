/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the ClientTunnel class. The ClientTunnel class implements the client side of the SimpleTunnel tunneling protocol.
*/

import Foundation
import NetworkExtension
import Meek
import Transport
import SwiftQueue

/// The client-side implementation of the SimpleTunnel protocol.
open class ClientTunnel: Tunnel
{
	/// The tunnel connection.
	open var connection: TCPConnection?

	/// The last error that occurred on the tunnel.
	open var lastError: Error?

	/// The previously-received incomplete message data.
	var previousData: NSMutableData?

	/// The address of the tunnel server.
	open var remoteHost: String?
    
    /// A Queue of Log Messages
    open var logQueue = Queue<String>()

	// MARK: Interface

	/// Start the TCP connection to the tunnel server.
	open func startTunnel(_ provider: NEPacketTunnelProvider) -> SimpleTunnelError?
    {
        self.logQueue.enqueue("startTunnel called")
        
        guard let serverAddress: String = provider.protocolConfiguration.serverAddress
        else
        {
            logQueue.enqueue("Unable to resolve server address.")
			return .badConfiguration
		}
        
        self.logQueue.enqueue("Server address: \(serverAddress)")

        let frontURL = URL(string: "https://www.google.com")
        guard let serverURL = URL(string: "https://\(serverAddress)/")
            else
        {
            logQueue.enqueue("Unable to resolve front url.")
            return .badConfiguration
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
        guard let tcpConnection: TCPConnection = provider.createTCPConnectionThroughTunnel(to: endpoint, enableTLS: false, tlsParameters: nil, delegate: nil)
        else
        {
            logQueue.enqueue("Unable to establish TCP connection.")
            return .badConfiguration
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
            self.didChange(connectionState: connectionState, maybeError: maybeError)
            
            //connection!.addObserver(self, forKeyPath: "state", options: .initial, context: &connection)
        }

		return nil
	}

	/// Close the tunnel.
	open func closeTunnelWithError(_ error: Error?)
    {
        logQueue.enqueue("Closing the tunnel with error: \(String(describing: error))")
		lastError = error
		closeTunnel()
	}

	/// Read a SimpleTunnel packet from the tunnel connection.
	func readNextPacket()
    {
        logQueue.enqueue("readNextPacket Called")
		guard let targetConnection = connection
        else
        {
			closeTunnelWithError(SimpleTunnelError.badConnection)
			return
		}

		// First, read the total length of the packet.
		targetConnection.readMinimumLength(MemoryLayout<UInt32>.size, maximumLength: MemoryLayout<UInt32>.size) { data, error in
			if let readError = error
            {
                self.logQueue.enqueue("Got an error on the tunnel connection: \(readError)")
				simpleTunnelLog("Got an error on the tunnel connection: \(readError)")
				self.closeTunnelWithError(readError)
				return
			}

			let lengthData = data!

			guard lengthData.count == MemoryLayout<UInt32>.size
            else
            {
                self.logQueue.enqueue("Length data length (\(lengthData.count)) != sizeof(UInt32) (\(MemoryLayout<UInt32>.size)")
				simpleTunnelLog("Length data length (\(lengthData.count)) != sizeof(UInt32) (\(MemoryLayout<UInt32>.size)")
				self.closeTunnelWithError(SimpleTunnelError.internalError)
				return
			}

			var totalLength: UInt32 = 0
			(lengthData as NSData).getBytes(&totalLength, length: MemoryLayout<UInt32>.size)

			if totalLength > UInt32(Tunnel.maximumMessageSize)
            {
                self.logQueue.enqueue("Got a length that is too big: \(totalLength)")
				simpleTunnelLog("Got a length that is too big: \(totalLength)")
				self.closeTunnelWithError(SimpleTunnelError.internalError)
				return
			}

			totalLength -= UInt32(MemoryLayout<UInt32>.size)

			// Second, read the packet payload.
			targetConnection.readMinimumLength(Int(totalLength), maximumLength: Int(totalLength)) { data, error in
				if let payloadReadError = error
                {
                    self.logQueue.enqueue("Got an error on the tunnel connection: \(payloadReadError)")
					simpleTunnelLog("Got an error on the tunnel connection: \(payloadReadError)")
					self.closeTunnelWithError(payloadReadError)
					return
				}

				let payloadData = data!

				guard payloadData.count == Int(totalLength)
                else
                {
                    self.logQueue.enqueue("Payload data length (\(payloadData.count)) != payload length (\(totalLength)")
					simpleTunnelLog("Payload data length (\(payloadData.count)) != payload length (\(totalLength)")
					self.closeTunnelWithError(SimpleTunnelError.internalError)
					return
				}

				_ = self.handlePacket(payloadData)

				self.readNextPacket()
			}
		}
	}

	/// Send a message to the tunnel server.
	open func sendMessage(_ messageProperties: [String: AnyObject], completionHandler: @escaping (Error?) -> Swift.Void)
    {
        logQueue.enqueue("Sending a message to the server.")
		guard let messageData = serializeMessage(messageProperties)
        else
        {
			completionHandler(SimpleTunnelError.internalError )
			return
		}

		connection!.write(messageData, completionHandler: completionHandler)
	}

	// MARK: NSObject

	/// Handle changes to the tunnel connection state.
    func didChange(connectionState: NWTCPConnectionState, maybeError: Error?)
    {
//        guard keyPath == "state" && context?.assumingMemoryBound(to: Optional<MeekTCPConnection>.self).pointee == connection
//        else
//        {
//            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
//            return
//        }

        self.logQueue.enqueue(">>Tunnel connection state changed to \(connection!.state)<<")

		switch connection!.state
        {
			case .connected:
				if let remoteAddress = self.connection!.remoteAddress as? NWHostEndpoint
                {
					remoteHost = remoteAddress.hostname
				}

				// Start reading messages from the tunnel connection.
				readNextPacket()

				// Let the delegate know that the tunnel is open
				delegate?.tunnelDidOpen(self)

			case .disconnected:
				closeTunnelWithError(connection!.error)

			case .cancelled:
                //TODO: connection!.removeObserver(self, forKeyPath:"state", context:&connection)
				connection = nil
				delegate?.tunnelDidClose(self)

			default:
				break
		}
	}

	// MARK: Tunnel

	/// Close the tunnel.
	override open func closeTunnel()
    {
        logQueue.enqueue("closeTunnel Called")
		super.closeTunnel()
		// Close the tunnel connection.
		if let TCPConnection = connection
        {
			TCPConnection.cancel()
		}
	}

	/// Write data to the tunnel connection.
	override func writeDataToTunnel(_ data: Data, startingAtOffset: Int) -> Int
    {
        logQueue.enqueue("writeDataToTunnel Called")
		connection?.write(data)
        {
            error in
			
            if error != nil
            {
				self.closeTunnelWithError(error)
			}
		}
		return data.count
	}

	/// Handle a message received from the tunnel server.
	override func handleMessage(_ commandType: TunnelCommand, properties: [String: AnyObject], connection: Connection?) -> Bool
    {
        logQueue.enqueue("handleMessage Called")
		var success = true

		switch commandType
        {
			case .openResult:
				// A logical connection was opened successfully.
				guard let targetConnection = connection,
					let resultCodeNumber = properties[TunnelMessageKey.ResultCode.rawValue] as? Int,
					let resultCode = TunnelConnectionOpenResult(rawValue: resultCodeNumber)
                else
				{
                    self.logQueue.enqueue("Tunnel received an invalid command: case .openResult")
                    simpleTunnelLog("Tunnel received an invalid command")
					success = false
					break
				}

				targetConnection.handleOpenCompleted(resultCode, properties:properties as [NSObject : AnyObject])

			case .fetchConfiguration:
				guard let configuration = properties[TunnelMessageKey.Configuration.rawValue] as? [String: AnyObject]
					else
                {
                    self.logQueue.enqueue("Tunnel received an invalid command: case .fetchConfiguration")
                    simpleTunnelLog("Tunnel received an invalid command")
                    break
                        
                }

				delegate?.tunnelDidSendConfiguration(self, configuration: configuration)
			
			default:
                self.logQueue.enqueue("Tunnel received an invalid command")
				simpleTunnelLog("Tunnel received an invalid command")
				success = false
		}
        
		return success
	}

	/// Send a FetchConfiguration message on the tunnel connection.
	open func sendFetchConfiguation()
    {
        logQueue.enqueue("Sending a fetch configuration message on the tunnel connection.")
		let properties = createMessagePropertiesForConnection(0, commandType: .fetchConfiguration)
		if !sendMessage(properties)
        {
            self.logQueue.enqueue("Failed to send a fetch configuration message")
			simpleTunnelLog("Failed to send a fetch configuration message")
		}
	}
}
