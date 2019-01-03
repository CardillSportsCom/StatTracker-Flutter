// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:async';
import 'dart:convert' show json;

import "package:http/http.dart" as http;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: <String>[
    'email',
  ],
);

void main() {
  runApp(
    MaterialApp(
      title: 'Google Sign In',
      home: SignInDemo(),
    ),
  );
}

class SignInDemo extends StatefulWidget {
  @override
  State createState() => SignInDemoState();
}

class SignInDemoState extends State<SignInDemo> {
  GoogleSignInAccount _currentUser;
  String _contactText;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
      });
      if (_currentUser != null) {
        _handleAuth();
      }
    });
    _googleSignIn.signInSilently();
  }

  Future<void> _handleAuth() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
//TODO you are stuck trying to make this auth POST call work. it returns 500 error
    GoogleSignInAuthentication authentication = await _currentUser.authentication;
    var authRequestBody = json.encode(AuthRequestBody(authentication.idToken));
    print(authRequestBody);
    Response response = await http.post("https://test-cardillsports-stattracker.herokuapp.com/auth",
        headers: { HttpHeaders.contentTypeHeader: 'application/json' },
        body: authRequestBody);
    AuthResponseBody authResponse = json.decode(response.body);

    prefs.setString("token-key", authResponse.token);


    var leaguesRequest = await http.get("https://test-cardillsports-stattracker.herokuapp.com/player/leagues/" + authResponse.player.id,
    headers: {"Authorization": prefs.get("token-key")});

    print(leaguesRequest);
  }

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  Future<void> _handleSignOut() async {
    _googleSignIn.disconnect();
  }

  Widget _buildBody() {
    if (_currentUser != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          ListTile(
            leading: GoogleUserCircleAvatar(
              identity: _currentUser,
            ),
            title: Text(_currentUser.displayName),
            subtitle: Text(_currentUser.email),
          ),
          const Text("Signed in successfully."),
          RaisedButton(
            child: const Text('SIGN OUT'),
            onPressed: _handleSignOut,
          ),
          RaisedButton(
            child: const Text('REFRESH'),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          const Text("You are not currently signed in."),
          RaisedButton(
            child: const Text('SIGN IN'),
            onPressed: _handleSignIn,
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Google Sign In'),
        ),
        body: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: _buildBody(),
        ));
  }
}

class AuthRequestBody {
  final String token;

  AuthRequestBody(this.token);

  Map<String, dynamic> toJson() =>
      {
        'token': token
      };
}

class AuthResponseBody {
  String token;
  AuthPlayer player;

  AuthResponseBody(this.token, this.player);

  AuthResponseBody.fromJson(Map<String, dynamic> json)
      : token = json['token'];
}

class AuthPlayer {
  String firstName;
  String lastName;
  String email;
  String id;

  AuthPlayer(this.firstName, this.lastName, this.email, this.id);

}