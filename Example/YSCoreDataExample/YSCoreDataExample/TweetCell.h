//
//  TweetCell.h
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/18.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Tweet;

@interface TweetCell : UITableViewCell

+ (UINib*)nib;
+ (CGFloat)cellHeight;

- (void)configureContentWithTweet:(Tweet*)tweet;

@end
