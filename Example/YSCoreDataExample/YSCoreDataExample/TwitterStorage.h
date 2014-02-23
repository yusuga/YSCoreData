//
//  TwitterStorage.h
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/13.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "YSCoreData.h"
#import "Tweet.h"
#import "User.h"

typedef void(^TwitterStorageFetchTweetsSuccess)(NSArray *tweets);
typedef void(^TwitterStorageFetchTweetsFailure)(NSError *error);

@interface TwitterStorage : YSCoreData

+ (instancetype)sharedInstance;

- (void)insertTweetsWithTweetJsons:(NSArray*)tweetJsons;
- (void)insertTweetWithTweetJson:(NSDictionary*)tweetJson;

- (void)fetchTweetsLimit:(NSUInteger)limit
                   maxId:(NSNumber *)maxId
                 success:(TwitterStorageFetchTweetsSuccess)success
                 failure:(TwitterStorageFetchTweetsFailure)failure;

@end
