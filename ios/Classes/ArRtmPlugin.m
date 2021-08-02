#import "ArRtmPlugin.h"
#import "RTMChannel.h"
#import "RTMClient.h"
#import <ARtmKit/ARtmKit.h>

@interface ArRtmPlugin() <ARtmDelegate>
  @property (strong, nonatomic) FlutterMethodChannel *methodChannel;
  @property (assign, nonatomic) NSInteger nextClientIndex;
  @property (assign, nonatomic) NSInteger nextChannelIndex;
  @property (strong, nonatomic) NSMutableDictionary<NSNumber *, RTMClient *> *AClients;
  @property (strong, nonatomic) id registrar;
  @property (strong, nonatomic) id messenger;
@end

@implementation ArRtmPlugin

+ (BOOL) isNSNull:(id)value {
  return value == [NSNull null];
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
                                   methodChannelWithName:@"org.ar.rtm"
                                   binaryMessenger:[registrar messenger]];
    ArRtmPlugin* instance = [[ArRtmPlugin alloc] init];
  instance.methodChannel = channel;
  instance.registrar = registrar;
  instance.messenger = [registrar messenger];
  instance.AClients = [NSMutableDictionary new];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleStaticMethod:(NSString *)name
                    params:(NSDictionary *)params
                    result:(FlutterResult)result {
  if ([@"createInstance" isEqualToString:name]) {
    NSString *appId = params[@"appId"];
    if (nil == appId) return result(@{@"errorCode": @(-1)});
    while (nil != _AClients[@(self.nextClientIndex)]) {
      self.nextClientIndex++;
    }
    RTMClient *rtmClient = [[RTMClient new] initWithAppId:appId clientIndex:@(self.nextClientIndex)
        messenger:_messenger];
    if (nil == rtmClient) {
      return result(@{@"errorCode": @(-1)});
    }
    _AClients[@(self.nextClientIndex)] = rtmClient;
    result(@{@"errorCode": @(0), @"index": @(self.nextClientIndex)});
    self.nextClientIndex++;
  } else if ([@"getSdkVersion" isEqualToString:name]) {
    result(@{@"errorCode": @(0), @"version": [ARtmKit getSDKVersion]});
  } else {
    result(@{@"errorCode": @(-2), @"reason": FlutterMethodNotImplemented});
  }
}

