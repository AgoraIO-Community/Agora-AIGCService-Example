//
//  MessageCell.h
//  VideoConference
//
//  Created by SRS on 2020/5/13.
//  Copyright © 2020 agora. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MessageCellActionType) {
    MessageCellActionTypeTip,
    MessageCellActionTypeTranslate
};

@protocol MessageCellDelegate <NSObject>
- (void)messageCelldidTapButton:(MessageCellActionType)actionType atIndexPath:(NSIndexPath *)indexPath;
@end

@interface MessageCell : UITableViewCell
@property (nonatomic, strong)NSIndexPath *indexPath;
@property (nonatomic, weak)id<MessageCellDelegate> delegate;

- (void)updateWithTime:(NSInteger)time
               message:(NSString *)msg
              username:(NSString *)username
        translatedText:(nullable NSString *)translatedText;
- (void)updateTimeShow:(BOOL)show;
- (void)updateRightButtonShow:(BOOL)show;

@end

NS_ASSUME_NONNULL_END
