//
//  NWTCPConnection+CustomStringConvertible.swift
//  PacketTunnelExtension
//
//  Created by Adelita Schule on 5/17/18.
//

import Foundation
import NetworkExtension

/// Make NEVPNStatus convertible to a string
extension NWTCPConnectionState: CustomStringConvertible
{
    public var description: String
    {
        switch self
        {
        case .cancelled: return "Cancelled"
        case .connected: return "Connected"
        case .connecting: return "Connecting"
        case .disconnected: return "Disconnected"
        case .invalid: return "Invalid"
        case .waiting: return "Waiting"
        }
    }
}
