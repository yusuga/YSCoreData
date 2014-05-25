//
//  YSCoreData.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/13.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "YSCoreData.h"

@interface YSCoreData ()

@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, copy) NSString *modelName;
@property (nonatomic) NSManagedObjectContext *privateWriterContext;
@property (nonatomic) NSString *storeType;

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
    return [self initWithDirectoryType:directoryType databasePath:databasePath modelName:modelName storeType:NSSQLiteStoreType];
}

- (instancetype)initWithDirectoryType:(YSCoreDataDirectoryType)directoryType
                         databasePath:(NSString *)databasePath
                            modelName:(NSString *)modelName
                            storeType:(NSString *)storeType
{
    if (self = [super init]) {
        self.databaseFullPath = [self databaseFullPathWithDirectoryType:directoryType databasePath:databasePath];
        self.modelName = modelName;
        self.storeType = storeType;
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
        default:
            NSAssert2(0, @"Unexpected error: %s; Unknown directoryType = %@;", __func__, @(directoryType));
        case YSCoreDataDirectoryTypeDocument:
        {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                 NSUserDomainMask,
                                                                 YES);
            basePath = [paths objectAtIndex:0];
            break;
        }
        case YSCoreDataDirectoryTypeTemporary:
            basePath = NSTemporaryDirectory();
            break;
        case YSCoreDataDirectoryTypeCaches:
        {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                                 NSUserDomainMask,
                                                                 YES);
            basePath = [paths objectAtIndex:0];
            break;
        }
    }
    NSString *dbPath = databasePath;
    if (databasePath == nil || databasePath.length == 0) {
        dbPath = @"Database.db";
    }
    if ([[dbPath pathComponents] count] > 1) {
        // ディレクトリの作成
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        [fileManager createDirectoryAtPath:[basePath stringByAppendingPathComponent:
                                            [databasePath stringByDeletingLastPathComponent]]
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error];
        NSAssert1(error == nil, @"error: %@", error);
    }
    return [basePath stringByAppendingPathComponent:databasePath];
}

