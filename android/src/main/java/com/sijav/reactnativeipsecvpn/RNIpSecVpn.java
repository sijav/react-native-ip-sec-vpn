package com.sijav.reactnativeipsecvpn;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.Service;
import android.content.Intent;
import android.net.VpnService;
import android.os.Bundle;

import androidx.annotation.Nullable;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import org.strongswan.android.logic.VpnStateService;

import static android.app.Activity.RESULT_OK;

public class RNIpSecVpn extends ReactContextBaseJavaModule {

    @SuppressLint("StaticFieldLeak")
    private static ReactApplicationContext reactContext;

    private RNIpSecVpnStateHandler _RNIpSecVpnStateHandler;

    RNIpSecVpn(ReactApplicationContext context) {
        super(context);
        // Load charon bridge
        System.loadLibrary("androidbridge");
        reactContext = context;
        Intent vpnStateServiceIntent = new Intent(context, VpnStateService.class);
        _RNIpSecVpnStateHandler = new RNIpSecVpnStateHandler(this);
        context.bindService(vpnStateServiceIntent, _RNIpSecVpnStateHandler, Service.BIND_AUTO_CREATE);
    }


    void sendEvent(String eventName, @Nullable WritableMap params) {
        reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(eventName, params);
    }

    @Override
    public String getName() {
        return "RNIpSecVpn";
    }

    @ReactMethod
    public void prepare(final Promise promise) {
        Activity currentActivity = getCurrentActivity();

        if (currentActivity == null) {
            promise.reject("E_ACTIVITY_DOES_NOT_EXIST", "Activity doesn't exist");
            return;
        }
        Intent intent = VpnService.prepare(currentActivity);
        if (intent != null) {
            reactContext.addActivityEventListener(new BaseActivityEventListener() {
                public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
                    if(requestCode == 0 && resultCode == RESULT_OK){
                        promise.resolve(null);
                    } else {
                        promise.reject("PrepareError", "Failed to prepare");
                    }
                }
            });
            currentActivity.startActivityForResult(intent, 0);
        }
    }

    @ReactMethod
    public void connect(String address, String username, String password, String psk, String vpnType, Integer mtu, Promise promise) {
        if(_RNIpSecVpnStateHandler.vpnStateService == null){
            promise.reject("E_SERVICE_NOT_STARTED", "Service not started yet");
            return;
        }
        if(mtu == 0){
            mtu = 1400;
        }
        Activity currentActivity = getCurrentActivity();

        if (currentActivity == null) {
            promise.reject("E_ACTIVITY_DOES_NOT_EXIST", "Activity doesn't exist");
            return;
        }
        Intent intent = VpnService.prepare(currentActivity);
        if (intent != null) {
            promise.reject("PrepareError", "Not prepared");
            return;
        }

        Bundle profileInfo = new Bundle();
        profileInfo.putString("Address", address);
        profileInfo.putString("UserName", username);
        profileInfo.putString("Password", password);
        profileInfo.putString("VpnType", password);
        profileInfo.putString("Psk", psk);
        profileInfo.putInt("MTU", mtu);
        _RNIpSecVpnStateHandler.vpnStateService.connect(profileInfo, true);
        promise.resolve(null);
    }

    @ReactMethod
    public void getCurrentState(Promise promise){
        if(_RNIpSecVpnStateHandler.vpnStateService == null){
            promise.reject("E_SERVICE_NOT_STARTED", "Service not started yet");
            return;
        }
        VpnStateService.ErrorState errorState = _RNIpSecVpnStateHandler.vpnStateService.getErrorState();
        VpnStateService.State state = _RNIpSecVpnStateHandler.vpnStateService.getState();
        if(errorState == VpnStateService.ErrorState.NO_ERROR){
            promise.resolve(state != null ? state.ordinal() : 4);
        } else {
            promise.resolve(4);
        }
    }

    @ReactMethod
    public void getCharonErrorState(Promise promise){
        if(_RNIpSecVpnStateHandler.vpnStateService == null){
            promise.reject("E_SERVICE_NOT_STARTED", "Service not started yet");
            return;
        }
        VpnStateService.ErrorState errorState = _RNIpSecVpnStateHandler.vpnStateService.getErrorState();
        promise.resolve(errorState != null ? errorState.ordinal() : 8);
    }

    @ReactMethod
    public void disconnect(Promise promise){
        if(_RNIpSecVpnStateHandler.vpnStateService != null){
            _RNIpSecVpnStateHandler.vpnStateService.disconnect();
        }
        promise.resolve(null);
    }
}
