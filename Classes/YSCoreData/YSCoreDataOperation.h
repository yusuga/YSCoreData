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

typedef void(^YSCoreDataOperationCompletion)(NSManagedObjectContext *context, NSError *error);
typedef void(^YSCoreDataOperationFetchCompletion)(NSManagedObjectContext *context, NSArray *fetchResults, NSError *error);


@interface YSCoreDataOperation : NSObject

- (id)initWithTemporaryContext:(NSManagedObjectContext*)temporaryContext
                   mainContext:(NSManagedObjectContext*)mainContext
          privateWriterContext:(NSManagedObjectContext*)privateWriterContext;

// sync

- (BOOL)writeWithConfigureManagedObject:(YSCoreDataOperationAsyncWriteConfigure)configure
                                  error:(NSError**)error
                          didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite;

- (NSArray*)fetchWithConfigureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                                     error:(NSError**)error;

- (BOOL)removeRecordWithConfigureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                                        error:(NSError**)error
                                didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite;

// async

- (void)asyncWriteWithConfigureManagedObject:(YSCoreDataOperationAsyncWriteConfigure)configure
                                  completion:(YSCoreDataOperationCompletion)completion
                               didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite;

- (void)asyncFetchWithConfigureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                                 completion:(YSCoreDataOperationFetchCompletion)completion;

- (void)asyncRemoveRecordWithConfigureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                                        completion:(YSCoreDataOperationCompletion)completion
                                     didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite;

- (void)cancel;
@property (nonatomic, readonly) BOOL isCancelled;

@end
