//
//  YSCoreData.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/13.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "YSCoreData.h"
#import <YSFileManager/YSFileManager.h>

#if DEBUG
    #if 0
        #define LOG_YSCOREDATA(...) NSLog(__VA_ARGS__)
    #endif
#endif

#ifndef LOG_YSCOREDATA
    #define LOG_YSCOREDATA(...)
#endif

@interface YSCoreData ()

@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic) NSManagedObjectContext *privateWriterContext;

@property (nonatomic) NSString *databaseName;

@end

@implementation YSCoreData
@synthesize mainContext = _mainContext;

+ (instancetype)sharedInstance
{
    static id s_sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_sharedInstance =  [[self alloc] init];
    });
    return s_sharedInstance;
}

- (void)setupWithDatabaseName:(NSString*)dbName
{
    self.databaseName = dbName;
    [self privateWriterContext]; // setup
}

- (NSString*)databasePath
{
    return [YSFileManager documentDirectoryWithAppendingPathComponent:self.databaseName];
}

- (BOOL)deleteDatabase
{
    NSLog(@"%s", __func__);
    NSString *path = [self databasePath];
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
    LOG_YSCOREDATA(@"%s", __func__);
    NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    temporaryContext.parentContext = self.mainContext;
    return temporaryContext;
}

#pragma mark - Async

- (void)asyncWriteWithConfigureManagedObject:(YSCoreDataAysncWriteConfigure)configure
                                     success:(void (^)(void))success
                                     failure:(YSCoreDataSaveFailure)failure
{
    NSManagedObjectContext *tempContext = [self newTemporaryContext];

    __weak typeof(self) wself = self;
    [tempContext performBlock:^{
        if (configure) {
            configure(tempContext);
        } else {
            NSLog(@"Error: asyncWrite; setting == nil");
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) failure(tempContext, nil);
            });
            return ;
        }
        
        // コンテキストが変更されていたらを保存
        if (tempContext.hasChanges) {
            // 最終的にprivateWriterContextの-save:によりsqliteへ保存される
            [wself saveWithTemporaryContext:tempContext
                        didMergeMainContext:success
                              didSaveSQLite:nil failure:failure];
        } else {
            if (success) success();
        }
    }];
}

- (void)asyncFetchWithConfigureFetchRequest:(YSCoreDataAysncFetchConfigure)configure
                                    success:(YSCoreDataAysncFetchSuccess)success
                                    failure:(YSCoreDataFailure)failure
{
    NSManagedObjectContext *tempContext = [self newTemporaryContext];
    
    __weak typeof(self) wself = self;
    [tempContext performBlock:^{
        NSFetchRequest *request;
        if (configure) {
            request = configure(tempContext);
        } else {
            NSLog(@"Error: asyncFetch; configure == nil");
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(nil);
            });
            return ;
        }
        
        if (request == nil) {
            NSLog(@"Error: asyncFetch; request == nil");
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) failure(nil);
            });
            return ;
        }
        
        NSError *error = nil;
        NSArray *fetchResults = [tempContext executeFetchRequest:request error:&error];
        
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) failure(error);
            });
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
        
        [wself.mainContext performBlock:^{ // == dispatch_async(dispatch_get_main_queue(), ^{
            /*
             mainContext(NSMainQueueConcurrencyTypeで初期化したContext)から
             保持していたNSManagedObjectIDを元にNSManagedObjectを取得
             */
            NSMutableArray *fetchResults = [NSMutableArray arrayWithCapacity:[ids count]];
            for (NSManagedObjectID *objId in ids) {
                [fetchResults addObject:[wself.mainContext objectWithID:objId]];
            }
            if (success) success(fetchResults);
        }];
    }];
}

#pragma mark - Save

- (void)saveWithTemporaryContext:(NSManagedObjectContext*)temporaryContext
             didMergeMainContext:(void(^)(void))didMergeMainContext
                   didSaveSQLite:(void(^)(void))didSaveSQLite
                         failure:(YSCoreDataSaveFailure)failure
{
    /*
     temporaryContextの-performBlock:から呼び出されることを前提としている
     */

    __weak typeof(self) wself = self;
    NSError *error = nil;
    LOG_YSCOREDATA(@"Will save temporaryContext");
    if (![temporaryContext save:&error]) { // mainContextに変更をプッシュ(マージされる)
        NSLog(@"Error: temporaryContext save; error = %@;", error);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failure) failure(temporaryContext, nil);
        });
        return;
    }
    LOG_YSCOREDATA(@"Did save temporaryContext");
    [wself.mainContext performBlock:^{
        if (didMergeMainContext) didMergeMainContext();
        NSError *error = nil;
        if (![wself.mainContext save:&error]) { // privateWriterContextに変更をプッシュ(マージされる)
            NSLog(@"Error: mainContext save; error = %@;", error);
            if (failure) failure(wself.mainContext, nil);
            return ;
        }
        LOG_YSCOREDATA(@"Did save mainContext");
        [wself.privateWriterContext performBlock:^{
            NSError *error = nil;
            if (![wself.privateWriterContext save:&error]) { // SQLiteへ保存
                NSLog(@"Error: privateWriterContext save; error = %@;", error);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failure) failure(wself.privateWriterContext, nil);
                });
                return ;
            }
            LOG_YSCOREDATA(@"Did save privateWriterContext");
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

- (void)removeRecordWithEntitiyName:(NSString *)entityName
                            success:(void(^)(void))success
                            failure:(YSCoreDataSaveFailure)failure
{
    NSManagedObjectContext *tempContext = [self newTemporaryContext];
    
    __weak typeof(self) wself = self;
    [tempContext performBlock:^{
        NSFetchRequest* req = [[NSFetchRequest alloc] init];
        [req setEntity:[NSEntityDescription entityForName:entityName
                                   inManagedObjectContext:tempContext]];
        NSError* error = nil;
        NSArray *results = [tempContext executeFetchRequest:req error:&error];
        if (error) {
            NSLog(@"Error: execure; error = %@;", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) failure(tempContext, error);
            });
            return;
        }
        for (NSManagedObject *manaObj in results) {
            [tempContext deleteObject:manaObj];
        }
        [wself saveWithTemporaryContext:tempContext didMergeMainContext:^{
            if (success) success();
        } didSaveSQLite:nil failure:failure];
    }];
}

#pragma mark - Property

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator == nil) {
        NSURL *storeUrl = [NSURL fileURLWithPath:[self databasePath]];
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
            NSLog(@"Error: %s; error = %@;", __func__, error);
        }
#if DEBUG
        NSLog(@"Database path = %@", [self databasePath]);
#endif
    }
    return _persistentStoreCoordinator;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel == nil) {
        _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    }
    return _managedObjectModel;
}

- (NSManagedObjectContext *)privateWriterContext
{
    if (_privateWriterContext == nil) {
        _privateWriterContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _privateWriterContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    }
    return _privateWriterContext;
}

- (NSManagedObjectContext *)mainContext
{
    if (_mainContext == nil) {
        _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _mainContext.parentContext = self.privateWriterContext;
    }
    return _mainContext;
}

- (NSString *)databaseName
{
    if (_databaseName) {
        return _databaseName;
    }
    return @"Database.db";
}

@end
