//
//  ClientTunnelConnectionDelegate.swift
//  PacketTunnelExtension
//
//  Created by Adelita Schule on 5/17/18.
//

import Foundation

/// The delegate protocol for ClientTunnelConnection.
public protocol ClientTunnelConnectionDelegate
{
    /// Handle the connection being opened.
    func tunnelConnectionDidOpen(_ connection: ClientTunnelConnection, configuration: [NSObject: AnyObject])
    /// Handle the connection being closed.
    func tunnelConnectionDidClose(_ connection: ClientTunnelConnection, error: Error?)
}
