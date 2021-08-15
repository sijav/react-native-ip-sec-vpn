//
//  RNIpSecVpnBridge.m
//  RNIpSecVpn
//
//  Copyright © 2019 Sijav. All rights reserved.
//

#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(RNIpSecVpn, RCTEventEmitter)

RCT_EXTERN_METHOD(prepare:(RCTPromiseResolveBlock)findEventsWithResolver rejecter:(RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(connect:(NSString *)address username:(NSString *)username password:(NSString *)password vpnType:(NSString *)vpnType mtu:(NSNumber *_Nonnull)mtu findEventsWithResolver:(RCTPromiseResolveBlock)findEventsWithResolver rejecter:(RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(save:(NSString *)address username:(NSString *)username p12password:(NSString *)p12password p12b64:(NSString *)p12b64 commonname:(NSString *)commonname remoteidentifier:(NSString *)remoteidentifier ondemand:(BOOL *)ondemand findEventsWithResolver:(RCTPromiseResolveBlock)findEventsWithResolver rejecter:(RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(start:(RCTPromiseResolveBlock)findEventsWithResolver rejecter:(RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(disconnect:(RCTPromiseResolveBlock)findEventsWithResolver rejecter:(RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(getCurrentState:(RCTPromiseResolveBlock)findEventsWithResolver rejecter:(RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(getCharonErrorState:(RCTPromiseResolveBlock)findEventsWithResolver rejecter:(RCTPromiseRejectBlock)rejecter)

@end
