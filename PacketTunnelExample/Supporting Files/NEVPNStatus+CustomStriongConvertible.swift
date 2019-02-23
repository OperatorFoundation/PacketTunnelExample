//
//  NEVPNStatus+CustomStriongConvertible.swift
//  PacketTunnelExample
//
//  Created by Mafalda on 2/12/19.
//

import Foundation
import NetworkExtension

/// Make NEVPNStatus convertible to a string
extension NEVPNStatus: CustomStringConvertible
{
    public var description: String
    {
        switch self
        {
        case .disconnected: return "Disconnected"
        case .invalid: return "Invalid"
        case .connected: return "Connected"
        case .connecting: return "Connecting"
        case .disconnecting: return "Disconnecting"
        case .reasserting: return "Reconnecting"
        }
    }
}