- (BOOL)deleteDatabase
{
    NSLog(@"%s", __func__);
    NSString *path = self.databaseFullPath;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    BOOL ret = [fileManager removeItemAtPath:path error:NULL];
    [fileManager removeItemAtPath:[path stringByAppendingString:@"-shm"] error:NULL];
    [fileManager removeItemAtPath:[path stringByAppendingString:@"-wal"] error:NULL];
    
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

#pragma mark - write

- (BOOL)writeWithConfigureManagedObject:(YSCoreDataOperationWriteConfigure)configure
                                  error:(NSError **)errorPtr
                           didSaveStore:(YSCoreDataOperationCompletion)didSaveStore
{
    YSCoreDataOperation *ope = [[YSCoreDataOperation alloc] initWithTemporaryContext:self.mainContext
                                                                         mainContext:self.mainContext
                                                                privateWriterContext:self.privateWriterContext];
    
    return [ope writeWithConfigureManagedObject:configure error:errorPtr didSaveStore:didSaveStore];
}

- (YSCoreDataOperation*)asyncWriteWithConfigureManagedObject:(YSCoreDataOperationWriteConfigure)configure
                                                  completion:(YSCoreDataOperationCompletion)completion
                                                didSaveStore:(YSCoreDataOperationCompletion)didSaveStore
{
    NSManagedObjectContext *tempContext = [self newTemporaryContext];
    
    YSCoreDataOperation *ope = [[YSCoreDataOperation alloc] initWithTemporaryContext:tempContext
                                                                         mainContext:self.mainContext
                                                                privateWriterContext:self.privateWriterContext];
    [ope asyncWriteWithConfigureManagedObject:configure
                                   completion:completion
                                 didSaveStore:didSaveStore];
    return ope;
}

#pragma mark - fetch

- (NSArray*)fetchWithConfigureFetchRequest:(YSCoreDataOperationFetchRequestConfigure)configure
                                     error:(NSError **)errorPtr
{
    YSCoreDataOperation *ope = [[YSCoreDataOperation alloc] initWithTemporaryContext:self.mainContext
                                                                         mainContext:self.mainContext
                                                                privateWriterContext:self.privateWriterContext];
    
    return [ope fetchWithConfigureFetchRequest:configure error:errorPtr];
}

- (YSCoreDataOperation*)asyncFetchWithConfigureFetchRequest:(YSCoreDataOperationFetchRequestConfigure)configure
                                                 completion:(YSCoreDataOperationFetchCompletion)completion
{
    NSManagedObjectContext *tempContext = [self newTemporaryContext];
    
    YSCoreDataOperation *ope = [[YSCoreDataOperation alloc] initWithTemporaryContext:tempContext
                                                                         mainContext:self.mainContext
                                                                privateWriterContext:self.privateWriterContext];
    [ope asyncFetchWithConfigureFetchRequest:configure
                                  completion:completion];
    return ope;
}

#pragma mark - remove

- (BOOL)removeObjectsWithConfigureFetchRequest:(YSCoreDataOperationFetchRequestConfigure)configure
                                         error:(NSError **)errorPtr
                                  didSaveStore:(YSCoreDataOperationCompletion)didSaveStore
{
    YSCoreDataOperation *ope = [[YSCoreDataOperation alloc] initWithTemporaryContext:self.mainContext
                                                                         mainContext:self.mainContext
                                                                privateWriterContext:self.privateWriterContext];
    
    return [ope removeObjectsWithConfigureFetchRequest:configure error:errorPtr didSaveStore:didSaveStore];
}

- (BOOL)removeAllObjectsWithError:(NSError **)errorPtr
                     didSaveStore:(YSCoreDataOperationCompletion)didSaveStore
{
    YSCoreDataOperation *ope = [[YSCoreDataOperation alloc] initWithTemporaryContext:self.mainContext
                                                                         mainContext:self.mainContext
                                                                privateWriterContext:self.privateWriterContext];
    
    return [ope removeAllObjectsWithManagedObjectModel:self.managedObjectModel error:errorPtr didSaveStore:didSaveStore];
}

- (YSCoreDataOperation*)asyncRemoveRecordWithConfigureFetchRequest:(YSCoreDataOperationFetchRequestConfigure)configure
                                                        completion:(YSCoreDataOperationCompletion)completion
                                                      didSaveStore:(YSCoreDataOperationCompletion)didSaveStore
{
    NSManagedObjectContext *tempContext = [self newTemporaryContext];
    
    YSCoreDataOperation *ope = [[YSCoreDataOperation alloc] initWithTemporaryContext:tempContext
                                                                         mainContext:self.mainContext
                                                                privateWriterContext:self.privateWriterContext];
    [ope asyncRemoveRecordWithConfigureFetchRequest:configure
                                         completion:completion
                                       didSaveStore:didSaveStore];
    return ope;
}

#pragma mark - count

- (NSUInteger)countRecordWithEntitiyName:(NSString*)entityName
{
    return [self countRecordWithContext:self.mainContext entitiyName:entityName];
}

- (NSDictionary*)countAllEntitiesByName
{
    NSDictionary *allEntities = [self.managedObjectModel entitiesByName];
    NSMutableDictionary *countAllEntities = [NSMutableDictionary dictionaryWithCapacity:[allEntities count]];
    for (NSString *entityName in [allEntities allKeys]) {
        [countAllEntities setObject:@([self countRecordWithEntitiyName:entityName]) forKey:entityName];
    }
    return countAllEntities;
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

#pragma mark - property

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator == nil) {
        LOG_YSCORE_DATA(@"Init %s", __func__);
        NSURL *url = [NSURL fileURLWithPath:self.databaseFullPath];
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:self.storeType configuration:nil URL:url options:nil error:&error]) {
            NSAssert1(0, @"NSPersistentStoreCoordinator error: %@", error);
            NSLog(@"NSPersistentStoreCoordinator error: %@", error);
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
            NSURL *modelUrl;
            if ([self.modelName pathExtension].length) {
                modelUrl = [[NSBundle mainBundle] URLForResource:[self.modelName stringByDeletingPathExtension]
                                                   withExtension:[self.modelName pathExtension]];
            } else {
                modelUrl = [[NSBundle mainBundle] URLForResource:self.modelName
                                                   withExtension:@"momd"];
            }
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

#pragma mark - helper



@end
