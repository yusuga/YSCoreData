//
//  TwitterRequest.h
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/18.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^RequestTwitterCompletion)(NSArray *newTweets);

@interface TwitterRequest : NSObject

+ (void)requestTweetsWithMaxCount:(NSUInteger)maxCount completion:(RequestTwitterCompletion)completion;
+ (void)requestTweetsWithCount:(NSUInteger)count completion:(RequestTwitterCompletion)completion;
+ (void)resetState;

+ (NSArray*)userNames;
+ (NSArray*)screenNames;

@end
