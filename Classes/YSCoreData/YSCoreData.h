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

@property (nonatomic, readonly) NSString *databaseFullPath;
@property (nonatomic, readonly) NSManagedObjectContext *mainContext;


/* Write */

- (BOOL)writeWithWriteBlock:(YSCoreDataOperationWriteBlock)writeBlock
                      error:(NSError **)errorPtr;

- (YSCoreDataOperation*)writeWithWriteBlock:(YSCoreDataOperationWriteBlock)writeBlock
                                 completion:(YSCoreDataOperationCompletion)completion;

/* Fetch */

- (NSArray*)fetchWithFetchRequestBlock:(YSCoreDataOperationFetchRequestBlock)fetchRequestBlock
                                 error:(NSError **)errorPtr;

- (YSCoreDataOperation*)fetchWithFetchRequestBlock:(YSCoreDataOperationFetchRequestBlock)fetchRequestBlock
                                        completion:(YSCoreDataOperationFetchCompletion)completion;

/* Remove */

- (BOOL)removeObjectsWithFetchRequestBlock:(YSCoreDataOperationFetchRequestBlock)fetchRequestBlock
                                     error:(NSError **)errorPtr;

- (BOOL)removeAllObjectsWithError:(NSError **)errorPtr;

- (YSCoreDataOperation*)removeObjectsWithFetchRequestBlock:(YSCoreDataOperationFetchRequestBlock)fetchRequestBlock
                                                completion:(YSCoreDataOperationCompletion)completion;

/* Count */

- (NSUInteger)countObjectsWithEntitiyName:(NSString*)entityName;
- (NSDictionary*)countAllEntitiesByName;

/* Others */

- (BOOL)deleteDatabase;

@end