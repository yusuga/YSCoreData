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

typedef void(^YSCoreDataOperationWriteConfigure)(NSManagedObjectContext *context,
                                                 YSCoreDataOperation *operation);

typedef NSFetchRequest*(^YSCoreDataOperationFetchRequestConfigure)(NSManagedObjectContext *context,
                                                                   YSCoreDataOperation *operation);

typedef void(^YSCoreDataOperationCompletion)(NSManagedObjectContext *context, NSError *error);
typedef void(^YSCoreDataOperationFetchCompletion)(NSManagedObjectContext *context, NSArray *fetchResults, NSError *error);


@interface YSCoreDataOperation : NSObject

- (id)initWithTemporaryContext:(NSManagedObjectContext*)temporaryContext
                   mainContext:(NSManagedObjectContext*)mainContext
          privateWriterContext:(NSManagedObjectContext*)privateWriterContext;

// sync

- (BOOL)writeWithConfigureManagedObject:(YSCoreDataOperationWriteConfigure)configure
                                  error:(NSError**)errorPtr
                           didSaveStore:(YSCoreDataOperationCompletion)didSaveStore;

- (NSArray*)fetchWithConfigureFetchRequest:(YSCoreDataOperationFetchRequestConfigure)configure
                                     error:(NSError**)errorPtr;

- (BOOL)removeObjectsWithConfigureFetchRequest:(YSCoreDataOperationFetchRequestConfigure)configure
                                         error:(NSError**)errorPtr
                                  didSaveStore:(YSCoreDataOperationCompletion)didSaveStore;

- (BOOL)removeAllObjectsWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel
                                         error:(NSError**)errorPtr
                                  didSaveStore:(YSCoreDataOperationCompletion)didSaveStore;

// async

- (void)asyncWriteWithConfigureManagedObject:(YSCoreDataOperationWriteConfigure)configure
                                  completion:(YSCoreDataOperationCompletion)completion
                                didSaveStore:(YSCoreDataOperationCompletion)didSaveStore;

- (void)asyncFetchWithConfigureFetchRequest:(YSCoreDataOperationFetchRequestConfigure)configure
                                 completion:(YSCoreDataOperationFetchCompletion)completion;

- (void)asyncRemoveRecordWithConfigureFetchRequest:(YSCoreDataOperationFetchRequestConfigure)configure
                                        completion:(YSCoreDataOperationCompletion)completion
                                      didSaveStore:(YSCoreDataOperationCompletion)didSaveStore;

- (void)cancel;
@property (nonatomic, readonly) BOOL isCancelled;
@property (nonatomic, readonly) BOOL isCompleted;

@end
