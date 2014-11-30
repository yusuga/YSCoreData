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

// insert

- (BOOL)insertTweetsWithTweetJsons:(NSArray*)tweetJsons
                             error:(NSError**)error;

- (YSCoreDataOperation*)insertTweetsWithTweetJsons:(NSArray*)tweetJsons
                                        completion:(YSCoreDataOperationCompletion)completion;

// fetch

- (NSArray*)fetchTweetsWithLimit:(NSUInteger)limit
                           maxId:(int64_t)maxId
                           error:(NSError**)errorPtr;

- (YSCoreDataOperation*)fetchTweetsLimit:(NSUInteger)limit
                                   maxId:(int64_t)maxId
                              completion:(YSCoreDataOperationFetchCompletion)completion;

// remove

- (BOOL)removeAllTweetsWithError:(NSError**)errorPtr;

- (YSCoreDataOperation*)removeAllTweetsWithCompletion:(YSCoreDataOperationCompletion)completion;

// count

- (NSUInteger)countTweetObjects;
- (NSUInteger)countUserObjects;

@end
