//
//  RTMClient.h
//  ar_rtm
//
//  Created by 余生丶 on 2020/11/5.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import "RTMChannel.h"
#import <ARtmKit/ARtmKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RTMClient : NSObject<FlutterStreamHandler, ARtmDelegate, ARtmCallDelegate>
@property (strong, nonatomic) ARtmKit *kit;
@property (strong, nonatomic) ARtmCallKit *callKit;
@property (strong, nonatomic) NSMutableDictionary<NSString *, RTMChannel*> *channels;
@property (strong, nonatomic) NSMutableDictionary<NSString *, ARtmRemoteInvitation *> *remoteInvitations;
@property (strong, nonatomic) NSMutableDictionary<NSString *, ARtmLocalInvitation *> *localInvitations;

@property (strong, nonatomic) NSObject<FlutterBinaryMessenger> *messenger;
@property (strong, nonatomic) NSNumber *clientIndex;
@property (strong, nonatomic) FlutterEventChannel *eventChannel;
@property (strong, nonatomic) FlutterEventSink eventSink;

- (instancetype) initWithAppId:(NSString *)appId
       clientIndex:(NSNumber *)clientIndex
         messenger:(NSObject<FlutterBinaryMessenger>*)messenger;

@end

NS_ASSUME_NONNULL_END
