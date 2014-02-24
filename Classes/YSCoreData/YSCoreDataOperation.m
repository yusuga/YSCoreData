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
                 successInContextThread:(void (^)(void))success
                                failure:(YSCoreDataOperationSaveFailure)failure
{
    __weak typeof(self) wself = self;
    [bgContext performBlock:^{
        if (configure) {
            configure(bgContext, wself);
            
            if (wself.isCancelled) {
                LOG_YSCORE_DATA(@"Cancel: asyncWrite");
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failure) failure(bgContext, nil);
                });
                return ;
            }
        } else {
            NSLog(@"Error: asyncWrite; setting == nil");
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) failure(bgContext, nil);
            });
            return ;
        }
        
        if (success) success();
    }];
}

- (void)asyncFetchWithBackgroundContext:(NSManagedObjectContext*)bgContext
                            mainContext:(NSManagedObjectContext*)mainContext
                  configureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                 successInContextThread:(YSCoreDataOperationAsyncFetchSuccess)success
                                failure:(YSCoreDataOperationFailure)failure
{
    __weak typeof(self) wself = self;
    [bgContext performBlock:^{
        void(^errorFinish)(NSError *error) = ^(NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(nil);
            });
        };
        
        NSFetchRequest *request;
        if (configure) {
            request = configure(bgContext, wself);

            if (wself.isCancelled) {
                LOG_YSCORE_DATA(@"Cancel: asyncFetch;");
                errorFinish(nil);
                return ;
            }
        } else {
            NSLog(@"Error: asyncFetch; configure == nil");
            errorFinish(nil);
            return ;
        }
        
        if (request == nil) {
            NSLog(@"Error: asyncFetch; request == nil");
            errorFinish(nil);
            return ;
        }
        
        NSError *error = nil;
        NSArray *fetchResults = [bgContext executeFetchRequest:request error:&error];
        
        if (wself.isCancelled) {
            LOG_YSCORE_DATA(@"Cancel: asyncFetch;");
            errorFinish(nil);
            return ;
        }
        
        if (error) {
            errorFinish(error);
            return;
        }
        
        if ([fetchResults count] == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) success(fetchResults);
            });
            return;
        }
        
        /*
         FetchしたNSManagedObjectを別スレッドに渡せない(temporaryContextと共に解放される)ので
         スレッドセーフなNSManagedObjectIDを保持する
         ※ 正確に言うと、NSManagedObject自体は解放されてないんだけどpropertyが解放されている
         */
        NSMutableArray *ids = [NSMutableArray arrayWithCapacity:[fetchResults count]];
        for (NSManagedObject *obj in fetchResults) {
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
                        successInContextThread:(void (^)(void))success
                                       failure:(YSCoreDataOperationSaveFailure)failure
{
    __weak typeof(self) wself = self;
    [bgContext performBlock:^{
        NSError *error = nil;
        NSArray *results = [wself excuteFetchWithContext:bgContext
                                   configureFetchRequest:configure
                                                   error:&error];
        if (error) {
            NSLog(@"Error: execure; error = %@;", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) failure(bgContext, error);
            });
            return;
        }
        for (NSManagedObject *manaObj in results) {
            [bgContext deleteObject:manaObj];
        }
        if (success) success();
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
            NSLog(@"Error: asyncFetch; request == nil");
//            *error = [NSError errorWithDomain:<#(NSString *)#> code:<#(NSInteger)#> userInfo:<#(NSDictionary *)#>]
            return nil;
        }
    } else {
        NSLog(@"Error: asyncFetch; configure == nil");
//        *error = [NSError errorWithDomain:<#(NSString *)#> code:<#(NSInteger)#> userInfo:<#(NSDictionary *)#>]
        return nil;
    }
    
    if (self.isCancelled) {
        LOG_YSCORE_DATA(@"Cancel: asyncFetch;");
//        *error = [NSError errorWithDomain:<#(NSString *)#> code:<#(NSInteger)#> userInfo:<#(NSDictionary *)#>]
        return nil;
    }
    
    NSArray *fetchResults = [context executeFetchRequest:req error:error];
    
    if ((error && *error)) {
        LOG_YSCORE_DATA(@"Error: -executeFetchRequest:error:; error = %@;", __func__, *error);
        return nil;
    }
    
    if (self.isCancelled) {
        LOG_YSCORE_DATA(@"Cancel: asyncFetch;");
//        *error = [NSError errorWithDomain:<#(NSString *)#> code:<#(NSInteger)#> userInfo:<#(NSDictionary *)#>]
        return nil;
    }
    return fetchResults;
}

#pragma mark -

- (void)cancel
{
    _isCancelled = YES;
}

@end
