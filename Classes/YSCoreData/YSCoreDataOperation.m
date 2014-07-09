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
@synthesize isCancelled = _isCancelled;
@synthesize isCompleted = _isCompleted;

- (id)init
{
    abort();
}

- (id)initWithTemporaryContext:(NSManagedObjectContext*)temporaryContext
                   mainContext:(NSManagedObjectContext*)mainContext
          privateWriterContext:(NSManagedObjectContext*)privateWriterContext
{
    if (temporaryContext == nil || mainContext == nil || privateWriterContext == nil) {
        NSAssert3(0, @"context is nil; temporaryContext: %@, mainContext: %@, privateWriterContext: %@", temporaryContext, mainContext, privateWriterContext);
        return nil;
    }
    
    if (self = [super init]) {
        self.temporaryContext = temporaryContext;
        self.mainContext = mainContext;
        self.privateWriterContext = privateWriterContext;
    }
    return self;
}

#pragma mark - write

- (BOOL)writeWithConfigureManagedObject:(YSCoreDataOperationWriteConfigure)configure
                                  error:(NSError**)errorPtr
                           didSaveStore:(YSCoreDataOperationCompletion)didSaveStore
{
    if (configure == nil) {
        NSError *coreDataError = [YSCoreDataError requiredArgumentIsNilErrorWithDescription:@"Write setting is nil"];
        if (errorPtr != NULL) {
            *errorPtr = coreDataError;
        }
        if (didSaveStore) didSaveStore(self, coreDataError);
        return NO;
    }
    configure(self.mainContext, self);
    return [self saveMainContextWithSave:errorPtr didSaveStore:didSaveStore];
}

- (void)asyncWriteWithConfigureManagedObject:(YSCoreDataOperationWriteConfigure)configure
                                  completion:(YSCoreDataOperationCompletion)completion
                                didSaveStore:(YSCoreDataOperationCompletion)didSaveStore
{
    __strong typeof(self) strongSelf = self;
    [self.temporaryContext performBlock:^{
        if (configure) {
            configure(strongSelf.temporaryContext, strongSelf);
            
            if (self.isCancelled) {
                LOG_YSCORE_DATA(@"Cancel: asyncWrite");
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError *error = [YSCoreDataError cancelErrorWithType:YSCoreDataErrorOperationTypeWrite];
                    if (completion) completion(strongSelf, error);
                    if (didSaveStore) didSaveStore(strongSelf, error);
                });
                return ;
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error = [YSCoreDataError requiredArgumentIsNilErrorWithDescription:@"Write setting is nil"];
                if (completion) completion(strongSelf, error);
                if (didSaveStore) didSaveStore(strongSelf, error);
            });
            return ;
        }
        
        [self asyncSaveTemporaryContextWithDidMergeMainContext:completion
                                                  didSaveStore:didSaveStore];
    }];
}

#pragma mark - fetch

- (NSArray*)fetchWithConfigureFetchRequest:(YSCoreDataOperationFetchRequestConfigure)configure
                                     error:(NSError**)errorPtr
{
    return [self excuteFetchWithContext:self.mainContext
                  configureFetchRequest:configure
                                  error:errorPtr];
}

