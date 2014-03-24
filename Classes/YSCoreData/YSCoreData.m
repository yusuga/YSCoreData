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
@property (nonatomic, copy) NSString *modelName;
@property (nonatomic) NSManagedObjectContext *privateWriterContext;

@property (nonatomic) NSString *databaseFullPath;

@end


@implementation YSCoreData
@synthesize mainContext = _mainContext;

- (instancetype)initWithDirectoryType:(YSCoreDataDirectoryType)directoryType
                         databasePath:(NSString *)databasePath
{
    return [self initWithDirectoryType:directoryType databasePath:databasePath modelName:nil];
}

- (instancetype)initWithDirectoryType:(YSCoreDataDirectoryType)directoryType
                         databasePath:(NSString *)databasePath
                            modelName:(NSString *)modelName
{
    if (self = [super init]) {
        self.databaseFullPath = [self databaseFullPathWithDirectoryType:directoryType databasePath:databasePath];
        self.modelName = modelName;
        [self privateWriterContext]; // setup
    }
    return self;
}

- (NSString*)databaseFullPathWithDirectoryType:(YSCoreDataDirectoryType)directoryType databasePath:(NSString*)databasePath
{
    if (directoryType == YSCoreDataDirectoryTypeMainBundle) {
        return [[NSBundle mainBundle] pathForResource:databasePath ofType:nil];
    }
    
    NSString *basePath;
    switch (directoryType) {
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
            NSAssert2(0, @"Unexpected error: %s; Unknown directoryType = %@;", __func__, @(directoryType));
            break;
    }
    NSString *dbPath = databasePath;
    if (databasePath == nil || databasePath.length == 0) {
        dbPath = @"Database.db";
    }
    NSArray *pathComponents = [dbPath pathComponents];
    if ([pathComponents count] > 1) {
        // ディレクトリの作成
        [YSFileManager createDirectoryAtPath:[basePath stringByAppendingPathComponent:[databasePath stringByDeletingLastPathComponent]]];
    }
    return [basePath stringByAppendingPathComponent:databasePath];
}

- (BOOL)deleteDatabase
{
    NSLog(@"%s", __func__);
    NSString *path = self.databaseFullPath;
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
                                               didSaveSQLite:(void (^)(void))didSaveSQLite
{
    NSManagedObjectContext *tempContext = [self newTemporaryContext];
    
    YSCoreDataOperation *ope = [[YSCoreDataOperation alloc] initWithTemporaryContext:tempContext
                                                                         mainContext:self.mainContext
                                                                privateWriterContext:self.privateWriterContext];
    [ope asyncWriteWithconfigureManagedObject:configure
                                      success:success
                                      failure:failure
                                didSaveSQLite:didSaveSQLite];
    return ope;
}

- (YSCoreDataOperation*)asyncFetchWithConfigureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                                                    success:(YSCoreDataOperationFetchSuccess)success
                                                    failure:(YSCoreDataOperationFailure)failure
{
    NSManagedObjectContext *tempContext = [self newTemporaryContext];
    
    YSCoreDataOperation *ope = [[YSCoreDataOperation alloc] initWithTemporaryContext:tempContext
                                                                         mainContext:self.mainContext
                                                                privateWriterContext:self.privateWriterContext];
    [ope asyncFetchWithConfigureFetchRequest:configure
                                     success:success
                                     failure:failure];
    return ope;    
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
                                                     didSaveSQLite:(void (^)(void))didSaveSQLite
{    
    NSManagedObjectContext *tempContext = [self newTemporaryContext];
    
    YSCoreDataOperation *ope = [[YSCoreDataOperation alloc] initWithTemporaryContext:tempContext
                                                                         mainContext:self.mainContext
                                                                privateWriterContext:self.privateWriterContext];
    [ope asyncRemoveRecordWithConfigureFetchRequest:configure
                                            success:success
                                            failure:failure
                                      didSaveSQLite:didSaveSQLite];
    return ope;
}

#pragma mark - Property

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator == nil) {
        LOG_YSCORE_DATA(@"Init %s", __func__);
        NSURL *url = [NSURL fileURLWithPath:self.databaseFullPath];
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]) {
            NSLog(@"Error: %s; error = %@;", __func__, error);
        }
#if DEBUG
        NSLog(@"Database full path = %@", self.databaseFullPath);
#endif
    }
    return _persistentStoreCoordinator;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel == nil) {
        LOG_YSCORE_DATA(@"Init %s", __func__);
        if (self.modelName) {
            NSURL *modelUrl = [[NSBundle mainBundle] URLForResource:@"modelUrl" withExtension:@"momd"];
            _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelUrl];
        } else {
            _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
        }
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
