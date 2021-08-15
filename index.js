"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.disconnect = exports.getCharonErrorState = exports.getCurrentState = exports.start = exports.save = exports.connect = exports.prepare = exports.onStateChangedListener = exports.removeOnStateChangeListener = exports.STATE_CHANGED_EVENT_NAME = exports.CharonErrorState = exports.VpnState = void 0;
const react_native_1 = require("react-native");
var VpnState;
(function (VpnState) {
    VpnState[VpnState["disconnected"] = 0] = "disconnected";
    VpnState[VpnState["connecting"] = 1] = "connecting";
    VpnState[VpnState["connected"] = 2] = "connected";
    VpnState[VpnState["disconnecting"] = 3] = "disconnecting";
    VpnState[VpnState["genericError"] = 4] = "genericError";
})(VpnState = exports.VpnState || (exports.VpnState = {}));
var CharonErrorState;
(function (CharonErrorState) {
    CharonErrorState[CharonErrorState["NO_ERROR"] = 0] = "NO_ERROR";
    CharonErrorState[CharonErrorState["AUTH_FAILED"] = 1] = "AUTH_FAILED";
    CharonErrorState[CharonErrorState["PEER_AUTH_FAILED"] = 2] = "PEER_AUTH_FAILED";
    CharonErrorState[CharonErrorState["LOOKUP_FAILED"] = 3] = "LOOKUP_FAILED";
    CharonErrorState[CharonErrorState["UNREACHABLE"] = 4] = "UNREACHABLE";
    CharonErrorState[CharonErrorState["GENERIC_ERROR"] = 5] = "GENERIC_ERROR";
    CharonErrorState[CharonErrorState["PASSWORD_MISSING"] = 6] = "PASSWORD_MISSING";
    CharonErrorState[CharonErrorState["CERTIFICATE_UNAVAILABLE"] = 7] = "CERTIFICATE_UNAVAILABLE";
    CharonErrorState[CharonErrorState["UNDEFINED"] = 8] = "UNDEFINED";
})(CharonErrorState = exports.CharonErrorState || (exports.CharonErrorState = {}));
const stateChanged = new react_native_1.NativeEventEmitter(react_native_1.NativeModules.RNIpSecVpn);
exports.STATE_CHANGED_EVENT_NAME = "stateChanged";
exports.removeOnStateChangeListener = (stateChangedEvent) => {
    stateChangedEvent.remove();
};
exports.onStateChangedListener = (callback) => {
    return stateChanged.addListener(exports.STATE_CHANGED_EVENT_NAME, (e) => callback(e));
};
exports.prepare = react_native_1.NativeModules.RNIpSecVpn.prepare;
exports.connect = (address, username, password, vpnType, mtu) => react_native_1.NativeModules.RNIpSecVpn.connect(address || "", username || "", password || "", vpnType || "", mtu || 1400);
exports.save = (address, username, p12password, p12b64, commonname, remoteidentifier, ondemand) => react_native_1.NativeModules.RNIpSecVpn.save(address || "", username || "", p12password || "", p12b64 || "", commonname || "", remoteidentifier || "", ondemand || false);
exports.start = react_native_1.NativeModules.RNIpSecVpn.start;
exports.getCurrentState = react_native_1.NativeModules.RNIpSecVpn.getCurrentState;
exports.getCharonErrorState = react_native_1.NativeModules.RNIpSecVpn.getCharonErrorState;
exports.disconnect = react_native_1.NativeModules.RNIpSecVpn.disconnect;
exports.default = react_native_1.NativeModules.RNIpSecVpn;
//# sourceMappingURL=index.js.map