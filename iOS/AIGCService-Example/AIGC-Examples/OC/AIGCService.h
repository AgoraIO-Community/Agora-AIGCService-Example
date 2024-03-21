//
//  AIGCService.h
//  GPT-Demo
//
//  Created by ZYP on 2023/10/7.
//

#import <Foundation/Foundation.h>
#import "AIGCConfigure.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AIGCServiceDelegate <NSObject>
- (void)onServiceEventResult:(AIGCServiceEvent)event
                        code:(AIGCServiceCode)code
                     message:(NSString * _Nullable)message;
- (NSInteger)onSpeech2TextResult:(NSString *)roundId
                          result:(NSString *)result
                recognizedSpeech:(BOOL)RecognizedSpeech;
- (NSInteger)onLLMResult:(NSString *)roundId answer:(NSString *)answer;
- (NSInteger)onText2SpeechResult:(NSString *)roundId
                           voice:(NSData *)voice
                            bits:(NSInteger)bits
                        channels:(NSInteger)channels
                     sampleRates:(NSInteger)sampleRates;
@end

@interface AIGCService : NSObject

@property(nonatomic, weak)id<AIGCServiceDelegate> delegate;

+ (instancetype)create;
+ (void)destory;

- (void)initialize:(AIGCConfigure *)configure;
- (NSArray <AIRole *>* _Nullable)getRoles;
- (void)setRoleWithId:(NSString *)roleId;
- (AIRole * _Nullable)getCurrentRole;
- (ServiceVendorGroup * _Nullable)getServiceVendors;
- (NSInteger)setInputOutputMode:(SceneMode *)inputMode
                     outputMode:(SceneMode *)outputMode
             serviceVendorGroup:(ServiceVendorGroup *)serviceVendorGroup;
- (void)start;
- (void)stop;
- (NSInteger)pushSpeechDialogueWithData:(NSData *)data
                             sampleRate:(NSInteger)sampleRate
                               channels:(NSInteger)channels
                                   bits:(NSInteger)bits
                                    vad:(NSInteger)vad;
- (NSInteger)pushTxtDialogue:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
