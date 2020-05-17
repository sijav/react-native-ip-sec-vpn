//
//  RNIpSecVpn.swift
//  RNIpSecVpn
//
//  Created by Sina Javaheri on 25/02/1399.
//  Copyright © 1399 AP Sijav. All rights reserved.
//

import Foundation
import NetworkExtension
import Security



// Identifiers
let serviceIdentifier = "MySerivice"
let userAccount = "authenticatedUser"
let accessGroup = "MySerivice"

// Arguments for the keychain queries
var kSecAttrAccessGroupSwift = NSString(format: kSecClass)

let kSecClassValue = kSecClass as CFString
let kSecAttrAccountValue = kSecAttrAccount as CFString
let kSecValueDataValue = kSecValueData as CFString
let kSecClassGenericPasswordValue = kSecClassGenericPassword as CFString
let kSecAttrServiceValue = kSecAttrService as CFString
let kSecMatchLimitValue = kSecMatchLimit as CFString
let kSecReturnDataValue = kSecReturnData as CFString
let kSecMatchLimitOneValue = kSecMatchLimitOne as CFString
let kSecAttrGenericValue = kSecAttrGeneric as CFString
let kSecAttrAccessibleValue = kSecAttrAccessible as CFString


class KeychainService: NSObject {
    func save(key: String, value: String) {
        let keyData: Data = key.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue), allowLossyConversion: false)!
        let valueData: Data = value.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue), allowLossyConversion: false)!

        let keychainQuery = NSMutableDictionary()
        keychainQuery[kSecClassValue as! NSCopying] = kSecClassGenericPasswordValue
        keychainQuery[kSecAttrGenericValue as! NSCopying] = keyData
        keychainQuery[kSecAttrAccountValue as! NSCopying] = keyData
        keychainQuery[kSecAttrServiceValue as! NSCopying] = "VPN"
        keychainQuery[kSecAttrAccessibleValue as! NSCopying] = kSecAttrAccessibleAlwaysThisDeviceOnly
        keychainQuery[kSecValueData as! NSCopying] = valueData
        // Delete any existing items
        SecItemDelete(keychainQuery as CFDictionary)
        SecItemAdd(keychainQuery as CFDictionary, nil)
    }

    func load(key: String) -> Data {
        let keyData: Data = key.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue), allowLossyConversion: false)!
        let keychainQuery = NSMutableDictionary()
        keychainQuery[kSecClassValue as! NSCopying] = kSecClassGenericPasswordValue
        keychainQuery[kSecAttrGenericValue as! NSCopying] = keyData
        keychainQuery[kSecAttrAccountValue as! NSCopying] = keyData
        keychainQuery[kSecAttrServiceValue as! NSCopying] = "VPN"
        keychainQuery[kSecAttrAccessibleValue as! NSCopying] = kSecAttrAccessibleAlwaysThisDeviceOnly
        keychainQuery[kSecMatchLimit] = kSecMatchLimitOne
        keychainQuery[kSecReturnPersistentRef] = kCFBooleanTrue

        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) { SecItemCopyMatching(keychainQuery, UnsafeMutablePointer($0)) }

        if status == errSecSuccess {
            if let data = result as! NSData? {
                if NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue) != nil {}
                return data as Data
            }
        }
        return "".data(using: .utf8)!
    }
}

@objc(RNIpSecVpn)
class RNIpSecVpn: RCTEventEmitter {
    
    @objc override static func requiresMainQueueSetup() -> Bool {
        return true
    }

    override func supportedEvents() -> [String]! {
        return [ "stateChanged" ]
    }
    
    @objc
    func prepare(_ findEventsWithResolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) -> Void {

        // Register to be notified of changes in the status. These notifications only work when app is in foreground.
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object : nil , queue: nil) {
            notification in let nevpnconn = notification.object as! NEVPNConnection
            self.sendEvent(withName: "stateChanged", body: [ "state" : checkNEStatus(status: nevpnconn.status) ])
        }
        findEventsWithResolver(nil)
    }
    
    @objc
    func connect(_ address: NSString, username: NSString, password: NSString, vpnType: NSString, mtu: NSNumber, findEventsWithResolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) -> Void {
        let vpnManager = NEVPNManager.shared()
        let kcs = KeychainService()

        vpnManager.loadFromPreferences { (error) -> Void in

            if error != nil {
                print("VPN Preferences error: 1")
            } else {
                let p = NEVPNProtocolIKEv2()

                p.username = username as String
                p.remoteIdentifier = address as String
                p.serverAddress = address as String

                kcs.save(key: "password", value: password as String)
                p.passwordReference = kcs.load(key: "password")
                p.authenticationMethod = NEVPNIKEAuthenticationMethod.none

                p.useExtendedAuthentication = true
                p.disconnectOnSleep = false

                vpnManager.protocolConfiguration = p
                vpnManager.isEnabled = true
                
                let defaultErr = NSError()

                vpnManager.saveToPreferences(completionHandler: { (error) -> Void in
                    if error != nil {
                        print("VPN Preferences error: 2")
                        rejecter("VPN_ERR", "VPN Preferences error: 2", defaultErr)
                    } else {
                        vpnManager.loadFromPreferences(completionHandler: { error in

                            if error != nil {
                                print("VPN Preferences error: 2")
                                rejecter("VPN_ERR", "VPN Preferences error: 2", defaultErr)
                            } else {
                                var startError: NSError?

                                do {
                                    try vpnManager.connection.startVPNTunnel()
                                } catch let error as NSError {
                                    startError = error
                                    print(startError ?? "VPN Manager cannot start tunnel")
                                    rejecter("VPN_ERR", "VPN Manager cannot start tunnel", startError)
                                } catch {
                                    print("Fatal Error")
                                    rejecter("VPN_ERR", "Fatal Error", NSError(domain: "", code: 200, userInfo: nil))
                                    fatalError()
                                }
                                if startError != nil {
                                    print("VPN Preferences error: 3")
                                    print(startError ?? "Start Error")
                                    rejecter("VPN_ERR", "VPN Preferences error: 3", startError)
                                } else {
                                    print("VPN started successfully..")
                                    findEventsWithResolver(nil)
                                }
                            }
                        })
                    }
                })
            }
        }
        
    }
    
    @objc
    func disconnect(_ findEventsWithResolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) -> Void {
        let vpnManager = NEVPNManager.shared()
        vpnManager.connection.stopVPNTunnel()
        findEventsWithResolver(nil)
    }
    
    @objc
    func getCurrentState(_ findEventsWithResolver:RCTPromiseResolveBlock, rejecter:RCTPromiseRejectBlock) -> Void {
        let vpnManager = NEVPNManager.shared()
        let status = checkNEStatus(status: vpnManager.connection.status)
        if(status.intValue < 5){
            findEventsWithResolver(status)
        } else {
            rejecter("VPN_ERR", "Unknown state", NSError())
            fatalError()
        }
    }
    
    @objc
    func getCharonErrorState(_ findEventsWithResolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) -> Void {
        findEventsWithResolver(nil)
    }

}


func checkNEStatus( status:NEVPNStatus ) -> NSNumber {
    switch status {
    case .connecting:
        return 1
    case .connected:
        return 2
    case .disconnecting:
        return 3
    case .disconnected:
        return 0
    case .invalid:
        return 0
    case .reasserting:
        return 4
    @unknown default:
        return 5
    }
}
