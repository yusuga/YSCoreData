//
//  YSCoreDataOperation.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/23.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "YSCoreDataOperation.h"
#import <objc/message.h>

@interface YSCoreDataOperation ()

@property (nonatomic) NSManagedObjectContext *temporaryContext;
@property (nonatomic) NSManagedObjectContext *mainContext;
@property (nonatomic) NSManagedObjectContext *privateWriterContext;

@property (nonatomic) SEL configureSelector;

@end

@implementation YSCoreDataOperation

- (id)init
{
    abort();
}

- (id)initWithTemporaryContext:(NSManagedObjectContext*)temporaryContext
                   mainContext:(NSManagedObjectContext*)mainContext
          privateWriterContext:(NSManagedObjectContext*)privateWriterContext
{
    if (self = [super init]) {
        NSAssert(temporaryContext != nil && mainContext != nil && privateWriterContext != nil, @"context is nil;");
        
        self.temporaryContext = temporaryContext;
        self.mainContext = mainContext;
        self.privateWriterContext = privateWriterContext;
    }
    return self;
}

#pragma mark - write

- (BOOL)writeWithConfigureManagedObject:(YSCoreDataOperationAsyncWriteConfigure)configure
                                  error:(NSError**)errorPtr
                          didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite
{
    if (configure == nil) {
        NSError *coreDataError = [YSCoreDataError requiredArgumentIsNilErrorWithDescription:@"Write setting is nil"];
        if (errorPtr != NULL) {
            *errorPtr = coreDataError;
        }
        if (didSaveSQLite) didSaveSQLite(self.mainContext, coreDataError);
        return NO;
    }
    configure(self.mainContext, self);
    return [self saveMainContextWithSave:errorPtr didSaveSQLite:didSaveSQLite];
}

- (void)asyncWriteWithConfigureManagedObject:(YSCoreDataOperationAsyncWriteConfigure)configure
                                  completion:(YSCoreDataOperationCompletion)completion
                               didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite
{
    [self.temporaryContext performBlock:^{
        if (configure) {
            configure(self.temporaryContext, self);
            
            if (self.isCancelled) {
                LOG_YSCORE_DATA(@"Cancel: asyncWrite");
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion(self.temporaryContext,
                                               [YSCoreDataError cancelErrorWithType:YSCoreDataErrorOperationTypeWrite]);
                });
                return ;
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(self.temporaryContext,
                                           [YSCoreDataError requiredArgumentIsNilErrorWithDescription:@"Write setting is nil"]);
            });
            return ;
        }
        
        [self asyncSaveTemporaryContextWithDidMergeMainContext:completion
                            didSaveSQLite:didSaveSQLite];
    }];
}

#pragma mark - fetch

- (NSArray*)fetchWithConfigureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                                     error:(NSError**)errorPtr
{
    return [self excuteFetchWithContext:self.mainContext
                  configureFetchRequest:configure
                                  error:errorPtr];
}

- (void)asyncFetchWithConfigureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                                 completion:(YSCoreDataOperationFetchCompletion)completion
{
    [self.temporaryContext performBlock:^{
        NSError *error = nil;
        NSArray *results = [self excuteFetchWithContext:self.temporaryContext
                                  configureFetchRequest:configure
                                                  error:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(self.temporaryContext, nil, error);
            });
            return;
        }
        
        if ([results count] == 0) {
            LOG_YSCORE_DATA(@"Fetch result is none");
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(self.temporaryContext, results, nil);
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
        
        [self.mainContext performBlock:^{ // == dispatch_async(dispatch_get_main_queue(), ^{
            
            if (self.isCancelled) {
                LOG_YSCORE_DATA(@"Cancel: asyncFetch;");
                if (completion) completion(self.mainContext,
                                           nil,
                                           [YSCoreDataError cancelErrorWithType:YSCoreDataErrorOperationTypeFetch]);
                return;
            }
            
            /*
             mainContext(NSMainQueueConcurrencyTypeで初期化したContext)から
             保持していたNSManagedObjectIDを元にNSManagedObjectを取得
             
             -objectWithID:, -objectRegisteredForID:, -existingObjectWithID:error: の違い。
             ( http://xcatsan.blogspot.jp/2010/06/coredata-object-idobject-id_04.html )
             
             ※ ただ、-existingObjectWithID:error:は該当オブジェクトがNSManagedObjectContextに登録されてない場合に
             必ずしも非Faultになるわけではなかった。
             */
            
            NSMutableArray *fetchResults = [NSMutableArray arrayWithCapacity:[ids count]];
            for (NSManagedObjectID *objId in ids) {
                NSError *error = nil;
                NSManagedObject *obj = [self.mainContext existingObjectWithID:objId error:&error];
                if (obj == nil || error) {
                    NSLog(@"Error: Fetch; error = %@;", error);
                    if (completion) completion(self.mainContext, nil, error);
                    return;
                }
                [fetchResults addObject:obj];
            }
            LOG_YSCORE_DATA(@"Success: Fetch %@", @([fetchResults count]));
            if (completion) completion(self.mainContext, fetchResults, nil);
        }];
    }];
}

