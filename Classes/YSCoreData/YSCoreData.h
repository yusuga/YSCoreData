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
                             modelName:(NSString*)modelName;

@property (nonatomic, readonly) NSManagedObjectContext *mainContext;

- (YSCoreDataOperation*)asyncWriteWithConfigureManagedObject:(YSCoreDataOperationAsyncWriteConfigure)configure
                                                     success:(void(^)(void))success
                                                     failure:(YSCoreDataOperationSaveFailure)failure
                                               didSaveSQLite:(void(^)(void))didSaveSQLite;

- (YSCoreDataOperation*)asyncFetchWithConfigureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                                    success:(YSCoreDataOperationFetchSuccess)success
                                    failure:(YSCoreDataOperationFailure)failure;

- (NSUInteger)countRecordWithEntitiyName:(NSString*)entityName;

- (YSCoreDataOperation*)asyncRemoveRecordWithConfigureFetchRequest:(YSCoreDataOperationAsyncFetchRequestConfigure)configure
                                                           success:(void(^)(void))success
                                                           failure:(YSCoreDataOperationSaveFailure)failure
                                                     didSaveSQLite:(void(^)(void))didSaveSQLite;

- (BOOL)deleteDatabase;

@end
