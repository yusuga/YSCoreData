//
//  YSCoreDataOperation.h
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/23.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreData;
#import "YSCoreDataError.h"

#if DEBUG
    #if 0
        #define LOG_YSCORE_DATA(...) NSLog(__VA_ARGS__)
    #endif
#endif

#ifndef LOG_YSCORE_DATA
    #define LOG_YSCORE_DATA(...)
#endif

@class YSCoreDataOperation;

typedef void(^YSCoreDataOperationAsyncWriteConfigure)(NSManagedObjectContext *context,
                                                      YSCoreDataOperation *operation);

typedef NSFetchRequest*(^YSCoreDataOperationAsyncFetchRequestConfigure)(NSManagedObjectContext *context,
                                                                 YSCoreDataOperation *operation);

typedef void(^YSCoreDataOperationAsyncFetchSuccess)(NSArray *fetchResults);

typedef void(^YSCoreDataOperationFailure)(NSError *error);
typedef void(^YSCoreDataOperationSaveFailure)(NSManagedObjectContext *context, NSError *error);


@interface YSCoreDataOperation : NSObject

- (void)asyncWriteWithBackgroundContext:(NSManagedObjectContext*)bgContext
                 configureManagedObject:(YSCoreDataOperationAsyncWriteConfigure)configure
                 successInContextThread:(void (^)(void))success
                                failure:(YSCoreDataOperationSaveFailure)failure;

- (void)asyncFetchWithBackgroundContext:(NSManagedObjectContext*)bgContext
                            mainContext:(NSManagedObjectContext*)mainContext
                  configureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                 successInContextThread:(YSCoreDataOperationAsyncFetchSuccess)success
                                failure:(YSCoreDataOperationFailure)failure;

- (void)asyncRemoveRecordWithBackgroundContext:(NSManagedObjectContext*)bgContext
                         configureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                        successInContextThread:(void(^)(void))success
                                       failure:(YSCoreDataOperationSaveFailure)failure;

- (void)cancel;
@property (nonatomic, readonly) BOOL isCancelled;

@end