- (void)asyncFetchWithConfigureFetchRequest:(YSCoreDataOperationFetchRequestConfigure)configure
                                 completion:(YSCoreDataOperationFetchCompletion)completion
{
    __strong typeof(self) strongSelf = self;
    [self.temporaryContext performBlock:^{
        NSError *error = nil;
        NSArray *results = [strongSelf excuteFetchWithContext:strongSelf.temporaryContext
                                        configureFetchRequest:configure
                                                        error:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(strongSelf, nil, error);
            });
            return;
        }
        
        if ([results count] == 0) {
            LOG_YSCORE_DATA(@"Fetch result is none");
            [strongSelf setCompleted:YES];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(strongSelf, results, nil);
            });
            return;
        }
        
        /*
         FetchしたNSManagedObjectを別スレッドに渡せない(temporaryContextと共に解放される)ので
         スレッドセーフなNSManagedObjectIDを保持する
         ※ NSManagedObject自体は解放されてないんだけどpropertyが解放されている
         */
        NSMutableArray *ids = [NSMutableArray arrayWithCapacity:[results count]];
        for (NSManagedObject *obj in results) {
            [ids addObject:obj.objectID];
        }
        
        [strongSelf.mainContext performBlock:^{ // == dispatch_async(dispatch_get_main_queue(), ^{
            
            if (strongSelf.isCancelled) {
                LOG_YSCORE_DATA(@"Cancel: asyncFetch;");
                if (completion) completion(strongSelf,
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
                NSManagedObject *obj = [strongSelf.mainContext existingObjectWithID:objId error:&error];
                if (obj == nil || error) {
                    NSLog(@"Error: Fetch; error = %@;", error);
                    if (completion) completion(strongSelf, nil, error);
                    return;
                }
                [fetchResults addObject:obj];
            }
            LOG_YSCORE_DATA(@"Success: Fetch %@", @([fetchResults count]));
            
            [self setCompleted:YES];
            if (completion) completion(strongSelf, fetchResults, nil);
        }];
    }];
}

#pragma mark - remove

- (BOOL)removeObjectsWithConfigureFetchRequest:(YSCoreDataOperationFetchRequestConfigure)configure
                                         error:(NSError**)errorPtr
                                  didSaveStore:(YSCoreDataOperationCompletion)didSaveStore
{
    NSError *error = nil;
    if ([self removeObjectsWithConfigureFetchRequest:configure error:&error]) {
        [self saveMainContextWithSave:errorPtr didSaveStore:didSaveStore];
        return YES;
    } else {
        if (errorPtr != NULL) *errorPtr = error;
        if (didSaveStore) didSaveStore(self, error);
        return NO;
    }
}

- (BOOL)removeAllObjectsWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel
                                         error:(NSError**)errorPtr
                                  didSaveStore:(YSCoreDataOperationCompletion)didSaveStore
{
    for (NSEntityDescription *entity in [managedObjectModel entities]) {
        NSError *error = nil;
        BOOL success = [self removeObjectsWithConfigureFetchRequest:^NSFetchRequest *(NSManagedObjectContext *context, YSCoreDataOperation *operation)
                        {
                            NSFetchRequest *req = [[NSFetchRequest alloc] init];
                            req.entity = entity;
                            return req;
                        } error:&error];
        
        if (!success) {
            if (error && errorPtr != NULL) {
                *errorPtr = error;
            }
            if (didSaveStore) didSaveStore(self, error);
            return NO;
        }
    }
    [self saveMainContextWithSave:errorPtr didSaveStore:didSaveStore];
    return YES;
}

- (BOOL)removeObjectsWithConfigureFetchRequest:(YSCoreDataOperationFetchRequestConfigure)configure
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

- (void)asyncRemoveRecordWithConfigureFetchRequest:(YSCoreDataOperationFetchRequestConfigure)configure
                                        completion:(YSCoreDataOperationCompletion)completion
                                      didSaveStore:(YSCoreDataOperationCompletion)didSaveStore
{
    __strong typeof(self) strongSelf = self;
    [self.temporaryContext performBlock:^{
        NSError *error = nil;
        NSArray *results = [self excuteFetchWithContext:self.temporaryContext
                                  configureFetchRequest:configure
                                                  error:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(strongSelf, error);
                if (didSaveStore) didSaveStore(strongSelf, error);
            });
            return;
        }
        
        for (NSManagedObject *manaObj in results) {
            [self.temporaryContext deleteObject:manaObj];
        }
        
        if (self.isCancelled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                LOG_YSCORE_DATA(@"Cancel: asycnRemove; did deleteObject;");
                NSError *error = [YSCoreDataError cancelErrorWithType:YSCoreDataErrorOperationTypeRemove];
                if (completion) completion(strongSelf, error);
                if (didSaveStore) didSaveStore(strongSelf, error);
            });
            return;
        }
        
        [self asyncSaveTemporaryContextWithDidMergeMainContext:completion
                                                  didSaveStore:didSaveStore];
    }];
}

