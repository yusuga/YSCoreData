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

- (NSManagedObjectContext *)createTemporaryContext
{
    LOG_YSCOREDATA(@"%s", __func__);
    NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    temporaryContext.parentContext = self.mainContext;
    return temporaryContext;
}

- (void)saveWithTemporaryContext:(NSManagedObjectContext*)temporaryContext
{
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

#pragma mark - Queue

+ (dispatch_queue_t)insertQueue
{
    static dispatch_queue_t s_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_queue = dispatch_queue_create("jp.YSCoreData.insert.queue", NULL);
    });
    return s_queue;
}

+ (dispatch_queue_t)fetchQueue
{
    static dispatch_queue_t s_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_queue = dispatch_queue_create("jp.YSCoreData.fetch.queue", NULL);
    });
    return s_queue;
}

@end
