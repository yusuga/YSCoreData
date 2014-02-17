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

+ (void)requestTweetsWithLimit:(NSUInteger)limit completion:(RequestTwitterCompletion)completion;
+ (void)resetState;

@end
