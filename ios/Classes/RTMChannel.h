//
//  RTMChannel.h
//  ar_rtm
//
//  Created by 余生丶 on 2020/11/5.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import <ARtmKit/ARtmKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RTMChannel : NSObject<FlutterStreamHandler, ARtmChannelDelegate>
@property (strong, nonatomic) NSObject<FlutterBinaryMessenger> *messenger;
@property (strong, nonatomic) ARtmChannel *channel;
@property (strong, nonatomic) NSNumber *clientIndex;
@property (strong, nonatomic) NSString *channelId;
@property (strong, nonatomic) FlutterEventChannel *eventChannel;
@property (strong, nonatomic) FlutterEventSink eventSink;

- (instancetype) initWithClientIndex:(NSNumber *)clientIndex
                 channelId:(NSString *)channelId
                 messenger:(id)messenger
                       kit:(ARtmKit*)kit;

@end

NS_ASSUME_NONNULL_END
