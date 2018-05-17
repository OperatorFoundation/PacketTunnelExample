//
//  TunnelDelegate.swift
//  PacketTunnelServices
//
//  Created by Adelita Schule on 5/17/18.
//

import Foundation

/// The tunnel delegate protocol.
public protocol TunnelDelegate: class
{
    func tunnelDidOpen(_ targetTunnel: Tunnel)
    func tunnelDidClose(_ targetTunnel: Tunnel)
    func tunnelDidSendConfiguration(_ targetTunnel: Tunnel, configuration: [String: AnyObject])
}
