//
//  YSCoreData.h
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/13.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreData;

typedef void(^YSCoreDataAysncWriteConfigure)(NSManagedObjectContext *context);

typedef NSFetchRequest*(^YSCoreDataAysncFetchConfigure)(NSManagedObjectContext *context);
typedef void(^YSCoreDataAysncFetchSuccess)(NSArray *fetchResults);

typedef void(^YSCoreDataFailure)(NSError *error);
typedef void(^YSCoreDataSaveFailure)(NSManagedObjectContext *context, NSError *error);

typedef enum {
    YSCoreDataDirectoryTypeDocument,
    YSCoreDataDirectoryTypeTemporary,
    YSCoreDataDirectoryTypeCaches,
} YSCoreDataDirectoryType;

@interface YSCoreData : NSObject

- (instancetype)initWithDirectoryType:(YSCoreDataDirectoryType)directoryType
                         databasePath:(NSString *)databasePath;

@property (nonatomic, readonly) NSManagedObjectContext *mainContext;

- (void)asyncWriteWithConfigureManagedObject:(YSCoreDataAysncWriteConfigure)configure
                                     success:(void(^)(void))success
                                     failure:(YSCoreDataSaveFailure)failure;

- (void)asyncFetchWithConfigureFetchRequest:(YSCoreDataAysncFetchConfigure)configure
                                    success:(YSCoreDataAysncFetchSuccess)success
                                    failure:(YSCoreDataFailure)failure;

- (NSUInteger)countRecordWithEntitiyName:(NSString*)entityName;
- (void)removeRecordWithEntitiyName:(NSString *)entityName
                            success:(void(^)(void))success
                            failure:(YSCoreDataSaveFailure)failure;

- (BOOL)deleteDatabase;

@end
