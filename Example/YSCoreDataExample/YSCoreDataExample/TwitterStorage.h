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
                             error:(NSError**)error
                     didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite;

- (YSCoreDataOperation*)asyncInsertTweetsWithTweetJsons:(NSArray*)tweetJsons
                                        completion:(YSCoreDataOperationCompletion)completion
                                     didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite;

// fetch

- (NSArray*)fetchTweetsWithLimit:(NSUInteger)limit
                           maxId:(NSNumber *)maxId
                           error:(NSError**)error;

- (YSCoreDataOperation*)asyncFetchTweetsLimit:(NSUInteger)limit
                                   maxId:(NSNumber *)maxId
                              completion:(YSCoreDataOperationFetchCompletion)completion;

// remove

- (BOOL)removeAllTweetRecordWithError:(NSError**)error
                        didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite;

- (YSCoreDataOperation*)asyncRemoveAllTweetRecordWithCompletion:(YSCoreDataOperationCompletion)completion
                                             didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite;

// count

- (NSUInteger)countTweetRecord;
- (NSUInteger)countUserRecord;

@end
