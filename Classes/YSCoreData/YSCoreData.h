//
//  YSCoreData.h
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/13.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreData;
#import "YSCoreDataOperation.h"

typedef enum {
    YSCoreDataDirectoryTypeDocument,
    YSCoreDataDirectoryTypeTemporary,
    YSCoreDataDirectoryTypeCaches,
    YSCoreDataDirectoryTypeMainBundle,
} YSCoreDataDirectoryType;

@interface YSCoreData : NSObject

- (instancetype)initWithDirectoryType:(YSCoreDataDirectoryType)directoryType
                         databasePath:(NSString *)databasePath;

- (instancetype)initWithDirectoryType:(YSCoreDataDirectoryType)directoryType
                         databasePath:(NSString *)databasePath
                            modelName:(NSString *)modelName;

- (instancetype)initWithDirectoryType:(YSCoreDataDirectoryType)directoryType
                         databasePath:(NSString *)databasePath
                            modelName:(NSString *)modelName
                            storeType:(NSString *)storeType;

@property (nonatomic, readonly) NSManagedObjectContext *mainContext;

// sync

- (BOOL)writeWithConfigureManagedObject:(YSCoreDataOperationWriteConfigure)configure
                                  error:(NSError **)errorPtr
                           didSaveStore:(YSCoreDataOperationCompletion)didSaveSQLite;

- (NSArray*)fetchWithConfigureFetchRequest:(YSCoreDataOperationFetchRequestConfigure)configure
                                     error:(NSError **)errorPtr;

- (BOOL)removeObjectsWithConfigureFetchRequest:(YSCoreDataOperationFetchRequestConfigure)configure
                                         error:(NSError **)errorPtr
                                  didSaveStore:(YSCoreDataOperationCompletion)didSaveSQLite;

- (BOOL)removeAllObjectsWithError:(NSError **)errorPtr
                     didSaveStore:(YSCoreDataOperationCompletion)didSaveSQLite;

- (NSUInteger)countRecordWithEntitiyName:(NSString*)entityName;
- (NSDictionary*)countAllEntitiesByName;

- (BOOL)deleteDatabase;

// async

- (YSCoreDataOperation*)asyncWriteWithConfigureManagedObject:(YSCoreDataOperationWriteConfigure)configure
                                                  completion:(YSCoreDataOperationCompletion)completion
                                                didSaveStore:(YSCoreDataOperationCompletion)didSaveSQLite;

- (YSCoreDataOperation*)asyncFetchWithConfigureFetchRequest:(YSCoreDataOperationFetchRequestConfigure)configure
                                                 completion:(YSCoreDataOperationFetchCompletion)completion;

- (YSCoreDataOperation*)asyncRemoveRecordWithConfigureFetchRequest:(YSCoreDataOperationFetchRequestConfigure)configure
                                                        completion:(YSCoreDataOperationCompletion)completion
                                                      didSaveStore:(YSCoreDataOperationCompletion)didSaveSQLite;

@end