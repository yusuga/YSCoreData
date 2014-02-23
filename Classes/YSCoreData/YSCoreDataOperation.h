//
//  YSCoreDataOperation.h
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/23.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreData;

#if DEBUG
    #if 0
        #define LOG_YSCORE_DATA(...) NSLog(__VA_ARGS__)
    #endif
#endif

#ifndef LOG_YSCORE_DATA
    #define LOG_YSCORE_DATA(...)
#endif

@class YSCoreDataOperation;

typedef void(^YSCoreDataOperationAysncWriteConfigure)(NSManagedObjectContext *context,
                                                      YSCoreDataOperation *operation);

typedef NSFetchRequest*(^YSCoreDataOperationAysncFetchConfigure)(NSManagedObjectContext *context,
                                                                 YSCoreDataOperation *operation);

typedef void(^YSCoreDataOperationAysncFetchSuccess)(NSArray *fetchResults);

typedef void(^YSCoreDataOperationFailure)(NSError *error);
typedef void(^YSCoreDataOperationSaveFailure)(NSManagedObjectContext *context, NSError *error);


@interface YSCoreDataOperation : NSObject

- (void)asyncWriteWithBackgroundContext:(NSManagedObjectContext*)bgContext
                 configureManagedObject:(YSCoreDataOperationAysncWriteConfigure)configure
                 successInContextThread:(void (^)(void))success
                                failure:(YSCoreDataOperationSaveFailure)failure;

- (void)asyncFetchWithBackgroundContext:(NSManagedObjectContext*)bgContext
                            mainContext:(NSManagedObjectContext*)mainContext
                  configureFetchRequest:(YSCoreDataOperationAysncFetchConfigure)configure
                 successInContextThread:(YSCoreDataOperationAysncFetchSuccess)success
                                failure:(YSCoreDataOperationFailure)failure;

- (void)cancel;
@property (nonatomic, readonly) BOOL isCancelled;

@end
