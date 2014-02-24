//
//  YSCoreDataOperation.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/23.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "YSCoreDataOperation.h"

@interface YSCoreDataOperation ()

@end

@implementation YSCoreDataOperation

- (void)asyncWriteWithBackgroundContext:(NSManagedObjectContext*)bgContext
                 configureManagedObject:(YSCoreDataOperationAsyncWriteConfigure)configure
                 successInContextThread:(YSCoreDataOperationSuccess)success
                                failure:(YSCoreDataOperationSaveFailure)failure
{
    NSAssert(bgContext != nil, @"context is nil;");
    
    [bgContext performBlock:^{
        if (configure) {
            configure(bgContext, self);
            
            if (self.isCancelled) {
                LOG_YSCORE_DATA(@"Cancel: asyncWrite");
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failure) failure(bgContext, [YSCoreDataError cancelErrorWithOperationType:YSCoreDataErrorOperationTypeWrite]);
                });
                return ;
            }
        } else {
            NSAssert(0, @"Error: asyncWrite; setting == nil");
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) failure(bgContext, [YSCoreDataError requiredArgumentIsNilErrorWithDescription:@"Write setting is nil"]);
            });
            return ;
        }
        
        if (success) success(bgContext);
    }];
}

- (void)asyncFetchWithBackgroundContext:(NSManagedObjectContext*)bgContext
                            mainContext:(NSManagedObjectContext*)mainContext
                  configureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                 success:(YSCoreDataOperationFetchSuccess)success
                                failure:(YSCoreDataOperationFailure)failure
{
    NSAssert(bgContext != nil && mainContext != nil, @"context is nil;");
    
    [bgContext performBlock:^{
        NSError *error = nil;
        NSArray *results = [self excuteFetchWithContext:bgContext
                                   configureFetchRequest:configure
                                                   error:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) failure(error);
            });
            return;
        }
        
        if ([results count] == 0) {
            LOG_YSCORE_DATA(@"Fetch result is none");
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) success(results);
            });
            return;
        }
        
        /*
         FetchしたNSManagedObjectを別スレッドに渡せない(temporaryContextと共に解放される)ので
         スレッドセーフなNSManagedObjectIDを保持する
         ※ 正確に言うと、NSManagedObject自体は解放されてないんだけどpropertyが解放されている
         */
        NSMutableArray *ids = [NSMutableArray arrayWithCapacity:[results count]];
        for (NSManagedObject *obj in results) {
            [ids addObject:obj.objectID];
        }
        
        [mainContext performBlock:^{ // == dispatch_async(dispatch_get_main_queue(), ^{
            /*
             mainContext(NSMainQueueConcurrencyTypeで初期化したContext)から
             保持していたNSManagedObjectIDを元にNSManagedObjectを取得
             */
            NSMutableArray *fetchResults = [NSMutableArray arrayWithCapacity:[ids count]];
            for (NSManagedObjectID *objId in ids) {
                [fetchResults addObject:[mainContext objectWithID:objId]];
            }
            LOG_YSCORE_DATA(@"Success: Fetch %@", @([fetchResults count]));
            if (success) success(fetchResults);
        }];
    }];
}

- (void)asyncRemoveRecordWithBackgroundContext:(NSManagedObjectContext *)bgContext
                         configureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                        successInContextThread:(YSCoreDataOperationSuccess)success
                                       failure:(YSCoreDataOperationSaveFailure)failure
{
    NSAssert(bgContext != nil, @"context is nil;");
    
    [bgContext performBlock:^{
        NSError *error = nil;
        NSArray *results = [self excuteFetchWithContext:bgContext
                                  configureFetchRequest:configure
                                                  error:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) failure(bgContext, error);
            });
            return;
        }
        
        if ([results count] == 0) {
            LOG_YSCORE_DATA(@"Fetch result is none");
            if (success) success(bgContext);
            return;
        }
        
        for (NSManagedObject *manaObj in results) {
            [bgContext deleteObject:manaObj];
        }
        
        if (self.isCancelled) {
            LOG_YSCORE_DATA(@"Cancel: asycnRemove; did deleteObject;");
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) failure(bgContext, [YSCoreDataError cancelErrorWithOperationType:YSCoreDataErrorOperationTypeRemove]);
            });
            return;
        }
        
        if (success) success(bgContext);
    }];
}

- (NSArray*)excuteFetchWithContext:(NSManagedObjectContext*)context
                      configureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                             error:(NSError**)error
{
    NSFetchRequest *req;
    if (configure) {
        req = configure(context, self);
        
        if (req == nil) {
            NSString *desc = @"Fetch request is nil";
            NSAssert(0, desc);
            *error = [YSCoreDataError requiredArgumentIsNilErrorWithDescription:desc];
            return nil;
        }
    } else {
        NSString *desc = @"Fetch configure is nil";
        NSAssert(0, desc);
        *error = [YSCoreDataError requiredArgumentIsNilErrorWithDescription:desc];
        return nil;
    }
    
    if (self.isCancelled) {
        LOG_YSCORE_DATA(@"Cancel: asyncFetch; will execute fetch request;");
        *error = [YSCoreDataError cancelErrorWithOperationType:YSCoreDataErrorOperationTypeFetch];
        return nil;
    }
    
    NSArray *results = [context executeFetchRequest:req error:error];
    
    if ((error && *error)) {
        LOG_YSCORE_DATA(@"Error: -executeFetchRequest:error:; error = %@;", *error);
        return nil;
    }
    
    if (self.isCancelled) {
        LOG_YSCORE_DATA(@"Cancel: asyncFetch; did execute fetch request;");
        *error = [YSCoreDataError cancelErrorWithOperationType:YSCoreDataErrorOperationTypeFetch];
        return nil;
    }
    
    return results;
}

#pragma mark -

- (void)cancel
{
    _isCancelled = YES;
}

@end
