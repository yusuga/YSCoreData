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
} YSCoreDataDirectoryType;

@interface YSCoreData : NSObject

- (instancetype)initWithDirectoryType:(YSCoreDataDirectoryType)directoryType
                         databasePath:(NSString *)databasePath;

@property (nonatomic, readonly) NSManagedObjectContext *mainContext;

- (YSCoreDataOperation*)asyncWriteWithConfigureManagedObject:(YSCoreDataOperationAysncWriteConfigure)configure
                                                     success:(void(^)(void))success
                                                     failure:(YSCoreDataOperationSaveFailure)failure;

- (YSCoreDataOperation*)asyncFetchWithConfigureFetchRequest:(YSCoreDataOperationAysncFetchConfigure)configure
                                    success:(YSCoreDataOperationAysncFetchSuccess)success
                                    failure:(YSCoreDataOperationFailure)failure;

- (NSUInteger)countRecordWithEntitiyName:(NSString*)entityName;
- (void)removeRecordWithEntitiyName:(NSString *)entityName
                            success:(void(^)(void))success
                            failure:(YSCoreDataOperationSaveFailure)failure;

- (BOOL)deleteDatabase;

@end
