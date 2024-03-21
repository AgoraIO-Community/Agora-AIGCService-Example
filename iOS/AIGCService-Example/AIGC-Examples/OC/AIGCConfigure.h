//
//  AIGCConfigure.h
//  GPT-Demo
//
//  Created by ZYP on 2023/10/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, AIGCServiceEvent) {
    AIGCServiceEventOne,
};

typedef NSInteger AIGCServiceCode;

@interface AIGCConfigure : NSObject

@property (nonatomic, copy)NSString *appId;
@property (nonatomic, copy)NSString *rtmToken;
@property (nonatomic, copy)NSString *userName;
@property (nonatomic, assign)BOOL enableMultiTurnShortTermMemory;
@property (nonatomic, assign)NSInteger speechRecognitionFiltersLength;
@end

@interface AIRole : NSObject

@end

@interface BaseVendor : NSObject
@property (nonatomic, copy)NSString *accountInJason;
@end

@interface STTVendor : BaseVendor
@property (nonatomic, copy)NSString *ID;
@property (nonatomic, copy)NSString *vendor;
@end

@interface LLMVendor : BaseVendor
@property (nonatomic, copy)NSString *ID;
@property (nonatomic, copy)NSString *vendor;
@end

@interface TTSVendor : BaseVendor
@property (nonatomic, copy)NSString *ID;
@property (nonatomic, copy)NSString *vendor;
@property (nonatomic, copy)NSString *language;
@property (nonatomic, copy)NSString *voiceName;
@property (nonatomic, copy)NSString *voiceStyle;
@end

@interface ServiceVendorGroup : NSObject
@property (nonatomic, copy)NSArray <STTVendor *>*stt;
@property (nonatomic, copy)NSArray <TTSVendor *>*tts;
@property (nonatomic, copy)NSArray <LLMVendor *>*llm;
@end

@interface SceneMode : NSObject
@property (nonatomic, assign)NSInteger mode;
@property (nonatomic, copy)NSString *language;
@property (nonatomic, assign)NSInteger speechFrameBits;
@property (nonatomic, assign)NSInteger speechFrameSampleRates;
@property (nonatomic, assign)NSInteger speechFrameChannels;
@end

NS_ASSUME_NONNULL_END
