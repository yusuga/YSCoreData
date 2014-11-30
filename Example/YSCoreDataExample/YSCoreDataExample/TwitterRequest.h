//
//  TwitterRequest.h
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/18.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TwitterRequest : NSObject

+ (NSArray*)requestTweetsWithMaxCount:(NSUInteger)maxCount;
+ (NSArray*)requestTweetsWithCount:(NSUInteger)count;
+ (void)resetState;

+ (NSDictionary*)tweetWithTweetID:(int64_t)tweetID
                           userID:(int64_t)userID;

+ (NSDictionary*)tweetWithTweetID:(int64_t)tweetID
                             text:(NSString*)text
                           userID:(int64_t)userID
                             name:(NSString*)name
                       screenName:(NSString*)screenName;

@end