- (void)handleARtmClientMethod:(NSString *)name
                    params:(NSDictionary *)params
                    result:(FlutterResult)result {
  NSNumber *clientIndex = params[@"clientIndex"];
  NSDictionary *args = params[@"args"];
  RTMClient *rtmClient = _AClients[clientIndex];
  if (nil == rtmClient) return result(@{@"errorCode": @(-1)});

  
  if ([@"destroy" isEqualToString:name]) {
    rtmClient = nil;
    [_AClients removeObjectForKey:clientIndex];
    result(@{@"errorCode": @(0)});
  }
  else if ([@"setLog" isEqualToString:name]) {
    NSInteger size = args[@"size"] != [NSNull null] ? [args[@"size"] integerValue] : 524288;
    NSString *path = args[@"path"] != [NSNull null] ? args[@"path"] : nil;
    if (nil != path) {
      NSString *dirPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
      path = [NSString stringWithFormat:@"%@/%@", dirPath, path];
    }
    NSNumber *level = args[@"level"] != [NSNull null] ? args[@"level"] : nil;
    result(@{
             @"errorCode": @(0),
             @"results": @{
                 @"setLogFileSize": @([rtmClient.kit setLogFileSize:(int)size]),
                 @"setLogLevel": @([rtmClient.kit setLogFilters:[level integerValue]]),
                 @"setLogFile": @([rtmClient.kit setLogFile:path]),
                 }
             });
  }
  else if ([@"login" isEqualToString:name]) {
    NSString *token = args[@"token"] != [NSNull null] ? args[@"token"] : nil;
    NSString *userId = args[@"userId"];
    [rtmClient.kit loginByToken:token user:userId completion:^(ARtmLoginErrorCode errorCode) {
      result(@{@"errorCode": @(errorCode)});
    }];
  }
  else if ([@"logout" isEqualToString:name]) {
    [rtmClient.kit logoutWithCompletion:^(ARtmLogoutErrorCode errorCode) {
      result(@{@"errorCode": @(errorCode)});
    }];
  }
  else if ([@"setParameters" isEqualToString:name]) {
      [rtmClient.kit setParameters:args[@"parameters"]];
  }
  else if ([@"renewToken" isEqualToString:name]) {
    NSString *token = args[@"token"] != [NSNull null] ? args[@"token"] : nil;
    [rtmClient.kit renewToken:token completion:^(NSString *token, ARtmRenewTokenErrorCode errorCode) {
      result(@{@"errorCode": @(errorCode)});
    }];
  }
  else if ([@"queryPeersOnlineStatus" isEqualToString:name]) {
    NSArray *peerIds = args[@"peerIds"] != [NSNull null] ? args[@"peerIds"] : nil;
    [rtmClient.kit queryPeersOnlineStatus:peerIds completion:^(NSArray<ARtmPeerOnlineStatus *> *peerOnlineStatus, ARtmQueryPeersOnlineErrorCode errorCode) {
      NSMutableDictionary *members = [[NSMutableDictionary alloc] init];
      for (ARtmPeerOnlineStatus *status in peerOnlineStatus) {
          
          
        members[status.peerId] = [NSNumber numberWithBool:!status.state];
      }
      result(@{@"errorCode": @(errorCode), @"results":members});
    }];
  }
  else if ([@"sendMessageToPeer" isEqualToString:name]) {
    NSString *peerId = args[@"peerId"] != [NSNull null] ? args[@"peerId"] : nil;
    NSString *text = args[@"message"] != [NSNull null] ? args[@"message"] : nil;
    BOOL offline = args[@"offline"] != [NSNull null] ? args[@"offline"] : false;
    BOOL historical = args[@"historical"] != [NSNull null] ? args[@"historical"] : false;
    ARtmSendMessageOptions *sendMessageOption = [[ARtmSendMessageOptions alloc] init];
    sendMessageOption.enableOfflineMessaging = offline;
    sendMessageOption.enableHistoricalMessaging = historical;
    [rtmClient.kit sendMessage:[[ARtmMessage new] initWithText:text]  toPeer:peerId sendMessageOptions:sendMessageOption completion:^(ARtmSendPeerMessageErrorCode errorCode) {
      result(@{@"errorCode": @(errorCode)});
    }];
  }
  else if ([@"setLocalUserAttributes" isEqualToString:name]) {
    NSArray *attributes = args[@"attributes"];
    NSMutableArray *rtmAttributes = [[NSMutableArray alloc] init];
    for (NSDictionary* item in attributes) {
      ARtmAttribute *attribute = [[ARtmAttribute alloc] init];
      attribute.key = item[@"key"];
      attribute.value = item[@"value"];
      [rtmAttributes addObject:attribute];
    }
    [rtmClient.kit setLocalUserAttributes:rtmAttributes completion:^(ARtmProcessAttributeErrorCode errorCode) {
      result(@{@"errorCode": @(errorCode)});
    }];
  }
  else if ([@"addOrUpdateLocalUserAttributes" isEqualToString:name]) {
    NSArray *attributes = args[@"attributes"];
    NSMutableArray *rtmAttributes = [[NSMutableArray alloc] init];
    for (NSDictionary* item in attributes) {
      ARtmAttribute *attribute = [[ARtmAttribute alloc] init];
      attribute.key = item[@"key"];
      attribute.value = item[@"value"];
      [rtmAttributes addObject:attribute];
    }
    [rtmClient.kit addOrUpdateLocalUserAttributes:rtmAttributes completion:^(ARtmProcessAttributeErrorCode errorCode) {
      result(@{@"errorCode": @(errorCode)});
    }];
  }
  else if ([@"deleteLocalUserAttributesByKeys" isEqualToString:name]) {
    NSArray *keys = args[@"keys"] != [NSNull null] ? args[@"keys"] : nil;
    [rtmClient.kit deleteLocalUserAttributesByKeys:keys completion:^(ARtmProcessAttributeErrorCode errorCode) {
      result(@{@"errorCode": @(errorCode)});
    }];
  }
  else if ([@"clearLocalUserAttributes" isEqualToString:name]) {
    [rtmClient.kit clearLocalUserAttributesWithCompletion :^(ARtmProcessAttributeErrorCode errorCode) {
      result(@{@"errorCode": @(errorCode)});
    }];
  }
  else if ([@"getUserAttributes" isEqualToString:name]) {
    NSString *userId = args[@"userId"] != [NSNull null] ? args[@"userId"] : nil;
    [rtmClient.kit getUserAllAttributes:userId completion:^(NSArray<ARtmAttribute *> * _Nullable attributes, NSString *userId, ARtmProcessAttributeErrorCode errorCode) {
      NSMutableDictionary *userAttributes = [[NSMutableDictionary alloc] init];
      for (ARtmAttribute *item in attributes) {
        [userAttributes setObject:item.value forKey:item.key];
      }
      result(@{@"errorCode": @(errorCode),
               @"attributes": userAttributes});
    }];
  }
  else if ([@"getUserAttributesByKeys" isEqualToString:name]) {
    NSString *userId = args[@"userId"] != [NSNull null] ? args[@"userId"] : nil;
    NSArray *keys = args[@"keys"] != [NSNull null] ? args[@"keys"] : nil;
    [rtmClient.kit getUserAttributes:userId ByKeys:keys completion:^(NSArray<ARtmAttribute *> * _Nullable attributes, NSString *userId, ARtmProcessAttributeErrorCode errorCode) {
      NSMutableDictionary *userAttributes = [[NSMutableDictionary alloc] init];
      for (ARtmAttribute *item in attributes) {
        [userAttributes setObject:item.value forKey:item.key];
      }
      result(@{@"errorCode": @(errorCode),
               @"attributes": userAttributes});
    }];
  }
  else if ([@"setChannelAttributes" isEqualToString:name]) {
    NSString *channelId = args[@"channelId"] != [NSNull null] ? args[@"channelId"] : nil;
    NSArray *attributes = args[@"attributes"];
    BOOL notify = args[@"enableNotificationToChannelMembers"] != [NSNull null] ? args[@"enableNotificationToChannelMembers"] : false;
    NSMutableArray *rtmChannelAttributes = [[NSMutableArray alloc] init];
    for (NSDictionary* item in attributes) {
      ARtmChannelAttribute *attribute = [[ARtmChannelAttribute alloc] init];
      attribute.key = item[@"key"];
      attribute.value = item[@"value"];
      [rtmChannelAttributes addObject:attribute];
    }
    ARtmChannelAttributeOptions *channelAttributeOption = [[ARtmChannelAttributeOptions alloc] init];
    channelAttributeOption.enableNotificationToChannelMembers = notify;
    [rtmClient.kit setChannel:channelId Attributes:rtmChannelAttributes Options:channelAttributeOption  completion:^(ARtmProcessAttributeErrorCode errorCode) {
      result(@{@"errorCode": @(errorCode)});
    }];
  }
  else if ([@"addOrUpdateChannelAttributes" isEqualToString:name]) {
    NSString *channelId = args[@"channelId"] != [NSNull null] ? args[@"channelId"] : nil;
    NSArray *attributes = args[@"attributes"];
    BOOL notify = args[@"enableNotificationToChannelMembers"] != [NSNull null] ? args[@"enableNotificationToChannelMembers"] : false;
    NSMutableArray *rtmChannelAttributes = [[NSMutableArray alloc] init];
    for (NSDictionary* item in attributes) {
      ARtmChannelAttribute *attribute = [[ARtmChannelAttribute alloc] init];
      attribute.key = item[@"key"];
      attribute.value = item[@"value"];
      [rtmChannelAttributes addObject:attribute];
    }
    ARtmChannelAttributeOptions *channelAttributeOption = [[ARtmChannelAttributeOptions alloc] init];
    channelAttributeOption.enableNotificationToChannelMembers = notify;
    [rtmClient.kit addOrUpdateChannel:channelId Attributes:rtmChannelAttributes Options:channelAttributeOption  completion:^(ARtmProcessAttributeErrorCode errorCode) {
      result(@{@"errorCode": @(errorCode)});
    }];
  }
  else if ([@"deleteChannelAttributesByKeys" isEqualToString:name]) {
    NSString *channelId = args[@"channelId"] != [NSNull null] ? args[@"channelId"] : nil;
    NSArray *keys = args[@"keys"] != [NSNull null] ? args[@"keys"] : nil;
    BOOL notify = args[@"enableNotificationToChannelMembers"] != [NSNull null] ? args[@"enableNotificationToChannelMembers"] : false;
    ARtmChannelAttributeOptions *channelAttributeOption = [[ARtmChannelAttributeOptions alloc] init];
    channelAttributeOption.enableNotificationToChannelMembers = notify;
    [rtmClient.kit deleteChannel:channelId AttributesByKeys:keys Options:channelAttributeOption  completion:^(ARtmProcessAttributeErrorCode errorCode) {
      result(@{@"errorCode": @(errorCode)});
    }];
  }
  else if ([@"clearChannelAttributes" isEqualToString:name]) {
    NSString *channelId = args[@"channelId"] != [NSNull null] ? args[@"channelId"] : nil;
    BOOL notify = args[@"enableNotificationToChannelMembers"] != [NSNull null] ? args[@"enableNotificationToChannelMembers"] : false;
    ARtmChannelAttributeOptions *channelAttributeOption = [[ARtmChannelAttributeOptions alloc] init];
    channelAttributeOption.enableNotificationToChannelMembers = notify;
    [rtmClient.kit clearChannel:channelId Options:channelAttributeOption  AttributesWithCompletion:^(ARtmProcessAttributeErrorCode errorCode) {
      result(@{@"errorCode": @(errorCode)});
    }];
  }
  else if ([@"getChannelAttributes" isEqualToString:name]) {
    NSString *channelId = args[@"channelId"] != [NSNull null] ? args[@"channelId"] : nil;
    [rtmClient.kit getChannelAllAttributes:channelId completion:^(NSArray<ARtmChannelAttribute *> * _Nullable attributes, ARtmProcessAttributeErrorCode errorCode) {
      NSMutableArray<NSDictionary*> *channelAttributes = [NSMutableArray new];
      for(ARtmChannelAttribute *attribute in attributes) {
        [channelAttributes addObject:@{
                                   @"key": attribute.key,
                                   @"value": attribute.value,
                                   @"userId": attribute.lastUpdateUid,
                                   @"updateTs": [NSNumber numberWithLongLong:attribute.lastUpdateTs]
                                   }];
      }
      result(@{@"errorCode": @(errorCode),
               @"attributes": channelAttributes});
    }];
  }
  else if ([@"getChannelAttributesByKeys" isEqualToString:name]) {
    NSString *channelId = args[@"channelId"] != [NSNull null] ? args[@"channelId"] : nil;
    NSArray *keys = args[@"keys"] != [NSNull null] ? args[@"keys"] : nil;
    [rtmClient.kit getChannelAttributes:channelId ByKeys:keys completion:^(NSArray<ARtmChannelAttribute *> * _Nullable attributes, ARtmProcessAttributeErrorCode errorCode) {
      NSMutableArray<NSDictionary*> *channelAttributes = [NSMutableArray new];
      for(ARtmChannelAttribute *attribute in attributes) {
        [channelAttributes addObject:@{
                                   @"key": attribute.key,
                                   @"value": attribute.value,
                                   @"userId": attribute.lastUpdateUid,
                                   @"updateTs": [NSNumber numberWithLongLong:attribute.lastUpdateTs]
                                   }];
      }
      result(@{@"errorCode": @(errorCode),
               @"attributes": channelAttributes});
    }];
  }
  else if ([@"sendLocalInvitation" isEqualToString:name]) {
    NSString *calleeId = args[@"calleeId"] != [NSNull null] ? args[@"calleeId"] : nil;
    NSString *content = args[@"content"] != [NSNull null] ? args[@"content"] : nil;
    NSString *channelId = args[@"channelId"] != [NSNull null] ? args[@"channelId"] : nil;
    ARtmLocalInvitation *invitation = [[ARtmLocalInvitation new] initWithCalleeId:calleeId];
    if (nil == invitation) return result(@{@"errorCode": @(-1)});
    if (nil != content) {
      invitation.content = content;
    }
    if (nil != channelId) {
      invitation.channelId = channelId;
    }
    [rtmClient.callKit sendLocalInvitation:invitation completion:^(ARtmInvitationApiCallErrorCode errorCode) {
      if (errorCode == 0) {
        [rtmClient.localInvitations setObject:invitation forKey:invitation.calleeId];
      }
      result(@{@"errorCode": @(errorCode)});
    }];
  }
  else if ([@"cancelLocalInvitation" isEqualToString:name]) {
    NSString *calleeId = args[@"calleeId"] != [NSNull null] ? args[@"calleeId"] : nil;
    NSString *content = args[@"content"] != [NSNull null] ? args[@"content"] : nil;
    NSString *channelId = args[@"channelId"] != [NSNull null] ? args[@"channelId"] : nil;
    ARtmLocalInvitation *invitation = rtmClient.localInvitations[calleeId];
    if (nil == invitation) return result(@{@"errorCode": @(-1)});
    if (nil != content) {
      invitation.content = content;
    }
    if (nil != channelId) {
      invitation.channelId = channelId;
    }
    [rtmClient.callKit cancelLocalInvitation:invitation completion:^(ARtmInvitationApiCallErrorCode errorCode) {
      if (errorCode == 0 && rtmClient.localInvitations[invitation.calleeId] != nil) {
        [rtmClient.localInvitations removeObjectForKey:invitation.calleeId];
      }
      result(@{@"errorCode": @(errorCode)});
    }];
  }
  else if ([@"acceptRemoteInvitation" isEqualToString:name]) {
    NSString *response = args[@"response"] != [NSNull null] ? args[@"response"] : nil;
    NSString *callerId = args[@"callerId"] != [NSNull null] ? args[@"callerId"] : nil;
    ARtmRemoteInvitation *invitation = rtmClient.remoteInvitations[callerId];
    if (nil == invitation) return result(@{@"errorCode": @(-1)});
    if (response != nil) {
      invitation.response = response;
    }
    [rtmClient.callKit acceptRemoteInvitation:invitation completion:^(ARtmInvitationApiCallErrorCode errorCode) {
      if (errorCode == 0 && rtmClient.remoteInvitations[callerId] != nil) {
        [rtmClient.remoteInvitations removeObjectForKey:callerId];
      }
      result(@{@"errorCode": @(errorCode)});
    }];
  }
  else if ([@"refuseRemoteInvitation" isEqualToString:name]) {
    NSString *response = args[@"response"] != [NSNull null] ? args[@"response"] : nil;
    NSString *callerId = args[@"callerId"] != [NSNull null] ? args[@"callerId"] : nil;
    ARtmRemoteInvitation *invitation = rtmClient.remoteInvitations[callerId];
    if (nil == invitation) return result(@{@"errorCode": @(-1)});
    if (response != nil) {
      invitation.response = response;
    }
    [rtmClient.callKit refuseRemoteInvitation:invitation completion:^(ARtmInvitationApiCallErrorCode errorCode) {
      if (errorCode == 0 && rtmClient.remoteInvitations[callerId] != nil) {
        [rtmClient.remoteInvitations removeObjectForKey:callerId];
      }
      result(@{@"errorCode": @(errorCode)});
    }];
  }
  else if ([@"createChannel" isEqualToString:name]) {
    NSString *channelId = args[@"channelId"];
    RTMChannel *rtmChannel = [[RTMChannel alloc] initWithClientIndex:clientIndex channelId:channelId messenger:_messenger kit:rtmClient.kit];
    if (nil == rtmChannel) return result(@{@"errorCode": @(-1)});
    rtmClient.channels[channelId] = rtmChannel;
    result(@{@"errorCode": @(0)});
  }
  else if ([@"releaseChannel" isEqualToString:name]) {
    NSString *channelId = args[@"channelId"];
    if (nil == rtmClient.channels[channelId]) return result(@{@"errorCode": @(-1)});
    [rtmClient.kit destroyChannelWithId:channelId];
    [rtmClient.channels removeObjectForKey:channelId];
    result(@{@"errorCode": @(0)});
  }
  else if ([@"subscribePeersOnlineStatus" isEqualToString:name]) {
    NSArray *peerIds = args[@"peerIds"] != [NSNull null] ? args[@"peerIds"] : nil;
      [rtmClient.kit subscribePeersOnlineStatus:peerIds completion:^(ARtmPeerSubscriptionStatusErrorCode errorCode) {
          result(@{@"errorCode": @(errorCode)});
      }];
  }
  else if ([@"unsubscribePeersOnlineStatus" isEqualToString:name]) {
      NSArray *peerIds = args[@"peerIds"] != [NSNull null] ? args[@"peerIds"] : nil;
      [rtmClient.kit unsubscribePeersOnlineStatus:peerIds completion:^(ARtmPeerSubscriptionStatusErrorCode errorCode) {
          result(@{@"errorCode": @(errorCode)});
      }];
  }
  else {
    result(@{@"errorCode": @(-2), @"reason": FlutterMethodNotImplemented});
  }
}


