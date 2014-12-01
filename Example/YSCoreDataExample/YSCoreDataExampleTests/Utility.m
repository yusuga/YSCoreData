//
//  Utility.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/05/06.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "Utility.h"
#import <TKRGuard/TKRGuard.h>
#import <YSFileManager/YSFileManager.h>
#import "TwitterRequest.h"
#import "TwitterStorage.h"

NSString * const kCoreDataSQLiteFileName = @"CoreData_SQLite.db";
NSString * const kCoreDataBinaryFileName = @"CoreData_Binary.db";
NSString * const kTwitterStorageSQLiteFileName = @"Twitter_SQLite.db";
NSString * const kTwitterStorageBinaryFileName = @"Twitter_Binary.db";

NSString * const kTwitterStorageOfMainBundlePath = @"Twitter.db";

@implementation Utility

+ (void)commonSettins
{
    [TKRGuard setDefaultTimeoutInterval:30.];
}

+ (void)cleanUpAllDatabase
{
    [[Utility coreDataWithStoreType:UtilityStoreTypeSQLite] deleteDatabase];
    [[Utility coreDataWithStoreType:UtilityStoreTypeBinary] deleteDatabase];
    
    [[Utility twitterStorageWithStoreType:UtilityStoreTypeSQLite] deleteDatabase];
    [[Utility twitterStorageWithStoreType:UtilityStoreTypeBinary] deleteDatabase];
    
    [self removeAllObjectsOfCoreData:[Utility twitterStorageOfMainBundle]];
    [self removeAllObjectsOfCoreData:[Utility coreDataWithStoreType:UtilityStoreTypeInMemory]];
    [self removeAllObjectsOfCoreData:[Utility twitterStorageWithStoreType:UtilityStoreTypeInMemory]];
    
    [[TwitterStorage sharedInstance] deleteDatabase];
}

+ (YSCoreData*)coreDataWithStoreType:(UtilityStoreType)storeType
{
    return [[YSCoreData alloc] initWithDirectoryType:YSCoreDataDirectoryTypeDocument
                                        databasePath:[self coreDataFileNameWithStoreType:storeType]
                                           modelName:nil
                                           storeType:[self coreDataStoreTypeWithStoreType:storeType]];
}

+ (TwitterStorage*)twitterStorageWithStoreType:(UtilityStoreType)storeType
{
    return [[TwitterStorage alloc] initWithDirectoryType:YSCoreDataDirectoryTypeDocument
                                            databasePath:[self twitterStorageFileNameWithStoreType:storeType]
                                               modelName:nil
                                               storeType:[self coreDataStoreTypeWithStoreType:storeType]];
}

+ (TwitterStorage*)twitterStorageOfMainBundle
{
    return [[TwitterStorage alloc] initWithDirectoryType:YSCoreDataDirectoryTypeMainBundle
                                            databasePath:kTwitterStorageOfMainBundlePath
                                               modelName:nil
                                               storeType:NSSQLiteStoreType];
}

+ (NSArray *)allStoreType
{
    NSMutableArray *types = [NSMutableArray arrayWithCapacity:UtilityStoreType_MAX];
    for (NSUInteger type = 0; type < UtilityStoreType_MAX; type++) {
        [types addObject:@(type)];
    }
    return [NSArray arrayWithArray:types];
}

+ (void)enumerateAllCoreDataUsingBlock:(void(^)(YSCoreData *coreData))block
{
    for (NSUInteger type = 0; type < UtilityStoreType_MAX; type++) {
        block([Utility coreDataWithStoreType:type]);
    }
}

+ (void)enumerateAllTwitterStorageUsingBlock:(void(^)(TwitterStorage *twitterStorage))block
{
    for (NSUInteger type = 0; type < UtilityStoreType_MAX; type++) {
        block([Utility twitterStorageWithStoreType:type]);
    }
    block([Utility twitterStorageOfMainBundle]);
}

