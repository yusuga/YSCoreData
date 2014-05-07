//
//  TestUtility.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/05/06.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "TestUtility.h"
#import <TKRGuard/TKRGuard.h>

NSString * const kCoreDataPath = @"CoreData.db";
NSString * const kTwitterStoragePath = @"Twitter.db";
static YSCoreDataDirectoryType const kDirectoryType = YSCoreDataDirectoryTypeDocument;

@implementation TestUtility

+ (YSCoreData*)coreData
{
    return [[YSCoreData alloc] initWithDirectoryType:kDirectoryType databasePath:kCoreDataPath];
}

+ (TwitterStorage*)twitterStorage
{
    return [[TwitterStorage alloc] initWithDirectoryType:kDirectoryType databasePath:kTwitterStoragePath];
}

+ (TwitterStorage*)twitterStorageOfMainBundle
{
    return [[TwitterStorage alloc] initWithDirectoryType:YSCoreDataDirectoryTypeMainBundle databasePath:kTwitterStoragePath];
}

+ (void)cleanUpAllDatabase
{
    [[TestUtility coreData] deleteDatabase];
    [[TestUtility twitterStorage] deleteDatabase];
    
    TwitterStorage *storage = [TestUtility twitterStorageOfMainBundle];
    NSString *key = @"remove";
    [storage asyncRemoveAllTweetRecordWithCompletion:^(NSManagedObjectContext *context, NSError *error) {
        if (error) {
            NSAssert1(0, @"error: %@", error);
        }
    } didSaveSQLite:^(NSManagedObjectContext *context, NSError *error) {
        NSAssert1([storage countTweetRecord] == 0, @"couunt tweet recored: %@", @([storage countTweetRecord]));
        [TKRGuard resumeForKey:key];
    }];
    [TKRGuard waitForKey:key];
}

@end
