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
@property (nonatomic) NSManagedObjectContext *writerContext;

@end

@implementation YSCoreDataOperation
@synthesize isCancelled = _isCancelled;

+ (dispatch_queue_t)operationDispatchQueue
{
    static dispatch_queue_t __queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __queue = dispatch_queue_create("jp.YuSugawara.YSCoreDataOperation.queue", NULL);
    });
    return __queue;
}

#pragma mark -

- (instancetype)init
{
    abort();
}

- (instancetype)initWithTemporaryContext:(NSManagedObjectContext*)temporaryContext
                             mainContext:(NSManagedObjectContext*)mainContext
                           writerContext:(NSManagedObjectContext*)writerContext
{
    NSParameterAssert(temporaryContext != nil);
    NSParameterAssert(mainContext != nil);
    NSParameterAssert(writerContext != nil);
    
    if (temporaryContext == nil || mainContext == nil || writerContext == nil) {
        return nil;
    }
    
    if (self = [super init]) {
        self.temporaryContext = temporaryContext;
        self.mainContext = mainContext;
        self.writerContext = writerContext;
    }
    return self;
}

#pragma mark - Write
#pragma mark Sync

- (BOOL)writeWithWriteBlock:(YSCoreDataOperationWriteBlock)writeBlock
                      error:(NSError**)errorPtr
{
    NSParameterAssert([NSThread isMainThread]);
    NSParameterAssert(writeBlock);
    
    writeBlock(self.mainContext, self);
    return [self saveMainContextWithError:errorPtr];
}

#pragma mark Async

- (void)writeWithWriteBlock:(YSCoreDataOperationWriteBlock)writeBlock
                 completion:(YSCoreDataOperationCompletion)completion
{
    NSParameterAssert(writeBlock);
    
    __strong typeof(self) strongSelf = self;
    dispatch_async([[self class] operationDispatchQueue], ^{
        [strongSelf.temporaryContext performBlock:^{
            writeBlock(strongSelf.temporaryContext, strongSelf);
            
            if (strongSelf.isCancelled) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError *error = [YSCoreDataError cancelErrorWithType:YSCoreDataErrorOperationTypeWrite];
                    if (completion) completion(strongSelf, error);
                    if (strongSelf.didSaveStore) strongSelf.didSaveStore(strongSelf, error);
                });
            } else {
                [strongSelf saveTemporaryContextWithDidMergeMainContext:completion];
            }
        }];
    });
}

#pragma mark - Fetch

- (NSArray*)fetchWithFetchRequestBlock:(YSCoreDataOperationFetchRequestBlock)fetchRequestBlock
                                 error:(NSError**)errorPtr
{
    NSParameterAssert(fetchRequestBlock);
    
    return [self executeFetchRequestWithContext:self.mainContext
                              fetchRequestBlock:fetchRequestBlock
                                          error:errorPtr];
}

- (void)fetchWithFetchRequestBlock:(YSCoreDataOperationFetchRequestBlock)fetchRequestBlock
                        completion:(YSCoreDataOperationFetchCompletion)completion
{
    __strong typeof(self) strongSelf = self;
    [self.temporaryContext performBlock:^{
        NSError *error = nil;
        NSArray *results = [strongSelf executeFetchRequestWithContext:strongSelf.temporaryContext
                                                    fetchRequestBlock:fetchRequestBlock
                                                                error:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(strongSelf, nil, error);
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
            for (NSManagedObjectID *objID in ids) {
                NSError *error = nil;
                NSManagedObject *obj = [strongSelf.mainContext existingObjectWithID:objID error:&error];
                if (obj == nil || error) {
                    NSLog(@"Error: Fetch; error = %@;", error);
                    if (completion) completion(strongSelf, nil, error);
                    return;
                }
                [fetchResults addObject:obj];
            }
            LOG_YSCORE_DATA(@"Success: Fetch %@", @([fetchResults count]));
            
            if (completion) completion(strongSelf, [NSArray arrayWithArray:fetchResults], nil);
        }];
    }];
}

#pragma mark - remove
#pragma mark Sync

- (BOOL)removeObjectsWithFetchRequestBlock:(YSCoreDataOperationFetchRequestBlock)fetchRequestBlock
                                     error:(NSError**)errorPtr
{
    NSParameterAssert([NSThread isMainThread]);
    
    NSError *error = nil;
    if ([self removeObjectsWithContext:self.mainContext fetchRequestBlock:fetchRequestBlock error:&error]) {
        [self saveMainContextWithError:errorPtr];
        return YES;
    } else {
        if (errorPtr) *errorPtr = error;
        if (self.didSaveStore) self.didSaveStore(self, error);
        return NO;
    }
}

- (BOOL)removeAllObjectsWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel
                                         error:(NSError**)errorPtr
{
    NSParameterAssert([NSThread isMainThread]);
    
    for (NSEntityDescription *entity in [managedObjectModel entities]) {
        NSError *error = nil;
        if (![self removeObjectsWithContext:self.mainContext fetchRequestBlock:^NSFetchRequest *(NSManagedObjectContext *context, YSCoreDataOperation *operation) {
            NSFetchRequest *req = [[NSFetchRequest alloc] init];
            req.entity = entity;
            return req;
        } error:&error]) {
            if (error && errorPtr != NULL) {
                *errorPtr = error;
            }
            if (self.didSaveStore) self.didSaveStore(self, error);
            return NO;
        }
    }
    
    return [self saveMainContextWithError:errorPtr];
}

