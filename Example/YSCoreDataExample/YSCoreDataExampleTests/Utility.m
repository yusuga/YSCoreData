//
//  Utility.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/05/06.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "Utility.h"
#import <TKRGuard/TKRGuard.h>

NSString * const kCoreDataSQLitePath = @"CoreData_SQLite.db";
NSString * const kCoreDataBinaryPath = @"CoreData_Binary.db";
NSString * const kTwitterStorageSQLitePath = @"Twitter_SQLite.db";
NSString * const kTwitterStorageBinaryPath = @"Twitter_Binary.db";

NSString * const kTwitterStorageOfMainBundlePath = @"Twitter.db";

@implementation Utility

+ (YSCoreData*)coreDataWithStoreType:(NSString*)storeType
{
    return [[YSCoreData alloc] initWithDirectoryType:YSCoreDataDirectoryTypeDocument
                                        databasePath:[self coreDataPathWithStoreType:storeType]
                                           modelName:nil
                                           storeType:storeType];
}

+ (TwitterStorage*)twitterStorageWithStoreType:(NSString*)storeType
{
    return [[TwitterStorage alloc] initWithDirectoryType:YSCoreDataDirectoryTypeDocument
                                            databasePath:[self twitterStoragePathWithStoreType:storeType]
                                               modelName:nil
                                               storeType:storeType];
}

+ (TwitterStorage*)twitterStorageOfMainBundle
{
    return [[TwitterStorage alloc] initWithDirectoryType:YSCoreDataDirectoryTypeMainBundle
                                            databasePath:kTwitterStorageOfMainBundlePath
                                               modelName:nil
                                               storeType:NSSQLiteStoreType];
}

+ (NSString*)coreDataPathWithStoreType:(NSString*)storeType
{
    if ([storeType isEqualToString:NSSQLiteStoreType]) {
        return kCoreDataSQLitePath;
    } else {
        return kCoreDataBinaryPath;
    }
}

+ (NSString*)twitterStoragePathWithStoreType:(NSString*)storeType
{
    if ([storeType isEqualToString:NSSQLiteStoreType]) {
        return kCoreDataSQLitePath;
    } else {
        return kCoreDataBinaryPath;
    }
}

+ (void)cleanUpAllDatabase
{
    [[Utility coreDataWithStoreType:NSSQLiteStoreType] deleteDatabase];
    [[Utility coreDataWithStoreType:NSBinaryStoreType] deleteDatabase];
    
    [[Utility twitterStorageWithStoreType:NSSQLiteStoreType] deleteDatabase];
    [[Utility twitterStorageWithStoreType:NSBinaryStoreType] deleteDatabase];
    
    [self removeAllObjectsOfCoreData:[Utility twitterStorageOfMainBundle]];
    [self removeAllObjectsOfCoreData:[Utility coreDataWithStoreType:NSInMemoryStoreType]];
    [self removeAllObjectsOfCoreData:[Utility twitterStorageWithStoreType:NSInMemoryStoreType]];

}

+ (void)removeAllObjectsOfCoreData:(YSCoreData*)coreData
{
    NSString *key = @"remove";
    NSError *error = nil;
    [coreData removeAllObjectsWithError:&error didSaveStore:^(YSCoreDataOperation *operation, NSError *error) {
        NSAssert1(error == nil, @"error: %@", error);
        [TKRGuard resumeForKey:key];
    }];
    NSAssert1(error == nil, @"error: %@", error);
    [TKRGuard waitForKey:key];
}

+ (void)commonSettins
{
    [TKRGuard setDefaultTimeoutInterval:10.];
}

@end
