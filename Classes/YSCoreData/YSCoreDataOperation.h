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
        #warning enable debug log
        #define LOG_YSCORE_DATA(...) NSLog(__VA_ARGS__)
    #endif
#endif

#ifndef LOG_YSCORE_DATA
    #define LOG_YSCORE_DATA(...)
#endif

@class YSCoreDataOperation;

typedef void(^YSCoreDataOperationWriteBlock)(NSManagedObjectContext *context,
                                             YSCoreDataOperation *operation);

typedef NSFetchRequest*(^YSCoreDataOperationFetchRequestBlock)(NSManagedObjectContext *context,
                                                               YSCoreDataOperation *operation);

typedef void(^YSCoreDataOperationCompletion)(YSCoreDataOperation *operation, NSError *error);
typedef void(^YSCoreDataOperationFetchCompletion)(YSCoreDataOperation *operation, NSArray *fetchResults, NSError *error);


@interface YSCoreDataOperation : NSObject

- (instancetype)initWithTemporaryContext:(NSManagedObjectContext*)temporaryContext
                             mainContext:(NSManagedObjectContext*)mainContext
                           writerContext:(NSManagedObjectContext*)writerContext;

/* Write */

- (BOOL)writeWithWriteBlock:(YSCoreDataOperationWriteBlock)writeBlock
                      error:(NSError**)errorPtr;

- (void)writeWithWriteBlock:(YSCoreDataOperationWriteBlock)writeBlock
                 completion:(YSCoreDataOperationCompletion)completion;

/* Fetch */

- (NSArray*)fetchWithFetchRequestBlock:(YSCoreDataOperationFetchRequestBlock)fetchRequestBlock
                                 error:(NSError**)errorPtr;

- (void)fetchWithFetchRequestBlock:(YSCoreDataOperationFetchRequestBlock)fetchRequestBlock
                        completion:(YSCoreDataOperationFetchCompletion)completion;

/* Remove */

- (BOOL)removeObjectsWithFetchRequestBlock:(YSCoreDataOperationFetchRequestBlock)fetchRequestBlock
                                     error:(NSError**)errorPtr;

- (BOOL)removeAllObjectsWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel
                                         error:(NSError**)errorPtr;

- (void)removeObjectsWithFetchRequestBlock:(YSCoreDataOperationFetchRequestBlock)fetchRequestBlock
                                completion:(YSCoreDataOperationCompletion)completion;

/* Others */

@property (copy, nonatomic) YSCoreDataOperationCompletion didSaveStore;

- (void)cancel;
@property (nonatomic, readonly) BOOL isCancelled;

@end
