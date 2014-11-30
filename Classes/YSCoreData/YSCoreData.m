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
@property (nonatomic) NSManagedObjectContext *writerContext;
@property (nonatomic) NSString *storeType;

@property (nonatomic, readwrite) NSString *databaseFullPath;

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
        [self writerContext]; // setup
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
    DDLogWarn(@"%s", __func__);
    NSString *path = self.databaseFullPath;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    BOOL ret = [fileManager removeItemAtPath:path error:NULL];
    [fileManager removeItemAtPath:[path stringByAppendingString:@"-shm"] error:NULL];
    [fileManager removeItemAtPath:[path stringByAppendingString:@"-wal"] error:NULL];
    
    self.writerContext = nil;
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
    NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    temporaryContext.parentContext = self.mainContext;
    return temporaryContext;
}

#pragma mark - write

- (BOOL)writeWithWriteBlock:(YSCoreDataOperationWriteBlock)writeBlock
                      error:(NSError *__autoreleasing *)errorPtr
{
    YSCoreDataOperation *ope = [[YSCoreDataOperation alloc] initWithTemporaryContext:self.mainContext
                                                                         mainContext:self.mainContext
                                                                       writerContext:self.writerContext];
    return [ope writeWithWriteBlock:writeBlock error:errorPtr];
}

- (YSCoreDataOperation*)writeWithWriteBlock:(YSCoreDataOperationWriteBlock)writeBlock
                                 completion:(YSCoreDataOperationCompletion)completion
{
    YSCoreDataOperation *ope = [[YSCoreDataOperation alloc] initWithTemporaryContext:[self newTemporaryContext]
                                                                         mainContext:self.mainContext
                                                                       writerContext:self.writerContext];
    [ope writeWithWriteBlock:writeBlock completion:completion];
    return ope;
}

#pragma mark - fetch

- (NSArray*)fetchWithFetchRequestBlock:(YSCoreDataOperationFetchRequestBlock)fetchRequestBlock
                                 error:(NSError *__autoreleasing *)errorPtr
{
    YSCoreDataOperation *ope = [[YSCoreDataOperation alloc] initWithTemporaryContext:self.mainContext
                                                                         mainContext:self.mainContext
                                                                writerContext:self.writerContext];
    
    return [ope fetchWithFetchRequestBlock:fetchRequestBlock error:errorPtr];
}

- (YSCoreDataOperation*)fetchWithFetchRequestBlock:(YSCoreDataOperationFetchRequestBlock)fetchRequestBlock
                                             completion:(YSCoreDataOperationFetchCompletion)completion
{
    YSCoreDataOperation *ope = [[YSCoreDataOperation alloc] initWithTemporaryContext:[self newTemporaryContext]
                                                                         mainContext:self.mainContext
                                                                       writerContext:self.writerContext];
    
    [ope fetchWithFetchRequestBlock:fetchRequestBlock completion:completion];
    return ope;
}

#pragma mark - remove

- (BOOL)removeObjectsWithFetchRequestBlock:(YSCoreDataOperationFetchRequestBlock)fetchRequestBlock
                                     error:(NSError *__autoreleasing *)errorPtr
{
    YSCoreDataOperation *ope = [[YSCoreDataOperation alloc] initWithTemporaryContext:self.mainContext
                                                                         mainContext:self.mainContext
                                                                       writerContext:self.writerContext];
    
    return [ope removeWithFetchRequestBlock:fetchRequestBlock error:errorPtr];
}

- (BOOL)removeAllObjectsWithError:(NSError **)errorPtr
{
    YSCoreDataOperation *ope = [[YSCoreDataOperation alloc] initWithTemporaryContext:self.mainContext
                                                                         mainContext:self.mainContext
                                                                       writerContext:self.writerContext];
    
    return [ope removeAllWithManagedObjectModel:self.managedObjectModel error:errorPtr];
}

- (YSCoreDataOperation*)removeObjectsWithFetchRequestBlock:(YSCoreDataOperationFetchRequestBlock)fetchRequestBlock
                                                completion:(YSCoreDataOperationCompletion)completion
{
    YSCoreDataOperation *ope = [[YSCoreDataOperation alloc] initWithTemporaryContext:[self newTemporaryContext]
                                                                         mainContext:self.mainContext
                                                                       writerContext:self.writerContext];
    
    [ope removeWithFetchRequestBlock:fetchRequestBlock completion:completion];
    return ope;
}

#pragma mark - count

- (NSUInteger)countObjectsWithEntitiyName:(NSString*)entityName
{
    return [self countObjectsWithContext:self.mainContext entitiyName:entityName];
}

- (NSDictionary*)countAllEntitiesByName
{
    NSDictionary *allEntities = [self.managedObjectModel entitiesByName];
    NSMutableDictionary *countAllEntities = [NSMutableDictionary dictionaryWithCapacity:[allEntities count]];
    for (NSString *entityName in [allEntities allKeys]) {
        [countAllEntities setObject:@([self countObjectsWithEntitiyName:entityName]) forKey:entityName];
    }
    return countAllEntities;
}

- (NSUInteger)countObjectsWithContext:(NSManagedObjectContext*)context
                          entitiyName:(NSString*)entityName
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
        DDLogVerbose(@"Init persistentStoreCoordinator");
        NSURL *url = [NSURL fileURLWithPath:self.databaseFullPath];
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:self.storeType configuration:nil URL:url options:nil error:&error]) {
            NSAssert1(0, @"NSPersistentStoreCoordinator error: %@", error);
            DDLogError(@"NSPersistentStoreCoordinator error: %@", error);
        }
        DDLogVerbose(@"Database full path = %@", self.databaseFullPath);
    }
    return _persistentStoreCoordinator;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel == nil) {
        DDLogVerbose(@"Init managedObjectModel");
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

- (NSManagedObjectContext *)mainContext
{
    if (_mainContext == nil) {
        DDLogVerbose(@"Init mainContext");
        _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _mainContext.parentContext = self.writerContext;
    }
    return _mainContext;
}

- (NSManagedObjectContext *)writerContext
{
    if (_writerContext == nil) {
        DDLogVerbose(@"Init writerContext");
        _writerContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _writerContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    }
    return _writerContext;
}

@end
