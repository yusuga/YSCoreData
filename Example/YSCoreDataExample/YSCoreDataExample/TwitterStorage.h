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

- (YSCoreDataOperation*)insertTweetWithTweetJson:(NSDictionary*)tweetJson
                                      completion:(YSCoreDataOperationCompletion)completion
                                   didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite;

- (YSCoreDataOperation*)insertTweetsWithTweetJsons:(NSArray*)tweetJsons
                                        completion:(YSCoreDataOperationCompletion)completion
                                     didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite;

- (YSCoreDataOperation*)fetchTweetsLimit:(NSUInteger)limit
                                   maxId:(NSNumber *)maxId
                              completion:(YSCoreDataOperationFetchCompletion)completion;

- (YSCoreDataOperation*)removeAllTweetRecordWithCompletion:(YSCoreDataOperationCompletion)completion
                                             didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite;

- (NSUInteger)countTweetRecord;
- (NSUInteger)countUserRecord;

@end
