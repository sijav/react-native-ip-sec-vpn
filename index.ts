import { NativeEventEmitter, NativeModules, EmitterSubscription } from "react-native";

// the generic VPN state for all platforms.
export enum VpnState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  genericError,
}

/// the error state from `VpnStateService`.
/// only available for Android device.
export enum CharonErrorState {
  NO_ERROR,
  AUTH_FAILED,
  PEER_AUTH_FAILED,
  LOOKUP_FAILED,
  UNREACHABLE,
  GENERIC_ERROR,
  PASSWORD_MISSING,
  CERTIFICATE_UNAVAILABLE,
  UNDEFINED,
}

const stateChanged: NativeEventEmitter = new NativeEventEmitter(NativeModules.RNIpSecVpn);

// receive state change from VPN service.
export const STATE_CHANGED_EVENT_NAME: string = "stateChanged";

// remove change listener
export const removeOnStateChangeListener: (stateChangedEvent: EmitterSubscription) => void = (stateChangedEvent) => {
  stateChangedEvent.remove();
};

// set a change listener
export const onStateChangedListener: (
  callback: (state: { state: VpnState; charonState: CharonErrorState }) => void
) => EmitterSubscription = (callback) => {
  return stateChanged.addListener(STATE_CHANGED_EVENT_NAME, (e: { state: VpnState; charonState: CharonErrorState }) => callback(e));
};

// prepare for vpn connection.
//
// android:
//   for first connection it will show a dialog to ask for permission.
//   when your connection was interrupted by another VPN connection,
//   you should prepare again before reconnect.
//   also if activity isn't running yet,
//   the activity can be null and will raise an exception
//   in this case prepare should be called once again when the activity is running.
//
// ios:
//   create a watch for state change
//   does not raise anything
export const prepare: () => Promise<void> = NativeModules.RNIpSecVpn.prepare;

// connect to VPN.
//
// use given credentials to connect VPN (ikev2-eap).
// this will create a background VPN service.
// mtu is only available on android.
export const connect: (address: string, username: string, password: string, vpnType?: string, mtu?: number) => Promise<void> = (
  address,
  username,
  password,
  vpnType,
  mtu
) => NativeModules.RNIpSecVpn.connect(address || "", username || "", password || "", vpnType || "", mtu || 1400);

export const save: (address: string, username: string, p12password: string, p12b64?: string, commonname?: string, remoteidentifier?: string, ondemand?: boolean) => Promise<void> = (
  address,
  username,
  p12password,
  p12b64,
  commonname,
  remoteidentifier,
  ondemand
) => NativeModules.RNIpSecVpn.save(address || "", username || "", p12password || "", p12b64 || "", commonname || "", remoteidentifier || "", ondemand || false);
export const start: () => Promise<void> = NativeModules.RNIpSecVpn.start;

// get current state
export const getCurrentState: () => Promise<VpnState> = NativeModules.RNIpSecVpn.getCurrentState;

// get current error state from `VpnStateService`. (Android only will recieve no error on ios)
// when [VpnState.genericError] is receivedon android, details of error can be
// inspected by [CharonErrorState].
export const getCharonErrorState: () => Promise<CharonErrorState> = NativeModules.RNIpSecVpn.getCharonErrorState;

// disconnect and stop VPN service.
// does not raise any exception
export const disconnect: () => Promise<void> = NativeModules.RNIpSecVpn.disconnect;

export default NativeModules.RNIpSecVpn;
