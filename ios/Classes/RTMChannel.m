//
//  RTMChannel.m
//  ar_rtm
//
//  Created by 余生丶 on 2020/11/5.
//

#import "RTMChannel.h"

@implementation RTMChannel

- (instancetype) initWithClientIndex:(NSNumber *)clientIndex channelId:(NSString *)channelId messenger:(id)messenger kit:(ARtmKit*)kit {
  self = [super init];
  if (self) {
    _clientIndex = clientIndex;
    _channelId = channelId;
    _channel = [kit createChannelWithId:channelId delegate:self];
    if (nil == _channel) {
      return nil;
    }
    _messenger = messenger;
    NSString *channelName = [NSString stringWithFormat:@"io.ar.rtm.client%@.channel%@", [clientIndex stringValue], channelId];
    _eventChannel = [FlutterEventChannel eventChannelWithName:channelName binaryMessenger:_messenger];
    if (nil == _eventChannel) {
      return nil;
    }
    
    [_eventChannel setStreamHandler:self];
  }
  return self;
}

- (void) dealloc {
  _clientIndex = nil;
  _channelId = nil;
  _channel = nil;
  _eventChannel = nil;
  _messenger = nil;
}

//MARK: - FlutterStreamHandler

- (FlutterError * _Nullable)onCancelWithArguments:(id _Nullable)arguments {
  _eventSink = nil;
  return nil;
}

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(nonnull FlutterEventSink)events {
  _eventSink = events;
  return nil;
}

- (void) sendChannelEvent:(NSString *)name params:(NSDictionary*)params {
  if (_eventSink) {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:params];
    dict[@"event"] = name;
    _eventSink([dict copy]);
  }
}

//MARK: - ARtmChannelDelegate

- (void)channel:(ARtmChannel *)channel memberJoined:(ARtmMember *)member {
    [self sendChannelEvent:@"onMemberJoined" params:@{@"userId": member.uid, @"channelId": member.channelId}];
}

- (void)channel:(ARtmChannel *)channel memberLeft:(ARtmMember *)member {
    [self sendChannelEvent:@"onMemberLeft" params:@{@"userId": member.uid, @"channelId": member.channelId}];
}

- (void)channel:(ARtmChannel *)channel messageReceived:(ARtmMessage *)message fromMember:(ARtmMember *)member {
    [self sendChannelEvent:@"onMessageReceived" params:@{@"userId": member.uid,
             @"channelId": member.channelId,
             @"message":
                @{@"text":message.text,
                  @"ts": @(message.serverReceivedTs),
                  @"offline": @(message.isOfflineMessage)}
                                                       }];
}

- (void)channel:(ARtmChannel *)channel attributeUpdate:(NSArray<ARtmChannelAttribute *> *)attributes {
    NSMutableArray<NSDictionary*> *channelAttributes = [NSMutableArray new];
    for(ARtmChannelAttribute *attribute in attributes) {
      [channelAttributes addObject:@{
                                 @"key": attribute.key,
                                 @"value": attribute.value,
                                 @"userId": attribute.lastUpdateUid,
                                 @"updateTs": [NSNumber numberWithLongLong:attribute.lastUpdateTs]
                                 }];
    }
    [self sendChannelEvent:@"onAttributesUpdated" params:@{@"attributes": channelAttributes}];
}

- (void)channel:(ARtmChannel *)channel memberCount:(int)count {
    [self sendChannelEvent:@"onMemberCountUpdated" params:@{@"count": [NSNumber numberWithInt:count]}];
}

@end

