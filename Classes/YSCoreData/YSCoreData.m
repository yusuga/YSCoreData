//
//  YSCoreData.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/13.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "YSCoreData.h"
#import <YSFileManager/YSFileManager.h>

@interface YSCoreData ()

@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic) NSManagedObjectContext *privateWriterContext;

@property (nonatomic) YSCoreDataDirectoryType directoryType;
@property (nonatomic) NSString *databasePath;
@property (nonatomic) NSString *databaseFullPath;

@end


@implementation YSCoreData
@synthesize mainContext = _mainContext;
@synthesize databaseFullPath = _databaseFullPath;

- (instancetype)initWithDirectoryType:(YSCoreDataDirectoryType)directoryType databasePath:(NSString *)databasePath
{
    if (self = [super init]) {
        self.directoryType = directoryType;
        self.databasePath = databasePath;
        [self privateWriterContext]; // setup
    }
    return self;
}

- (NSString*)databaseFullPath
{
    if (_databaseFullPath == nil) {
        NSString *basePath;
        switch (self.directoryType) {
            case YSCoreDataDirectoryTypeDocument:
                basePath = [YSFileManager documentDirectory];
                break;
            case YSCoreDataDirectoryTypeTemporary:
                basePath = [YSFileManager temporaryDirectory];
                break;
            case YSCoreDataDirectoryTypeCaches:
                basePath = [YSFileManager cachesDirectory];
                break;
            default:
                basePath = [YSFileManager documentDirectory];
                NSAssert2(0, @"Unexpected error: %s; Unknown directoryType = %@;", __func__, @(self.directoryType));
                break;
        }
        NSString *databasePath = self.databasePath;
        if (databasePath == nil || databasePath.length == 0) {
            databasePath = @"Database.db";
        }
        NSArray *pathComponents = [databasePath pathComponents];
        if ([pathComponents count] > 1) {
            // ディレクトリの作成
            [YSFileManager createDirectoryAtPath:[basePath stringByAppendingPathComponent:[databasePath stringByDeletingLastPathComponent]]];
        }
        _databaseFullPath = [basePath stringByAppendingPathComponent:databasePath];
    }
    return _databaseFullPath;
}

- (BOOL)deleteDatabase
{
    NSLog(@"%s", __func__);
    NSString *path = [self databaseFullPath];
    BOOL ret = [YSFileManager removeAtPath:path];
    [YSFileManager removeAtPath:[path stringByAppendingString:@"-shm"]];
    [YSFileManager removeAtPath:[path stringByAppendingString:@"-wal"]];
    self.privateWriterContext = nil;
    _mainContext = nil;
    self.persistentStoreCoordinator = nil;
    return ret;
}

- (NSManagedObjectContext *)newTemporaryContext
{
    /*
     新しいtemporaryContext
     parentContextにmainContextを指定することによって、temporaryContextはこの時点でmainContextが保持しているNSManagedObjectを
     参照することができる
     */
    LOG_YSCORE_DATA(@"%s", __func__);
    NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    temporaryContext.parentContext = self.mainContext;
    return temporaryContext;
}

#pragma mark - Async

- (YSCoreDataOperation*)asyncWriteWithConfigureManagedObject:(YSCoreDataOperationAsyncWriteConfigure)configure
                                                     success:(void (^)(void))success
                                                     failure:(YSCoreDataOperationSaveFailure)failure
{
    YSCoreDataOperation *ope = [[YSCoreDataOperation alloc] init];
    NSManagedObjectContext *tempContext = [self newTemporaryContext];
    
    __weak typeof(self) wself = self;
    [ope asyncWriteWithBackgroundContext:tempContext
                  configureManagedObject:configure
                  successInContextThread:^{
                      // コンテキストが変更されていたらを保存
                      if (tempContext.hasChanges) {
                          // 最終的にprivateWriterContextの-save:によりsqliteへ保存される
                          [wself saveWithTemporaryContext:tempContext
                                      didMergeMainContext:success
                                            didSaveSQLite:nil
                                                  failure:failure];
                      } else {
                          LOG_YSCORE_DATA(@"tempContext.hasChanges == NO");
                          dispatch_async(dispatch_get_main_queue(), ^{
                              if (success) success();
                          });
                      }
                  } failure:^(NSManagedObjectContext *context, NSError *error) {
                      if (failure) failure(context, error);
                  }];
    return ope;
}

- (YSCoreDataOperation*)asyncFetchWithConfigureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                                                    success:(YSCoreDataOperationAsyncFetchSuccess)success
                                                    failure:(YSCoreDataOperationFailure)failure
{
    YSCoreDataOperation *ope = [[YSCoreDataOperation alloc] init];
    NSManagedObjectContext *tempContext = [self newTemporaryContext];
    
    [ope asyncFetchWithBackgroundContext:tempContext
                             mainContext:self.mainContext
                   configureFetchRequest:configure
                  successInContextThread:success
                                 failure:failure];
    
    return ope;    
}

