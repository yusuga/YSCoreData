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

typedef void(^TwitterStorageFetchTweetsCompletion)(NSArray *tweets);

@interface TwitterStorage : YSCoreData

- (void)insertTweetsWithTweetJsons:(NSArray*)tweetJsons;
- (void)insertTweetWithTweetJson:(NSDictionary*)tweetJson;

- (void)fetchTweetsLimit:(NSUInteger)limit maxId:(NSNumber *)maxId completion:(TwitterStorageFetchTweetsCompletion)completion;

@end
