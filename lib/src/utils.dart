class ARRtmMessage {
  String text;
  int ts;
  bool offline;

  ARRtmMessage(this.text, this.ts, this.offline);

  ARRtmMessage.fromText(String text, {this.ts = 0, this.offline = false})
      : text = text;

  ARRtmMessage.fromJson(Map<dynamic, dynamic> json)
      : text = json['text'],
        ts = json['ts'],
        offline = json['offline'];

  Map<String, dynamic> toJson() => {'text': text, 'ts': ts, 'offline': offline};

  @override
  String toString() {
    return "{text: $text, ts: $ts, offline: $offline}";
  }
}

class ARRtmMember {
  String userId;
  String channelId;

  ARRtmMember(this.userId, this.channelId);

  ARRtmMember.fromJson(Map<dynamic, dynamic> json)
      : userId = json['userId'],
        channelId = json['channelId'];

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'channelId': channelId,
      };

  @override
  String toString() {
    return "{uid: $userId, cid: $channelId}";
  }
}

class ARRtmChannelAttribute {
  String key;
  String value;
  String userId;
  int updateTs;

  ARRtmChannelAttribute(this.key, this.value, {this.userId="", this.updateTs=0});

  ARRtmChannelAttribute.fromJson(Map<dynamic, dynamic> json)
      : key = json['key'],
        value = json['value'],
        userId = json['userId'],
        updateTs = json['updateTs'];

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'userId': userId,
        'updateTs': updateTs,
      };

  @override
  String toString() {
    return "{key: $key, value: $value, userId: $userId, updateTs: $updateTs}";
  }
}

class ARRtmLocalInvitation {
  String calleeId;
  String content;
  String response;
  String channelId;
  int state;

  ARRtmLocalInvitation(
      this.calleeId, this.content, this.response, this.channelId, this.state);

  ARRtmLocalInvitation.fromJson(Map<dynamic, dynamic> json)
      : calleeId = json['calleeId'],
        content = json['content'],
        response = json['response'],
        channelId = json['channelId'],
        state = json['state'];

  Map<String, dynamic> toJson() => {
        'calleeId': calleeId,
        'content': content,
        'response': response,
        'channelId': channelId,
        'state': state,
      };

  @override
  String toString() {
    return "{calleeId: $calleeId, content: $content, response: $response, channelId: $channelId, state: $state}";
  }
}

class ARRtmRemoteInvitation {
  String callerId;
  String content;
  String response;
  String channelId;
  int state;

  ARRtmRemoteInvitation(
      this.callerId, this.content, this.response, this.channelId, this.state);

  ARRtmRemoteInvitation.fromJson(Map<dynamic, dynamic> json)
      : callerId = json['callerId'],
        content = json['content'],
        response = json['response'],
        channelId = json['channelId'],
        state = json['state'];

  Map<String, dynamic> toJson() => {
        'callerId': callerId,
        'content': content,
        'response': response,
        'channelId': channelId,
        'state': state,
      };

  @override
  String toString() {
    return "{callerId: $callerId, content: $content, response: $response, channelId: $channelId, state: $state}";
  }
}

class ARtmPeerOnlineStatus{
  String peerId;
  int state;//0在线 1连接状态不稳定（服务器连续 6 秒未收到来自 SDK 的数据包 2用户不在线

  ARtmPeerOnlineStatus.fromJson(Map<dynamic, dynamic> json)
      : peerId = json['peerId'],
        state = json['state'];
}
