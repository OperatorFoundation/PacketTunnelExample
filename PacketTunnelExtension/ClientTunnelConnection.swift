/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the ClientTunnelConnection class. The ClientTunnelConnection class handles the encapsulation and decapsulation of IP packets in the client side of the SimpleTunnel tunneling protocol.
*/

import Foundation
import NetworkExtension

/// An object used to tunnel IP packets using the SimpleTunnel protocol.
public class ClientTunnelConnection
{
	/// The connection delegate.
	let delegate: ClientTunnelConnectionDelegate

	/// The flow of IP packets.
	let packetFlow: NEPacketTunnelFlow

	// MARK: Initializers

	init(clientPacketFlow: NEPacketTunnelFlow, connectionDelegate: ClientTunnelConnectionDelegate)
    {
		delegate = connectionDelegate
		packetFlow = clientPacketFlow
	}

	// MARK: Interface

	/// Send a "connection open" message to the tunnel server.
	func open()
    {
		delegate.tunnelConnectionDidOpen(self, configuration: [:])
	}

	/// Handle packets coming from the packet flow.
	func handlePackets(_ packets: [Data], protocols: [NSNumber])
    {
        // This is where you should send the packets to the server.
        
        // Read more packets.
        self.packetFlow.readPackets
        {
            inPackets, inProtocols in
            
            self.handlePackets(inPackets, protocols: inProtocols)
        }
	}

	/// Make the initial readPacketsWithCompletionHandler call.
	func startHandlingPackets()
    {
		packetFlow.readPackets
        {
            inPackets, inProtocols in
            
			self.handlePackets(inPackets, protocols: inProtocols)
		}
	}

	/// Send packets to the virtual interface to be injected into the IP stack.
    public func sendPackets(_ packets: [Data], protocols: [NSNumber])
    {
		packetFlow.writePackets(packets, withProtocols: protocols)
	}
}
