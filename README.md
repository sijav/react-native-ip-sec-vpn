# react-native-ip-sec-vpn

## Getting started

Plugin can be installed using npm<br>
With yarn:<br>
`$ yarn add react-native-ip-sec-vpn --save`<br>
Or with npm:<br>
`$ npm install react-native-ip-sec-vpn --save`<br>

### Mostly automatic installation

on react native >60 no need to do anything but for manualing installation run the code below

`$ react-native link react-native-ip-sec-vpn`

## Example

To run example:

- make sure the module folder has no node_modules
- install the dependencies on the example folder using `yarn` or `npm i`
- run the project:

```
npx react-native run-android
```

## Usage

```javascript
import {prepare, connect} from "react-native-ip-sec-vpn";
...
useEffect(() => {
	prepare();
}); /// or use componentDidmount in case of a class component
...
connect(address, username, password)
```

### see example folder.

## Methods

| Name                               | arguments                                                                                                                                                                                                                                                                                    | returns                   | Description                                                                                                 |
| ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------- | ----------------------------------------------------------------------------------------------------------- |
| prepare                            | None                                                                                                                                                                                                                                                                                         | Promise<void>             | Android: This will ask permission and do necessary setups<br>IOS: This will listen for status change on vpn |
| connect                            | address: string (address of VPN)<br>username: string (username of VPN's credentials)<br>password: string (username of VPN's credentials)<br>vpnType: string \| undefined (Android only, not implemented yet)<br>mtu: number \| undefiend (Android only, VPN's maximum transmission unit)<br> | Promise<void>             | Connect to vpn with provided credentials                                                                    |
| getCurrentState                    | None                                                                                                                                                                                                                                                                                         | Promise<VpnState>         | Get current VPN state                                                                                       |
| getCharonErrorState (Android only) | None                                                                                                                                                                                                                                                                                         | Promise<CharonErrorState> | Get current VPN Error state (Android only)                                                                  |
| disconnect                         | None                                                                                                                                                                                                                                                                                         | Promise<void>             | Disconnect the VPN                                                                                          |
| onStateChangedListener             | callback: (state: { state: VpnState; charonState: CharonErrorState }) => void                                                                                                                                                                                                                | EmitterSubscription       | Will call the callback on state change                                                                      |
| removeOnStateChangeListener        | stateChangedEvent: EmitterSubscription                                                                                                                                                                                                                                                       | void                      | Remove the state change listener                                                                            |

## Enums

| Name             | Values                                                                                                                                                                                                                                                                                                                                                             | Description       |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------- |
| VpnState         | disconnected = 0 (VPN is disconnected)<br>connecting = 1 (VPN is connecting)<br>connected = 2 (VPN is connected)<br>disconnecting = 3 (VPN is disconnecting)<br>genericError = 4 (VPN encountered an error charon state on android to find out the error)                                                                                                          | VPN current state |
| CharonErrorState | NO_ERROR = 0 (VPN has no error)<br>AUTH_FAILED = 1 (Wrong credentials)<br>PEER_AUTH_FAILED = 2<br>LOOKUP_FAILED = 3 (Wrong VPN URL)<br>UNREACHABLE = 4 (VPN URL is unreachable)<br>GENERIC_ERROR = 5<br>PASSWORD_MISSING = 6 (No password has been provided)<br>CERTIFICATE_UNAVAILABLE = 7 (Certification has not been provided)<br>UNDEFINED = 8 (Unknown error) | VPN Error         |