#pragma mark - Save

- (void)saveWithTemporaryContext:(NSManagedObjectContext*)temporaryContext
             didMergeMainContext:(void(^)(void))didMergeMainContext
                   didSaveSQLite:(void(^)(void))didSaveSQLite
                         failure:(YSCoreDataOperationSaveFailure)failure
{
    /*
     temporaryContextの-performBlock:から呼び出されることを前提としている
     */

    __weak typeof(self) wself = self;
    NSError *error = nil;
    LOG_YSCORE_DATA(@"Will save temporaryContext");
    if (![temporaryContext save:&error]) { // mainContextに変更をプッシュ(マージされる)
        NSLog(@"Error: temporaryContext save; error = %@;", error);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failure) failure(temporaryContext, nil);
        });
        return;
    }
    LOG_YSCORE_DATA(@"Did save temporaryContext");
    [wself.mainContext performBlock:^{
        if (didMergeMainContext) didMergeMainContext();
        NSError *error = nil;
        if (![wself.mainContext save:&error]) { // privateWriterContextに変更をプッシュ(マージされる)
            NSLog(@"Error: mainContext save; error = %@;", error);
            if (failure) failure(wself.mainContext, nil);
            return ;
        }
        LOG_YSCORE_DATA(@"Did save mainContext");
        [wself.privateWriterContext performBlock:^{
            NSError *error = nil;
            if (![wself.privateWriterContext save:&error]) { // SQLiteへ保存
                NSLog(@"Error: privateWriterContext save; error = %@;", error);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failure) failure(wself.privateWriterContext, nil);
                });
                return ;
            }
            LOG_YSCORE_DATA(@"Did save privateWriterContext");
            if (didSaveSQLite) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    didSaveSQLite();
                });
            }
        }];
    }];
}

- (NSUInteger)countRecordWithEntitiyName:(NSString*)entityName
{
    return [self countRecordWithContext:self.mainContext entitiyName:entityName];
}

- (NSUInteger)countRecordWithContext:(NSManagedObjectContext*)context entitiyName:(NSString*)entityName
{
    NSFetchRequest* req = [[NSFetchRequest alloc] init];
    [req setEntity:[NSEntityDescription entityForName:entityName
                               inManagedObjectContext:context]];
    [req setIncludesSubentities:NO];
    
    NSError* error = nil;
    NSUInteger count = [context countForFetchRequest:req error:&error];
    return count == NSNotFound ? 0 : count;
}

- (YSCoreDataOperation*)asyncRemoveRecordWithConfigureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                                           success:(void(^)(void))success
                                           failure:(YSCoreDataOperationSaveFailure)failure
{
    YSCoreDataOperation *ope = [[YSCoreDataOperation alloc] init];
    NSManagedObjectContext *tempContext = [self newTemporaryContext];
    
    __weak typeof(self) wself = self;
    [ope asyncRemoveRecordWithBackgroundContext:tempContext
                          configureFetchRequest:configure
                         successInContextThread:^{
                             
                             [wself saveWithTemporaryContext:tempContext
                                         didMergeMainContext:success
                                               didSaveSQLite:nil
                                                     failure:failure];
                             
                         } failure:failure];
    
    return ope;
}

#pragma mark - Property

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator == nil) {
        LOG_YSCORE_DATA(@"Init %s", __func__);
        NSURL *storeUrl = [NSURL fileURLWithPath:[self databaseFullPath]];
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
            NSLog(@"Error: %s; error = %@;", __func__, error);
            NSAssert2(0, @"Unexpected error: %s; error = %@;", __func__, error);
        }
#if DEBUG
        NSLog(@"Database path = %@", [self databaseFullPath]);
#endif
    }
    return _persistentStoreCoordinator;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel == nil) {
        LOG_YSCORE_DATA(@"Init %s", __func__);
        _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    }
    return _managedObjectModel;
}

- (NSManagedObjectContext *)privateWriterContext
{
    if (_privateWriterContext == nil) {
        LOG_YSCORE_DATA(@"Init %s", __func__);
        _privateWriterContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _privateWriterContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    }
    return _privateWriterContext;
}

- (NSManagedObjectContext *)mainContext
{
    if (_mainContext == nil) {
        LOG_YSCORE_DATA(@"Init %s", __func__);
        _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _mainContext.parentContext = self.privateWriterContext;
    }
    return _mainContext;
}

@end