#pragma mark - excute

- (NSArray*)excuteFetchWithContext:(NSManagedObjectContext*)context
             configureFetchRequest:(YSCoreDataOperationFetchRequestConfigure)configure
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
    
    if (error && *error) {
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

- (BOOL)saveMainContextWithSave:(NSError**)errorPtr didSaveStore:(YSCoreDataOperationCompletion)didSaveStore
{
    NSError *error = nil;
    [self.mainContext save:&error];
    if (error) {
        if (errorPtr != NULL) {
            *errorPtr = error;
        }
        if (didSaveStore) didSaveStore(self, error);
        return NO;
    }
    [self setCompleted:YES];
    [self asyncSavePrivateWriterContextWithdidSaveStore:didSaveStore];
    return YES;
}

- (void)asyncSaveTemporaryContextWithDidMergeMainContext:(YSCoreDataOperationCompletion)didMergeMainContext
                                            didSaveStore:(YSCoreDataOperationCompletion)didSaveStore
{
    /*
     temporaryContextの-performBlock:から呼び出されることを前提としている
     */
    
    __strong typeof(self) strongSelf = self;
    
    // コンテキストが変更されていなければ保存しない
    if (!self.temporaryContext.hasChanges) {
        LOG_YSCORE_DATA(@"temporaryContext.hasChanges == NO");
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf setCompleted:YES];
            if (didMergeMainContext) didMergeMainContext(strongSelf, nil);
            if (didSaveStore) didSaveStore(strongSelf, nil);
        });
        return;
    }
    
    NSError *error = nil;
    LOG_YSCORE_DATA(@"Will save temporaryContext");
    if (![self.temporaryContext save:&error]) { // mainContextに変更をプッシュ(マージされる)
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Error: temporaryContext save; error = %@;", error);
            if (didMergeMainContext) didMergeMainContext(strongSelf, error);
            if (didSaveStore) didSaveStore(strongSelf, error);
        });
        return;
    }
    LOG_YSCORE_DATA(@"Did save temporaryContext");
    [self.mainContext performBlock:^{
        [strongSelf setCompleted:YES];
        if (didMergeMainContext) didMergeMainContext(strongSelf, nil);
        NSError *error = nil;
        if (![strongSelf.mainContext save:&error]) { // privateWriterContextに変更をプッシュ(マージされる)
            NSLog(@"Error: mainContext save; error = %@;", error);
            if (didSaveStore) didSaveStore(strongSelf, error);
            return ;
        }
        LOG_YSCORE_DATA(@"Did save mainContext");
        [strongSelf asyncSavePrivateWriterContextWithdidSaveStore:didSaveStore];
    }];
}

- (void)asyncSavePrivateWriterContextWithdidSaveStore:(YSCoreDataOperationCompletion)didSaveStore
{
    __strong typeof(self) strongSelf = self;
    [self.privateWriterContext performBlock:^{
        NSError *error = nil;
        if (![strongSelf.privateWriterContext save:&error]) { // SQLiteへ保存
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Error: privateWriterContext save; error = %@;", error);
                if (didSaveStore) didSaveStore(strongSelf, error);
            });
            return ;
        }
        LOG_YSCORE_DATA(@"Did save privateWriterContext");
        if (didSaveStore) {
            dispatch_async(dispatch_get_main_queue(), ^{
                didSaveStore(strongSelf, nil);
            });
        }
    }];
}

#pragma mark -

- (void)cancel
{
    @synchronized(self) {
        _isCancelled = YES;
    }
}

- (BOOL)isCancelled
{
    @synchronized(self) {
        return _isCancelled;
    }
}

- (void)setCompleted:(BOOL)completed
{
    @synchronized(self) {
        _isCompleted = completed;
    }
}

- (BOOL)isCompleted
{
    @synchronized(self) {
        return _isCompleted;
    }
}

@end
