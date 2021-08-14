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
let serviceIdentifier = "AutoVPN"
let userAccount = "authenticatedUser"
let accessGroup = "AutoVPN"

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

class Downloader {
    static func loadFileAsync(_ url: URL, destination: String, completion: @escaping (String?, Error?) -> Void)
        {
            let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

            let destinationUrl = documentsUrl.appendingPathComponent(destination)
            if FileManager().fileExists(atPath: destinationUrl.path)
            {
                print("File already exists [\(destinationUrl.path)]")
                completion(destinationUrl.path, nil)
            }
            else
            {
                let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                
                let task = session.dataTask(with: request, completionHandler:
                {
                    data, response, error in
                    if error == nil
                    {
                        if let response = response as? HTTPURLResponse
                        {
                            if response.statusCode == 200
                            {
                                if let data = data
                                {
                                    if let _ = try? data.write(to: destinationUrl, options: Data.WritingOptions.atomic)
                                    {
                                         completion(destinationUrl.path, error)
                                    }
                                    else
                                    {
                                         completion(destinationUrl.path, error)
                                    }
                                }
                                else
                                {
                                     completion(destinationUrl.path, error)
                                }
                            }
                        }
                    }
                    else
                    {
                         completion(destinationUrl.path, error)
                    }
                })
                task.resume()
            }
        }
}


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
    static let shared = RNIpSecVpn()
    let vpnManager = NEVPNManager.shared()
    var isConnecting = false
    @objc override static func requiresMainQueueSetup() -> Bool {
        return true
    }

    override func supportedEvents() -> [String]! {
        return [ "stateChanged" ]
    }

    func dataFromFile(_ p12Url: NSString,  completion: @escaping (Data?, Error?) -> Void)
    {
        print("Downloading Url...\(p12Url)")
        let url = URL(string: p12Url as String)!
        Downloader.loadFileAsync(url, destination: "hivpn.p12") { (path, error) in
            if(error != nil){
                return completion(nil, error)
            }
            do{
                print("Path is \(String(describing: path))")
                let data = try NSData(contentsOfFile: path!) as Data
                completion(data, nil)
            }catch {
                print("Error!! to read file")
                completion(nil, "Failed to read" as? Error)
            }
        }
    }

    @objc
    func prepare(_ findEventsWithResolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) -> Void {
        print("VPN Prepare")
        //https://stackoverflow.com/questions/39056600/nevpnmanager-check-is-connected-after-restart-the-app/47689509
        vpnManager.loadFromPreferences { (error) in
            if error != nil {
                print(error.debugDescription)
            }
            else{
                print("No error from loading VPN viewDidLoad")
            }
        }
        // Register to be notified of changes in the status. These notifications only work when app is in foreground.
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object : nil , queue: nil) {
            notification in let nevpnconn = notification.object as! NEVPNConnection
            self.sendEvent(withName: "stateChanged", body: [ "state" : checkNEStatus(status: nevpnconn.status) ])
        }
        findEventsWithResolver(nil)
    }
    
    @objc
    func connect(_ address: NSString, username: NSString, password: NSString, vpnType: NSString, mtu: NSNumber, findEventsWithResolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) -> Void {
        let kcs = KeychainService()
        print("VPN connecting...")
        if(self.isConnecting == true){
            return
        }
        self.isConnecting = true
        vpnManager.loadFromPreferences { (error) -> Void in

            if error != nil {
                print("VPN Preferences error: 1")
            } else {
                let p = NEVPNProtocolIKEv2()

                // certificate authentication
                // p.authenticationMethod = .certificate
                // p.serverAddress = VPNServerSettings.shared.vpnServerAddress
                // p.remoteIdentifier = VPNServerSettings.shared.vpnRemoteIdentifier
                // p.localIdentifier = VPNServerSettings.shared.vpnLocalIdentifier

                p.username = username as String
                p.remoteIdentifier = address as String
                p.serverAddress = address as String

                kcs.save(key: "password", value: password as String)
                p.passwordReference = kcs.load(key: "password")
                p.authenticationMethod = NEVPNIKEAuthenticationMethod.none

                //Set IKE SA (Security Association) Params...
                p.ikeSecurityAssociationParameters.encryptionAlgorithm = .algorithmAES256GCM
                p.ikeSecurityAssociationParameters.integrityAlgorithm = .SHA512
                p.ikeSecurityAssociationParameters.diffieHellmanGroup = .group20
                p.ikeSecurityAssociationParameters.lifetimeMinutes = 1440
                //p.ikeSecurityAssociationParameters.isProxy() = false

                //Set CHILD SA (Security Association) Params...
                p.childSecurityAssociationParameters.encryptionAlgorithm = .algorithmAES256GCM
                p.childSecurityAssociationParameters.integrityAlgorithm = .SHA512
                p.childSecurityAssociationParameters.diffieHellmanGroup = .group20
                p.childSecurityAssociationParameters.lifetimeMinutes = 1440
                p.useExtendedAuthentication = true
                p.disconnectOnSleep = false
                p.enablePFS = true
                p.disableMOBIKE = false
                p.deadPeerDetectionRate = .medium
                p.disableRedirect = true

                self.vpnManager.protocolConfiguration = p
                self.vpnManager.isEnabled = true
                self.vpnManager.isOnDemandEnabled = false

    /*
    let p12Password = "*****" // password from file certificate "****.p12"
    let vpnServerAddress = "******"
    let vpnRemoteIdentifier = "*******" // In my case same like vpn server address
    let vpnLocalIdentifier = "phone@caf1e9*******.algo"
    let vpnServerCertificateIssuerCommonName = "*******" // In my case same like vpn server address
    */
                // p.serverCertificateIssuerCommonName = vpnServerCertificateIssuerCommonName
                // p.disconnectOnSleep = false
                // p.certificateType = .ECDSA384
                // p.identityDataPassword = p12Password
                // p.identityData = self.dataFromFile()
                // vpnManager.protocolConfiguration = p
                // vpnManager.isEnabled = true


                let defaultErr = NSError()
                print("SAVE TO PREFERENCES...")
                self.vpnManager.saveToPreferences(completionHandler: { (error) -> Void in
                    if error != nil {
                        print("VPN Preferences error: 2")
                        rejecter("VPN_ERR", "VPN Preferences error: 2", defaultErr)
                    } else {
                        self.vpnManager.loadFromPreferences(completionHandler: { error in

                            if error != nil {
                                print("VPN Preferences error: 2")
                                rejecter("VPN_ERR", "VPN Preferences error: 2", defaultErr)
                            } else {
                                var startError: NSError?

                                do {
                                    try self.vpnManager.connection.startVPNTunnel()
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
                    self.isConnecting = false
                })
            }
        }
        
    }

    @objc
    func save(_ address: NSString, username: NSString, p12password: NSString, p12b64: NSString, commonname: NSString, remoteidentifier: NSString, ondemand: Bool, findEventsWithResolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) -> Void {
        print("Saving VPN settings...")
        if(self.isConnecting == true){
            return
        }
        self.isConnecting = true
        vpnManager.loadFromPreferences { (error) -> Void in
            if error != nil {
                print("VPN Preferences error: 1")
            } else {
                let data = Data(base64Encoded: p12b64 as String, options: .ignoreUnknownCharacters)
                print("p12 decoded")
                    let p = NEVPNProtocolIKEv2()
                    p.identityDataPassword = p12password as String
                    p.identityData = data
                    p.authenticationMethod = .certificate
                    p.serverCertificateIssuerCommonName = commonname as String
                    p.remoteIdentifier = remoteidentifier as String
                    p.localIdentifier = username as String
                    p.serverAddress = address as String

                    //Set IKE SA (Security Association) Params...
                    p.ikeSecurityAssociationParameters.encryptionAlgorithm = .algorithmAES256GCM
                    p.ikeSecurityAssociationParameters.integrityAlgorithm = .SHA512
                    p.ikeSecurityAssociationParameters.diffieHellmanGroup = .group20
                    p.ikeSecurityAssociationParameters.lifetimeMinutes = 1440
                    //p.ikeSecurityAssociationParameters.isProxy() = false

                    //Set CHILD SA (Security Association) Params...
                    p.childSecurityAssociationParameters.encryptionAlgorithm = .algorithmAES256GCM
                    p.childSecurityAssociationParameters.integrityAlgorithm = .SHA512
                    p.childSecurityAssociationParameters.diffieHellmanGroup = .group20
                    p.childSecurityAssociationParameters.lifetimeMinutes = 1440

                    p.disconnectOnSleep = false
                    p.certificateType = .RSA

                    p.useExtendedAuthentication = true
                    p.disconnectOnSleep = false
                    p.enablePFS = true
                    p.disableMOBIKE = false
                    p.deadPeerDetectionRate = .medium
                    p.disableRedirect = true

                    self.vpnManager.protocolConfiguration = p
                    self.vpnManager.isEnabled = true
                    self.vpnManager.isOnDemandEnabled = ondemand

                   let rule = NEOnDemandRuleConnect()
                   rule.interfaceTypeMatch = .any
                   self.vpnManager.onDemandRules = [rule]

                    let defaultErr = NSError()
                    print("SAVE TO PREFERENCES...")
                    self.vpnManager.saveToPreferences(completionHandler: { (error) -> Void in
                        if error != nil {
                            print("VPN Preferences error: 2")
                            rejecter("VPN_ERR", "VPN Preferences error: 2", defaultErr)
                        } else {
                            print("VPN saved successfully..")
                            findEventsWithResolver(nil) 
                        }
                        self.isConnecting = false
                    })
                }
        }
        
    }


    @objc
    func start(_ findEventsWithResolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) -> Void {
        print("Start VPN connecting...")
        if(self.isConnecting == true){
            return
        }
        self.isConnecting = true
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
        self.isConnecting = false
    }

    @objc
    func disconnect(_ findEventsWithResolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) -> Void {
        vpnManager.connection.stopVPNTunnel()
        findEventsWithResolver(nil)
    }
    
    @objc
    func getCurrentState(_ findEventsWithResolver:RCTPromiseResolveBlock, rejecter:RCTPromiseRejectBlock) -> Void {
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
