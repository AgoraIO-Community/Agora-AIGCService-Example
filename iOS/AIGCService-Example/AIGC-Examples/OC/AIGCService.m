//
//  AIGCService.m
//  GPT-Demo
//
//  Created by ZYP on 2023/10/7.
//

#import "AIGCService.h"

@implementation AIGCService

+ (instancetype)create {
    return [AIGCService new];
}

- (void)initialize:(AIGCConfigure *)configure {
    
}

- (NSArray <AIRole *>* _Nullable)getRoles {
    return nil;
}

- (void)setRoleWithId:(NSString *)roleId {
    
}

- (AIRole *)getCurrentRole {
    return [AIRole new];
}

- (ServiceVendorGroup * _Nullable)getServiceVendors {
    return [ServiceVendorGroup new];
}

- (NSInteger)setInputOutputMode:(SceneMode *)inputMode
                     outputMode:(SceneMode *)outputMode
             serviceVendorGroup:(ServiceVendorGroup *)serviceVendorGroup {
    return 0;
}

- (void)start {}
- (void)stop {}

- (NSInteger)pushSpeechDialogueWithData:(NSData *)data
                             sampleRate:(NSInteger)sampleRate
                               channels:(NSInteger)channels
                                   bits:(NSInteger)bits
                                    vad:(NSInteger)vad {
    
    return 0;
}

- (NSInteger)pushTxtDialogue:(NSString *)text {
    return 0;
}

+ (void)destory {}

@end
