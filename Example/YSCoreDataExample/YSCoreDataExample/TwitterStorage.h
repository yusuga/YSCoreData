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
                                         success:(void(^)(void))success
                                         failure:(YSCoreDataOperationSaveFailure)failure
                                   didSaveSQLite:(void(^)(void))didSaveSQLite;

- (YSCoreDataOperation*)insertTweetsWithTweetJsons:(NSArray*)tweetJsons
                                           success:(void(^)(void))success
                                           failure:(YSCoreDataOperationSaveFailure)failure
                                     didSaveSQLite:(void(^)(void))didSaveSQLite;

- (YSCoreDataOperation*)fetchTweetsLimit:(NSUInteger)limit
                                   maxId:(NSNumber *)maxId
                                 success:(TwitterStorageFetchTweetsSuccess)success
                                 failure:(TwitterStorageFetchTweetsFailure)failure;

- (YSCoreDataOperation*)removeAllTweetRecordWithSuccess:(void (^)(void))success
                                                failure:(YSCoreDataOperationSaveFailure)failure
                                          didSaveSQLite:(void(^)(void))didSaveSQLite;

- (NSUInteger)countTweetRecord;
- (NSUInteger)countUserRecord;

@end