#pragma mark - remove

- (BOOL)removeRecordWithConfigureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                                        error:(NSError**)errorPtr
                                didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite
{
    NSError *error = nil;
    if ([self removeObjectsWithConfigureFetchRequest:configure error:&error]) {
        [self saveMainContextWithSave:errorPtr didSaveSQLite:didSaveSQLite];
        return YES;
    } else {
        if (errorPtr != NULL) {
            *errorPtr = error;
        }
        if (didSaveSQLite) {
            didSaveSQLite(self.mainContext, error);
        }
        return NO;
    }
    return YES;
}

- (BOOL)removeAllObjectsWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel
                                         error:(NSError**)errorPtr
                                 didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite
{
    for (NSEntityDescription *entity in [managedObjectModel entities]) {
        NSError *error = nil;
        BOOL success = [self removeObjectsWithConfigureFetchRequest:^NSFetchRequest *(NSManagedObjectContext *context, YSCoreDataOperation *operation) {
            NSFetchRequest *req = [[NSFetchRequest alloc] init];
            req.entity = entity;
            return req;
        } error:&error];
        
        if (!success) {
            if (error && errorPtr != NULL) {
                *errorPtr = error;
            }
            if (didSaveSQLite) didSaveSQLite(self.mainContext, error);
            return NO;
        }
    }
    [self saveMainContextWithSave:errorPtr didSaveSQLite:didSaveSQLite];
    return YES;
}

- (BOOL)removeObjectsWithConfigureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                                         error:(NSError**)errorPtr
{
    NSError *error = nil;
    NSArray *results = [self excuteFetchWithContext:self.mainContext configureFetchRequest:configure error:&error];
    if (error) {
        if (errorPtr != NULL) {
            *errorPtr = error;
        }
        return NO;
    }
    for (NSManagedObject *obj in results) {
        [self.mainContext deleteObject:obj];
    }
    return YES;
}

- (void)asyncRemoveRecordWithConfigureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                                        completion:(YSCoreDataOperationCompletion)completion
                                     didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite
{
    [self.temporaryContext performBlock:^{
        NSError *error = nil;
        NSArray *results = [self excuteFetchWithContext:self.temporaryContext
                                  configureFetchRequest:configure
                                                  error:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(self.temporaryContext, error);
            });
            return;
        }
        
        if ([results count] == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                LOG_YSCORE_DATA(@"Fetch result is none");
                if (completion) completion(self.temporaryContext, nil);
            });
            return;
        }
        
        for (NSManagedObject *manaObj in results) {
            [self.temporaryContext deleteObject:manaObj];
        }
        
        if (self.isCancelled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                LOG_YSCORE_DATA(@"Cancel: asycnRemove; did deleteObject;");
                if (completion) completion(self.temporaryContext,
                                           [YSCoreDataError cancelErrorWithType:YSCoreDataErrorOperationTypeRemove]);
            });
            return;
        }
        
        [self asyncSaveTemporaryContextWithDidMergeMainContext:completion
                            didSaveSQLite:didSaveSQLite];
    }];
}

#pragma mark - excute