#pragma mark Async

- (void)removeObjectsWithFetchRequestBlock:(YSCoreDataOperationFetchRequestBlock)fetchRequestBlock
                                completion:(YSCoreDataOperationCompletion)completion
{
    NSParameterAssert(fetchRequestBlock);
    
    __strong typeof(self) strongSelf = self;
    dispatch_async([[self class] operationDispatchQueue], ^{
        [strongSelf.temporaryContext performBlock:^{
            NSError *error = nil;
            if (![strongSelf removeObjectsWithContext:strongSelf.temporaryContext fetchRequestBlock:fetchRequestBlock error:&error]) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion(strongSelf, error);
                    if (strongSelf.didSaveStore) strongSelf.didSaveStore(strongSelf, error);
                });
                return ;
            }
            
            if (strongSelf.isCancelled) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError *error = [YSCoreDataError cancelErrorWithType:YSCoreDataErrorOperationTypeRemove];
                    if (completion) completion(strongSelf, error);
                    if (strongSelf.didSaveStore) strongSelf.didSaveStore(strongSelf, error);
                });
            } else {
                [strongSelf saveTemporaryContextWithDidMergeMainContext:completion];
            }
        }];
    });
}

#pragma mark Private

- (BOOL)removeObjectsWithContext:(NSManagedObjectContext*)context
               fetchRequestBlock:(YSCoreDataOperationFetchRequestBlock)fetchRequestBlock
                           error:(NSError**)errorPtr
{
    NSError *error = nil;
    NSArray *results = [self executeFetchRequestWithContext:context fetchRequestBlock:fetchRequestBlock error:&error];
    
    if (error) {
        if (errorPtr) *errorPtr = error;
        return NO;
    }
    for (NSManagedObject *obj in results) {
        [context deleteObject:obj];
    }
    return YES;
}

#pragma mark - Execute

- (NSArray*)executeFetchRequestWithContext:(NSManagedObjectContext*)context
                         fetchRequestBlock:(YSCoreDataOperationFetchRequestBlock)fetchRequestBlock
                                     error:(NSError**)errorPtr
{
    NSFetchRequest *req = fetchRequestBlock(context, self);
    if (req == nil) {
        NSString *desc = @"Fetch request is nil";
        if (errorPtr != NULL) {
            *errorPtr = [YSCoreDataError requiredArgumentIsNilErrorWithDescription:desc];
        }
        return nil;
    }
    
    if (self.isCancelled) {
        LOG_YSCORE_DATA(@"Cancel: asyncFetch; will execute fetch request;");
        if (errorPtr) {
            *errorPtr = [YSCoreDataError cancelErrorWithType:YSCoreDataErrorOperationTypeFetch];
        }
        return nil;
    }
    
    NSArray *results = [context executeFetchRequest:req error:errorPtr];
    
    if (errorPtr && *errorPtr) {
        LOG_YSCORE_DATA(@"Error: -executeFetchRequest:error:; error = %@;", *error);
        return nil;
    }
    
    if (self.isCancelled) {
        LOG_YSCORE_DATA(@"Cancel: asyncFetch; did execute fetch request;");
        if (errorPtr) {
            *errorPtr = [YSCoreDataError cancelErrorWithType:YSCoreDataErrorOperationTypeFetch];
        }
        return nil;
    }
    
    return results;
}

#pragma mark - Save

- (BOOL)saveContext:(NSManagedObjectContext*)context withError:(NSError**)errorPtr
{
    if (!context.hasChanges) {
        return YES;
    }
    return [context save:errorPtr];
}

- (void)saveTemporaryContextWithDidMergeMainContext:(YSCoreDataOperationCompletion)didMergeMainContext
{
    __strong typeof(self) strongSelf = self;
    [self.temporaryContext performBlock:^{
        NSError *error = nil;
        [strongSelf saveContext:strongSelf.temporaryContext withError:&error]; // mainContextに変更をプッシュ(マージされる)
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (didMergeMainContext) {
                didMergeMainContext(strongSelf, error);
            }
            if (error == nil) {
                [strongSelf saveMainContextWithError:NULL];
            }
        });
    }];
}

- (BOOL)saveMainContextWithError:(NSError**)errorPtr
{
    NSParameterAssert([NSThread isMainThread]);
    
    NSError *error = nil;
    if ([self saveContext:self.mainContext withError:&error]) { // privateWriterContextに変更をプッシュ(マージされる)
        [self saveWriterContext];
        return YES;
    } else {
        if (errorPtr) *errorPtr = error;
        if (self.didSaveStore) self.didSaveStore(self, error);
        return NO;
    }
}

- (void)saveWriterContext
{
    __strong typeof(self) strongSelf = self;
    [self.writerContext performBlock:^{
        NSError *error = nil;
        [strongSelf saveContext:strongSelf.writerContext withError:&error]; // SQLiteへ保存
        
        if (strongSelf.didSaveStore) {
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.didSaveStore(strongSelf, error);
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

@end
