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

- (BOOL)removeDatabase
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
    LOG_YSCOREDATA(@"%s", __func__);
    NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    temporaryContext.parentContext = self.mainContext;
    return temporaryContext;
}

#pragma mark - Async

- (void)asyncWriteWithConfigureManagedObject:(YSCoreDataAysncWriteConfigure)configure failure:(YSCoreDataAysncWriteFailure)failure
{
    NSManagedObjectContext *temporaryContext = [self newTemporaryContext];
    
    __weak typeof(self) wself = self;
    [temporaryContext performBlock:^{
        if (configure) {
            configure(temporaryContext);
        } else {
            NSLog(@"Error: asyncWrite; setting == nil");
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) failure(nil);
            });
            return ;
        }
        
        // コンテキストが変更されていたらを保存
        if (temporaryContext.hasChanges) {
            // 最終的にprivateWriterContextの-save:によりsqliteへ保存される
            [wself saveWithTemporaryContext:temporaryContext];
        }
    }];
}

- (void)asyncFetchWithConfigureFetchRequest:(YSCoreDataAysncFetchConfigure)configure
                                    success:(YSCoreDataAysncFetchSuccess)success
                                    failure:(YSCoreDataAysncFetchFailure)failure
{
    NSManagedObjectContext *temporaryContext = [self newTemporaryContext];
    
    __weak typeof(self) wself = self;
    [temporaryContext performBlock:^{
        NSFetchRequest *request;
        if (configure) {
            request = configure(temporaryContext);
        } else {
            NSLog(@"Error: asyncFetch; setting == nil");
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
        NSArray *fetchResults = [temporaryContext executeFetchRequest:request error:&error];
        
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
{
    /*
     temporaryContextのqueueから呼び出されることを前提としている
     */
    
    __weak typeof(self) wself = self;
    NSError *error = nil;
    LOG_YSCOREDATA(@"Will save temporaryContext");
    if (![temporaryContext save:&error]) { // mainContextに変更をプッシュ(マージされる)
        NSLog(@"Error: temporaryContext save; error = %@;", error);
    }
    LOG_YSCOREDATA(@"Did save temporaryContext");
    [wself.mainContext performBlock:^{
        NSError *error = nil;
        if (![wself.mainContext save:&error]) { // privateWriterContextに変更をプッシュ(マージされる)
            NSLog(@"Error: mainContext save; error = %@;", error);
        }
        LOG_YSCOREDATA(@"Did save mainContext");
        [wself.privateWriterContext performBlock:^{
            NSError *error = nil;
            if (![wself.privateWriterContext save:&error]) { // sqliteへ保存
                NSLog(@"Error: privateWriterContext save; error = %@;", error);
            }
            LOG_YSCOREDATA(@"Did save privateWriterContext");
        }];
    }];
}

- (NSUInteger)countRecordWithEntitiyName:(NSString*)entityName
{
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:entityName
                                   inManagedObjectContext:self.mainContext]];
    [request setIncludesSubentities:NO];
    
    NSError* error = nil;
    NSUInteger count = [self.mainContext countForFetchRequest:request error:&error];
    return count == NSNotFound ? 0 : count;
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