- (void)handleARtmChannelMethod:(NSString *)name
                    params:(NSDictionary *)params
                    result:(FlutterResult)result {
  NSNumber *clientIndex = params[@"clientIndex"];
  NSString *channelId = params[@"channelId"];
  NSDictionary *args = params[@"args"];
  RTMClient *rtmClient = _AClients[clientIndex];
  
  RTMChannel *rtmChannel = rtmClient.channels[channelId];
  
  if (nil == rtmChannel) return result(@{@"errorCode": @(-1)});

  ARtmChannel *channel = rtmChannel.channel;
  if ([@"join" isEqualToString:name]) {
    [channel joinWithCompletion:^(ARtmJoinChannelErrorCode errorCode) {
      result(@{@"errorCode": @(errorCode)});
    }];
  }
  else if ([@"sendMessage" isEqualToString:name]) {
    NSString *text = args[@"message"] != [NSNull null] ? args[@"message"] : nil;
    ARtmMessage *message = [[ARtmMessage new] initWithText:text];
    BOOL offline = args[@"offline"] != [NSNull null] ? args[@"offline"] : false;
    BOOL historical = args[@"historical"] != [NSNull null] ? args[@"historical"] : false;
    ARtmSendMessageOptions *sendMessageOption = [[ARtmSendMessageOptions alloc] init];
    sendMessageOption.enableOfflineMessaging = offline;
    sendMessageOption.enableHistoricalMessaging = historical;
    [channel sendMessage:message sendMessageOptions: sendMessageOption completion:^(ARtmSendChannelMessageErrorCode errorCode) {
        result(@{@"errorCode": @(errorCode)});
    }];
  }
  else if ([@"leave" isEqualToString:name]) {
    [channel leaveWithCompletion:^(ARtmLeaveChannelErrorCode errorCode) {
      result(@{@"errorCode": @(errorCode)});
    }];
  }
  else if ([@"getMembers" isEqualToString:name]) {
    [channel getMembersWithCompletion:^(NSArray<ARtmMember *> * _Nullable members, ARtmGetMembersErrorCode errorCode) {
      NSMutableArray<NSDictionary*> *exportMembers = [NSMutableArray new];
      for(ARtmMember *member in members) {
        [exportMembers addObject:@{
                                   @"userId": member.uid,
                                   @"channelId": member.channelId
                                   }];
      }
      result(@{@"errorCode": @(errorCode), @"members": exportMembers});
    }];
  }
  else {
    result(@{@"errorCode": @(-2), @"reason": FlutterMethodNotImplemented});
  }
}

- (void)handleMethodCall:(FlutterMethodCall*)methodCall result:(FlutterResult)result {
  NSString *methodName = methodCall.method;
  NSDictionary *callArguments = methodCall.arguments;
  NSString *call = callArguments[@"call"];
  NSDictionary *params = callArguments[@"params"];
  
  if ([@"static" isEqualToString:call]) {
    [self handleStaticMethod:methodName params:params result:result];
  } else if ([@"ARRtmClient" isEqualToString:call]) {
    [self handleARtmClientMethod:methodName params:params result:result];
  } else if ([@"ARRtmChannel" isEqualToString:call]) {
    [self handleARtmChannelMethod:methodName params:params result:result];
  } else {
    result(@{@"errorCode": @(-2), @"reason": FlutterMethodNotImplemented});
  }
}

@end

