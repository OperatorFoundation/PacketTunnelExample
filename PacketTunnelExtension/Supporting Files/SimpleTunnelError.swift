//
//  SimpleTunnelError.swift
//  PacketTunnelExtension
//
//  Created by Adelita Schule on 5/17/18.
//

import Foundation

/// SimpleTunnel errors
public enum SimpleTunnelError: Error
{
    case badConfiguration
    case badConnection
    case cancelled
    case disconnected
    case internalError
}
