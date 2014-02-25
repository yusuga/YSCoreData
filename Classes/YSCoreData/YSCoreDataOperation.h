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
    #if 1
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

typedef void(^YSCoreDataOperationFetchSuccess)(NSArray *fetchResults);

typedef void(^YSCoreDataOperationFailure)(NSError *error);
typedef void(^YSCoreDataOperationSaveFailure)(NSManagedObjectContext *context, NSError *error);


@interface YSCoreDataOperation : NSObject

- (id)initWithTemporaryContext:(NSManagedObjectContext*)temporaryContext
                   mainContext:(NSManagedObjectContext*)mainContext
          privateWriterContext:(NSManagedObjectContext*)privateWriterContext;

- (void)asyncWriteWithconfigureManagedObject:(YSCoreDataOperationAsyncWriteConfigure)configure
                                     success:(void(^)(void))success
                                     failure:(YSCoreDataOperationSaveFailure)failure
                               didSaveSQLite:(void(^)(void))didSaveSQLite;


- (void)asyncFetchWithConfigureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                                    success:(YSCoreDataOperationFetchSuccess)success
                                    failure:(YSCoreDataOperationFailure)failure;


- (void)asyncRemoveRecordWithConfigureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                                           success:(void(^)(void))success
                                           failure:(YSCoreDataOperationSaveFailure)failure
                                     didSaveSQLite:(void(^)(void))didSaveSQLite;

- (void)cancel;
@property (nonatomic, readonly) BOOL isCancelled;

@end
