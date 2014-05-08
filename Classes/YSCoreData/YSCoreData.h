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

- (BOOL)writeWithConfigureManagedObject:(YSCoreDataOperationAsyncWriteConfigure)configure
                                  error:(NSError **)error
                          didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite;

- (NSArray*)fetchWithConfigureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                                     error:(NSError **)error;

- (BOOL)removeRecordWithConfigureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                                        error:(NSError **)error
                                didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite;

- (NSUInteger)countRecordWithEntitiyName:(NSString*)entityName;
- (NSDictionary*)countAllEntitiesByName;

// async

- (YSCoreDataOperation*)asyncWriteWithConfigureManagedObject:(YSCoreDataOperationAsyncWriteConfigure)configure
                                                  completion:(YSCoreDataOperationCompletion)completion
                                               didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite;

- (YSCoreDataOperation*)asyncFetchWithConfigureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                                                 completion:(YSCoreDataOperationFetchCompletion)completion;

- (YSCoreDataOperation*)asyncRemoveRecordWithConfigureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                                                        completion:(YSCoreDataOperationCompletion)completion
                                                     didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite;

- (BOOL)deleteDatabase;

@end