- (NSArray*)excuteFetchWithContext:(NSManagedObjectContext*)context
             configureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                             error:(NSError**)error
{
    NSFetchRequest *req;
    if (configure) {
        req = configure(context, self);
        
        if (req == nil) {
            NSString *desc = @"Fetch request is nil";
            if (error != NULL) {
                *error = [YSCoreDataError requiredArgumentIsNilErrorWithDescription:desc];
            }
            return nil;
        }
    } else {
        NSString *desc = @"Fetch configure is nil";
        if (error != NULL) {
            *error = [YSCoreDataError requiredArgumentIsNilErrorWithDescription:desc];
        }
        return nil;
    }
    
    if (self.isCancelled) {
        LOG_YSCORE_DATA(@"Cancel: asyncFetch; will execute fetch request;");
        if (error != NULL) {
            *error = [YSCoreDataError cancelErrorWithType:YSCoreDataErrorOperationTypeFetch];
        }
        return nil;
    }
    
    NSArray *results = [context executeFetchRequest:req error:error];
    
    if ((error && *error)) {
        LOG_YSCORE_DATA(@"Error: -executeFetchRequest:error:; error = %@;", *error);
        return nil;
    }
    
    if (self.isCancelled) {
        LOG_YSCORE_DATA(@"Cancel: asyncFetch; did execute fetch request;");
        if (error != NULL) {
            *error = [YSCoreDataError cancelErrorWithType:YSCoreDataErrorOperationTypeFetch];
        }
        return nil;
    }
    
    return results;
}

#pragma mark - save

- (BOOL)saveMainContextWithSave:(NSError**)errorPtr didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite
{
    NSError *error = nil;
    [self.mainContext save:&error];
    if (error) {
        if (errorPtr != NULL) {
            *errorPtr = error;
        }
        if (didSaveSQLite) didSaveSQLite(self.mainContext, error);
        return NO;
    }
    [self asyncSavePrivateWriterContextWithDidSaveSQLite:didSaveSQLite];
    return YES;
}

- (void)asyncSaveTemporaryContextWithDidMergeMainContext:(YSCoreDataOperationCompletion)didMergeMainContext
                      didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite
{
    /*
     temporaryContextの-performBlock:から呼び出されることを前提としている
     */
    
    // コンテキストが変更されていなければ保存しない
    if (!self.temporaryContext.hasChanges) {
        LOG_YSCORE_DATA(@"temporaryContext.hasChanges == NO");
        dispatch_async(dispatch_get_main_queue(), ^{
            if (didMergeMainContext) didMergeMainContext(self.mainContext, nil);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (didSaveSQLite) didSaveSQLite(self.privateWriterContext, nil);
            });
        });
        return;
    }
    
    NSError *error = nil;
    LOG_YSCORE_DATA(@"Will save temporaryContext");
    if (![self.temporaryContext save:&error]) { // mainContextに変更をプッシュ(マージされる)
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Error: temporaryContext save; error = %@;", error);
            if (didMergeMainContext) didMergeMainContext(self.temporaryContext, [YSCoreDataError saveErrorWithType:YSCoreDataErrorSaveTypeTemporaryContext]);
        });
        return;
    }
    LOG_YSCORE_DATA(@"Did save temporaryContext");
    [self.mainContext performBlock:^{
        if (didMergeMainContext) didMergeMainContext(self.mainContext, nil);
        NSError *error = nil;
        if (![self.mainContext save:&error]) { // privateWriterContextに変更をプッシュ(マージされる)
            NSLog(@"Error: mainContext save; error = %@;", error);
            if (didSaveSQLite) didSaveSQLite(self.mainContext,
                                             [YSCoreDataError saveErrorWithType:YSCoreDataErrorSaveTypeMainContext]);
            return ;
        }
        LOG_YSCORE_DATA(@"Did save mainContext");
        [self asyncSavePrivateWriterContextWithDidSaveSQLite:didSaveSQLite];
    }];
}

- (void)asyncSavePrivateWriterContextWithDidSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite
{
    [self.privateWriterContext performBlock:^{
        NSError *error = nil;
        if (![self.privateWriterContext save:&error]) { // SQLiteへ保存
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Error: privateWriterContext save; error = %@;", error);
                if (didSaveSQLite) didSaveSQLite(self.privateWriterContext,
                                                 [YSCoreDataError saveErrorWithType:YSCoreDataErrorSaveTypePrivateWriterContext]);
            });
            return ;
        }
        LOG_YSCORE_DATA(@"Did save privateWriterContext");
        if (didSaveSQLite) {
            dispatch_async(dispatch_get_main_queue(), ^{
                didSaveSQLite(self.privateWriterContext, nil);
            });
        }
    }];
}

#pragma mark -

- (void)cancel
{
    _isCancelled = YES;
}

@end
