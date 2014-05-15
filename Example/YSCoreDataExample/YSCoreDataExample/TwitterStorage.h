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
                      didSaveStore:(YSCoreDataOperationCompletion)didSaveStore;

- (YSCoreDataOperation*)asyncInsertTweetsWithTweetJsons:(NSArray*)tweetJsons
                                             completion:(YSCoreDataOperationCompletion)completion
                                           didSaveStore:(YSCoreDataOperationCompletion)didSaveStore;

// fetch

- (NSArray*)fetchTweetsWithLimit:(NSUInteger)limit
                           maxId:(NSNumber *)maxId
                           error:(NSError**)error;

- (YSCoreDataOperation*)asyncFetchTweetsLimit:(NSUInteger)limit
                                        maxId:(NSNumber *)maxId
                                   completion:(YSCoreDataOperationFetchCompletion)completion;

// remove

- (BOOL)removeAllTweetRecordWithError:(NSError**)error
                         didSaveStore:(YSCoreDataOperationCompletion)didSaveStore;

- (YSCoreDataOperation*)asyncRemoveAllTweetRecordWithCompletion:(YSCoreDataOperationCompletion)completion
                                                   didSaveStore:(YSCoreDataOperationCompletion)didSaveStore;

// count

- (NSUInteger)countTweetRecord;
- (NSUInteger)countUserRecord;

@end
