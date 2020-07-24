import React, { useState, useEffect } from 'react';
import {
  VpnState,
  CharonErrorState,
  connect,
  disconnect,
  getCharonErrorState,
  getCurrentState,
  onStateChangedListener,
  prepare,
} from 'react-native-ip-sec-vpn';
import { SafeAreaView, StyleSheet, ScrollView, View, Text, StatusBar, TextInput, Button } from 'react-native';

import { Header, Colors } from 'react-native/Libraries/NewAppScreen';

const styles = StyleSheet.create({
  scrollView: {
    backgroundColor: Colors.lighter,
  },
  engine: {
    position: 'absolute',
    right: 0,
  },
  body: {
    backgroundColor: Colors.white,
  },
  sectionContainer: {
    marginTop: 32,
    paddingHorizontal: 24,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: '600',
    color: Colors.black,
  },
  sectionDescription: {
    marginTop: 8,
    fontSize: 18,
    fontWeight: '400',
    color: Colors.dark,
  },
  highlight: {
    fontWeight: '700',
  },
  footer: {
    color: Colors.dark,
    fontSize: 12,
    fontWeight: '600',
    padding: 4,
    paddingRight: 12,
    textAlign: 'right',
  },
  fixToText: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 5,
  },
  textInput: {
    height: 30,
    borderColor: 'gray',
    color: 'black',
    borderWidth: 1,
    padding: 5,
  },
});

export const App = () => {
  const [credentials, setCredentials] = useState({
    address: '',
    username: '',
    password: '',
  });
  const [state, setState] = useState(VpnState[VpnState.disconnected]);
  const [charonState, setCharonState] = useState(CharonErrorState[CharonErrorState.NO_ERROR]);
  useEffect(() => {
    prepare()
      .then(() => console.log('prepared'))
      .catch((err) => {
        // only happen on android when activity is not running yet
        console.log(err);
        prepare();
      });
    onStateChangedListener((e) => {
      console.log('state changed: ', e);
      setState(VpnState[e.state]);
      setCharonState(CharonErrorState[e.charonState]);
    });
  }, []);
  return (
    <>
      <StatusBar barStyle="dark-content" />
      <SafeAreaView>
        <ScrollView contentInsetAdjustmentBehavior="automatic" style={styles.scrollView}>
          <Header />
          {global.HermesInternal == null ? null : (
            <View style={styles.engine}>
              <Text style={styles.footer}>Engine: Hermes</Text>
            </View>
          )}
          <View style={styles.body}>
            <View style={styles.sectionContainer}>
              <Text style={styles.sectionTitle}>React Native IPsec VPN example</Text>
              <View style={styles.sectionDescription}>
                <Text>Current State {state}</Text>
                <Text>Current Charon State {charonState}</Text>
              </View>
            </View>
            <View style={styles.sectionContainer}>
              <Text style={styles.sectionTitle}>Credentials</Text>
              <View style={styles.sectionDescription}>
                <Text>Address:</Text>
                <TextInput
                  style={styles.textInput}
                  placeholder="Address"
                  autoCapitalize="none"
                  keyboardType="url"
                  textContentType="URL"
                  onChangeText={(address) => setCredentials({ ...credentials, address })}
                  value={credentials.address}
                />
                <Text>Username:</Text>
                <TextInput
                  style={styles.textInput}
                  placeholder="Username"
                  autoCapitalize="none"
                  keyboardType="default"
                  autoCompleteType="username"
                  textContentType="username"
                  onChangeText={(username) => setCredentials({ ...credentials, username })}
                  value={credentials.username}
                />
                <Text>Password:</Text>
                <TextInput
                  style={styles.textInput}
                  placeholder="Password"
                  autoCapitalize="none"
                  autoCompleteType="password"
                  textContentType="password"
                  onChangeText={(password) => setCredentials({ ...credentials, password })}
                  value={credentials.password}
                />
              </View>
            </View>
            <View style={styles.sectionContainer}>
              <View style={styles.fixToText}>
                <Button
                  title="Connect"
                  onPress={() =>
                    connect(credentials.address, credentials.username, credentials.password)
                      .then(() => console.log('connected'))
                      .catch(console.log)
                  }
                />
                <Button
                  title="Disconnect"
                  onPress={() =>
                    disconnect()
                      .then(() => console.log('disconnect: '))
                      .catch(console.log)
                  }
                />
              </View>
              <View style={styles.fixToText}>
                <Button
                  title="Update State"
                  onPress={() => getCurrentState().then((_state) => console.log('getCurrentState: ', _state) || setState(VpnState[_state]))}
                />
                <Button
                  title="Update Charon State"
                  onPress={() =>
                    getCharonErrorState().then(
                      (_state) => console.log('getCharonErrorState: ', _state) || setCharonState(CharonErrorState[_state])
                    )
                  }
                />
              </View>
            </View>
          </View>
        </ScrollView>
      </SafeAreaView>
    </>
  );
};

export default App;
