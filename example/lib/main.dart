import 'package:flutter/material.dart';
import 'dart:async';

import 'package:ar_rtm/ar_rtm.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLogin = false;
  bool _isInChannel = false;
  bool _isSubsribe = false;

  final _userNameController = TextEditingController();
  final _peerUserIdController = TextEditingController();
  final _subUserIdController = TextEditingController();
  final _peerMessageController = TextEditingController();
  final _channelNameController = TextEditingController();
  final _channelMessageController = TextEditingController();

  final _infoStrings = <String>[];

  ARRtmClient _client;
  ARRtmChannel _channel;

  @override
  void initState() {
    super.initState();
    _createClient();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('anyRTC Real Time Message'),
          ),
          body: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildLogin(),
                _buildQueryOnlineStatus(),
                _buildSubscribePeersOnlineStatus(),
                _buildSendPeerMessage(),
                _buildJoinChannel(),
                _buildGetMembers(),
                _buildSendChannelMessage(),
                _buildInfoList(),
              ],
            ),
          )),
    );
  }

  void _createClient() async {
    _client =
    await ARRtmClient.createInstance("YOUR APPID");
    _client.onMessageReceived = (ARRtmMessage message, String peerId) {
      _log("Peer msg: " + peerId + ", msg: " + message.text);
    };
    _client.onConnectionStateChanged = (int state, int reason) {
      _log('Connection state changed: ' +
          state.toString() +
          ', reason: ' +
          reason.toString());
      if (state == 5) {
        _client.logout();
        _log('Logout.');
        setState(() {
          _isLogin = false;
        });
      }
    };
    _client.onPeersOnlineStatusChanged =(List<ARtmPeerOnlineStatus> list){
      _log("onPeersOnlineStatusChanged peerId: " + list[0].peerId + ', state: ' + list[0].state.toString());
    };
  }

  Future<ARRtmChannel> _createChannel(String name) async {
    ARRtmChannel channel = await _client.createChannel(name);
    channel.onMemberJoined = (ARRtmMember member) {
      _log(
          "Member joined: " + member.userId + ', channel: ' + member.channelId);
    };
    channel.onMemberLeft = (ARRtmMember member) {
      _log("Member left: " + member.userId + ', channel: ' + member.channelId);
    };
    channel.onMessageReceived =
        (ARRtmMessage message, ARRtmMember member) {
      _log("Channel msg: " + member.userId + ", msg: " + message.text);
    };
    return channel;
  }

  static TextStyle textStyle = TextStyle(fontSize: 18, color: Colors.blue);

  Widget _buildLogin() {
    return Row(children: <Widget>[
      _isLogin
          ? new Expanded(
              child: new Text('User Id: ' + _userNameController.text,
                  style: textStyle))
          : new Expanded(
              child: new TextField(
                  controller: _userNameController,
                  decoration: InputDecoration(hintText: 'Input your user id'))),
      new OutlineButton(
        child: Text(_isLogin ? 'Logout' : 'Login', style: textStyle),
        onPressed: _toggleLogin,
      )
    ]);
  }

  Widget _buildQueryOnlineStatus() {
    if (!_isLogin) {
      return Container();
    }
    return Row(children: <Widget>[
      new Expanded(
          child: new TextField(
              controller: _peerUserIdController,
              decoration: InputDecoration(hintText: 'Input peer user id'))),
      new OutlineButton(
        child: Text('Query Online', style: textStyle),
        onPressed: _toggleQuery,
      )
    ]);
  }

  Widget _buildSubscribePeersOnlineStatus() {
    if (!_isLogin) {
      return Container();
    }
    return Row(children: <Widget>[
      _isSubsribe
          ? new Expanded(
          child: new Text('已订阅: ' + _subUserIdController.text,
              style: textStyle))
          : new Expanded(
          child: new TextField(
              controller: _subUserIdController,
              decoration: InputDecoration(hintText: 'Input subscribe peerId'))),
      new OutlineButton(
        child: Text(_isSubsribe ? 'UnSubscribe' : 'Subscribe',
            style: textStyle),
        onPressed: _toggleSubscribe,
      )
    ]);
  }

  Widget _buildSendPeerMessage() {
    if (!_isLogin) {
      return Container();
    }
    return Row(children: <Widget>[
      new Expanded(
          child: new TextField(
              controller: _peerMessageController,
              decoration: InputDecoration(hintText: 'Input peer message'))),
      new OutlineButton(
        child: Text('Send to Peer', style: textStyle),
        onPressed: _toggleSendPeerMessage,
      )
    ]);
  }

  Widget _buildJoinChannel() {
    if (!_isLogin) {
      return Container();
    }
    return Row(children: <Widget>[
      _isInChannel
          ? new Expanded(
              child: new Text('Channel: ' + _channelNameController.text,
                  style: textStyle))
          : new Expanded(
              child: new TextField(
                  controller: _channelNameController,
                  decoration: InputDecoration(hintText: 'Input channel id'))),
      new OutlineButton(
        child: Text(_isInChannel ? 'Leave Channel' : 'Join Channel',
            style: textStyle),
        onPressed: _toggleJoinChannel,
      )
    ]);
  }

  Widget _buildSendChannelMessage() {
    if (!_isLogin || !_isInChannel) {
      return Container();
    }
    return Row(children: <Widget>[
      new Expanded(
          child: new TextField(
              controller: _channelMessageController,
              decoration: InputDecoration(hintText: 'Input channel message'))),
      new OutlineButton(
        child: Text('Send to Channel', style: textStyle),
        onPressed: _toggleSendChannelMessage,
      )
    ]);
  }

  Widget _buildGetMembers() {
    if (!_isLogin || !_isInChannel) {
      return Container();
    }
    return Row(children: <Widget>[
      new OutlineButton(
        child: Text('Get Members in Channel', style: textStyle),
        onPressed: _toggleGetMembers,
      )
    ]);
  }

  Widget _buildInfoList() {
    return Expanded(
        child: Container(
            child: ListView.builder(
      itemExtent: 28,
      itemBuilder: (context, i) {
        return ListTile(
          contentPadding: const EdgeInsets.all(0.0),
          title: Text(_infoStrings[i]),
        );
      },
      itemCount: _infoStrings.length,
    )));
  }

  void _toggleLogin() async {
    if (_isLogin) {
      try {
        await _client.logout();
        _log('Logout success.');

        setState(() {
          _isLogin = false;
          _isInChannel = false;
        });
      } catch (errorCode) {
        _log('Logout error: ' + errorCode.toString());
      }
    } else {
      String userId = _userNameController.text;
      if (userId.isEmpty) {
        _log('Please input your user id to login.');
        return;
      }

      try {
        await _client.login(null, userId);
        _log('Login success: ' + userId);
        setState(() {
          _isLogin = true;
        });
      } catch (errorCode) {
        _log('Login error: ' + errorCode.toString());
      }
    }
  }

  void _toggleQuery() async {
    String peerUid = _peerUserIdController.text;
    if (peerUid.isEmpty) {
      _log('Please input peer user id to query.');
      return;
    }
    try {
      Map<dynamic, dynamic> result =
          await _client.queryPeersOnlineStatus([peerUid]);
      _log('Query result: ' + result.toString());
    } catch (errorCode) {
      _log('Query error: ' + errorCode.toString());
    }
  }

  void _toggleSendPeerMessage() async {
    String peerUid = _peerUserIdController.text;
    if (peerUid.isEmpty) {
      _log('Please input peer user id to send message.');
      return;
    }

    String text = _peerMessageController.text;
    if (text.isEmpty) {
      _log('Please input text to send.');
      return;
    }

    try {
      ARRtmMessage message = ARRtmMessage.fromText(text);
      _log(message.text);
      await _client.sendMessageToPeer(peerUid, message, false);
      _log('Send peer message success.');
    } catch (errorCode) {
      _log('Send peer message error: ' + errorCode.toString());
    }
  }

  void _toggleSubscribe() async {
      if(_isSubsribe){
        List<String> list = [_subUserIdController.text];
        await _client.unsubscribePeersOnlineStatus(list);
        _subUserIdController.text = null;
        setState(() {
          _isSubsribe = false;
        });
      }else{
        List<String> list = [_subUserIdController.text];
        await _client.subscribePeersOnlineStatus(list);
        setState(() {
          _isSubsribe = true;
        });
      }
  }


  void _toggleJoinChannel() async {
    if (_isInChannel) {
      try {
        await _channel.leave();
        _log('Leave channel success.');
        await _client.releaseChannel(_channel.channelId);
        _channelMessageController.text = null;
        setState(() {
          _isInChannel = false;
        });
      } catch (errorCode) {
        _log('Leave channel error: ' + errorCode.toString());
      }
    } else {
      String channelId = _channelNameController.text;
      if (channelId.isEmpty) {
        _log('Please input channel id to join.');
        return;
      }

      try {
        _channel = await _createChannel(channelId);
        await _channel.join();
        _log('Join channel success.');

        setState(() {
          _isInChannel = true;
        });
      } catch (errorCode) {
        _log('Join channel error: ' + errorCode.toString());
      }
    }
  }

  void _toggleGetMembers() async {
    try {
      List<ARRtmMember> members = await _channel.getMembers();
      _log('Members: ' + members.toString());
    } catch (errorCode) {
      _log('GetMembers failed: ' + errorCode.toString());
    }
  }

  void _toggleSendChannelMessage() async {
    String text = _channelMessageController.text;
    if (text.isEmpty) {
      _log('Please input text to send.');
      return;
    }
    try {
      await _channel.sendMessage(ARRtmMessage.fromText(text));
      _log('Send channel message success.');
    } catch (errorCode) {
      _log('Send channel message error: ' + errorCode.toString());
    }
  }

  void _log(String info) {
    print(info);
    setState(() {
      _infoStrings.insert(0, info);
    });
  }
}