+ (void)enumerateStoreTypeUsingBlock:(void(^)(UtilityStoreType type))block
{
    for (NSUInteger type = 0; type < UtilityStoreType_MAX; type++) {
        block(type);
    }
}

+ (NSString*)coreDataFileNameWithStoreType:(UtilityStoreType)storeType
{
    switch (storeType) {
        case UtilityStoreTypeSQLite:
            return kCoreDataSQLiteFileName;
        case UtilityStoreTypeBinary:
            return kCoreDataBinaryFileName;
        case UtilityStoreTypeInMemory:
            return nil;
        default:
            NSAssert1(false, @"storeType = %zd", storeType);
            abort();
            break;
    }
}

+ (NSString*)twitterStorageFileNameWithStoreType:(UtilityStoreType)storeType
{
    switch (storeType) {
        case UtilityStoreTypeSQLite:
            return kTwitterStorageSQLiteFileName;
        case UtilityStoreTypeBinary:
            return kTwitterStorageBinaryFileName;
        case UtilityStoreTypeInMemory:
            return nil;
        default:
            NSAssert1(false, @"storeType = %zd", storeType);
            abort();
            break;
    }
}

+ (NSString*)coreDataStoreTypeWithStoreType:(UtilityStoreType)storeType
{
    switch (storeType) {
        case UtilityStoreTypeSQLite:
            return NSSQLiteStoreType;
        case UtilityStoreTypeBinary:
            return NSBinaryStoreType;
        case UtilityStoreTypeInMemory:
            return NSInMemoryStoreType;
        default:
            NSAssert1(false, @"storeType = %zd", storeType);
            abort();
            break;
    }
}

+ (NSString*)coreDataDocumentPathWithStoreType:(UtilityStoreType)storeType
{
    return [YSFileManager documentDirectoryWithAppendingPathComponent:[Utility coreDataFileNameWithStoreType:storeType]];
}

+ (NSString*)twitterStorageDocumentPathWithStoreType:(UtilityStoreType)storeType
{
    return [YSFileManager documentDirectoryWithAppendingPathComponent:[Utility twitterStorageFileNameWithStoreType:storeType]];
}

+ (NSString*)twitterStorageMainBundlePath
{
    return [[NSBundle mainBundle] pathForResource:kTwitterStorageOfMainBundlePath ofType:nil];
}

+ (void)removeAllObjectsOfCoreData:(YSCoreData*)coreData
{
    NSError *error = nil;
    [coreData removeAllWithError:&error];
    NSAssert1(error == nil, @"error: %@", error);
}

+ (NSArray*)tweetsWithCount:(int64_t)count
{
    NSMutableArray *objs = [NSMutableArray arrayWithCapacity:count];
    for (int64_t i = 0; i < count; i++) {
        [objs addObject:[TwitterRequest tweetWithTweetID:i
                                                  userID:i]];
    }
    return [NSArray arrayWithArray:objs];
}

+ (void)addTweetsWithTwitterStorage:(TwitterStorage*)storage
                              count:(int64_t)count
{
    [self addTweetWithTwitterStorage:storage tweetJsonObjects:[self tweetsWithCount:count]];
}

+ (void)addTweetWithTwitterStorage:(TwitterStorage*)storage
                  tweetJsonObjects:(NSArray*)tweetJsonObjects
{
    NSError *error = nil;
    [storage insertTweetsWithTweetJsons:tweetJsonObjects error:&error];
    NSAssert1(error == nil, @"error: %@", error);
}

+ (NSArray*)fetchAllTweetsWithTwitterStorage:(TwitterStorage*)twitterStorage
{
    NSError *error = nil;
    NSArray *tweets = [twitterStorage fetchTweetsWithLimit:0
                                                     maxId:0
                                                     error:&error];
    NSAssert1(error == nil, @"error: %@", error);
    return tweets;
}

@end
