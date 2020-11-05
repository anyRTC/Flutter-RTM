import 'dart:async';

import 'package:flutter/services.dart';

import 'ar_rtm_plugin.dart';
import 'utils.dart';

class ARRtmChannelException implements Exception {
  final reason;
  final code;

  ARRtmChannelException(this.reason, this.code) : super();

  Map<String, dynamic> toJson() => {"reason": reason, "code": code};

  @override
  String toString() {
    return this.reason;
  }
}

class ARRtmChannel {
  /// Occurs when you receive error events.
  void Function(dynamic error) onError;

  /// Occurs when receiving a channel message.
  void Function(ARRtmMessage message, ARRtmMember fromMember)
      onMessageReceived;

  /// Occurs when a user joins the channel.
  void Function(ARRtmMember member) onMemberJoined;

  /// Occurs when a channel member leaves the channel.
  void Function(ARRtmMember member) onMemberLeft;

  /// Occurs when channel attribute updated.
  void Function(List<ARRtmChannelAttribute> attributes) onAttributesUpdated;

  /// Occurs when channel member count updated.
  void Function(int count) onMemberCountUpdated;

  final String channelId;
  final int _clientIndex;

  bool _closed;

  StreamSubscription<dynamic> _eventSubscription;

  EventChannel _addEventChannel() {
    return new EventChannel(
        'io.ar.rtm.client$_clientIndex.channel$channelId');
  }

  _eventListener(dynamic event) {
    final Map<dynamic, dynamic> map = event;
    switch (map['event']) {
      case 'onMessageReceived':
        ARRtmMessage message = ARRtmMessage.fromJson(map['message']);
        ARRtmMember member = ARRtmMember.fromJson(map);
        this?.onMessageReceived?.call(message, member);
        break;
      case 'onMemberJoined':
        ARRtmMember member = ARRtmMember.fromJson(map);
        this?.onMemberJoined?.call(member);
        break;
      case 'onMemberLeft':
        ARRtmMember member = ARRtmMember.fromJson(map);
        this?.onMemberLeft?.call(member);
        break;
      case 'onAttributesUpdated':
        List<Map<dynamic, dynamic>> attributes =
            List<Map<dynamic, dynamic>>.from(map['attributes']);
        this?.onAttributesUpdated?.call(attributes
            .map((attr) => ARRtmChannelAttribute.fromJson(attr))
            .toList());
        break;
      case 'onMemberCountUpdated':
        int count = map['count'];
        this?.onMemberCountUpdated?.call(count);
        break;
    }
  }

  ARRtmChannel(this._clientIndex, this.channelId) {
    _closed = false;
    _eventSubscription = _addEventChannel()
        .receiveBroadcastStream()
        .listen(_eventListener, onError: onError);
  }

  Future<dynamic> _callNative(String methodName, dynamic arguments) {
    return ArRtmPlugin.callMethodForChannel(methodName, {
      'clientIndex': _clientIndex,
      'channelId': channelId,
      'args': arguments
    });
  }

  Future<void> join() async {
    final res = await _callNative("join", null);
    if (res["errorCode"] != 0)
      throw ARRtmChannelException(
          "join failed errorCode:${res['errorCode']}", res['errorCode']);
  }

  Future<void> sendMessage(ARRtmMessage message,
      [bool offline, bool historical]) async {
    final res = await _callNative("sendMessage", {
      'message': message.text,
      "offline": offline,
      "historical": historical
    });
    if (res["errorCode"] != 0)
      throw ARRtmChannelException(
          "sendMessage failed errorCode:${res['errorCode']}", res['errorCode']);
  }

  Future<void> leave() async {
    final res = await _callNative("leave", null);
    if (res["errorCode"] != 0)
      throw ARRtmChannelException(
          "leave failed errorCode:${res['errorCode']}", res['errorCode']);
  }

  Future<List<ARRtmMember>> getMembers() async {
    final res = await _callNative("getMembers", null);
    if (res["errorCode"] != 0)
      throw ARRtmChannelException(
          "getMembers failed errorCode: ${res['errorCode']}", res['errorCode']);
    List<ARRtmMember> list = [];
    for (final member in res['members']) {
      list.add(ARRtmMember.fromJson(Map<String, dynamic>.from(member)));
    }
    return list;
  }

  Future<void> close() async {
    if (_closed) return null;
    await _eventSubscription.cancel();
    _closed = true;
  }

  @Deprecated('Use `ARRtmClient.releaseChannel` instead.')
  void release() {}
}
