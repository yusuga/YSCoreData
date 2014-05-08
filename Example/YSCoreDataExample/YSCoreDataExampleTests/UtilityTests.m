//
//  UtilityTests.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/05/06.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Utility.h"
#import <YSFileManager/YSFileManager.h>

@interface UtilityTests : XCTestCase

@end

@implementation UtilityTests

- (void)setUp
{
    [super setUp];
    [Utility commonSettins];
    [Utility cleanUpAllDatabase];
}

- (NSString*)coreDataPathWithStoreType:(NSString*)storeType
{
    return [YSFileManager documentDirectoryWithAppendingPathComponent:[Utility coreDataPathWithStoreType:storeType]];
}

- (NSString*)twitterStoragePathWithStoreType:(NSString*)storeType
{
    return [YSFileManager documentDirectoryWithAppendingPathComponent:[Utility twitterStoragePathWithStoreType:storeType]];
}

- (NSString*)twitterStorageOfMainBundlePath
{
    return [[NSBundle mainBundle] pathForResource:kTwitterStorageOfMainBundlePath ofType:nil];
}

- (void)testCleanUpAllDatabase
{
    [Utility cleanUpAllDatabase];
    XCTAssertFalse([YSFileManager fileExistsAtPath:[self coreDataPathWithStoreType:NSSQLiteStoreType]]);
    XCTAssertFalse([YSFileManager fileExistsAtPath:[self coreDataPathWithStoreType:NSBinaryStoreType]]);
    XCTAssertFalse([YSFileManager fileExistsAtPath:[self twitterStoragePathWithStoreType:NSSQLiteStoreType]]);
    XCTAssertFalse([YSFileManager fileExistsAtPath:[self twitterStoragePathWithStoreType:NSBinaryStoreType]]);
    
    XCTAssertTrue([YSFileManager fileExistsAtPath:[self twitterStorageOfMainBundlePath]]);
    
    for (YSCoreData *coreData in @[[Utility twitterStorageOfMainBundle],
                                   [Utility coreDataWithStoreType:NSInMemoryStoreType],
                                   [Utility twitterStorageWithStoreType:NSInMemoryStoreType]])
    {
        for (NSNumber *count in [[coreData countAllEntitiesByName] allValues]) {
            XCTAssertTrue(count.integerValue == 0, @"count: %@", count);
        }
    }
}

- (void)testCreateCoreData
{
    for (NSString *storeType in @[NSSQLiteStoreType, NSBinaryStoreType]) {
        XCTAssertNotNil([Utility coreDataWithStoreType:storeType]);
        XCTAssertTrue([YSFileManager fileExistsAtPath:[self coreDataPathWithStoreType:storeType]]);
    }
}

- (void)testCreateTwitterStorage
{
    for (NSString *storeType in @[NSSQLiteStoreType, NSBinaryStoreType]) {
        XCTAssertNotNil([Utility twitterStorageWithStoreType:storeType]);
        XCTAssertTrue([YSFileManager fileExistsAtPath:[self twitterStoragePathWithStoreType:storeType]]);
    }
}

- (void)testExistsTwitterStorageOfMainBundle
{
    XCTAssertNotNil([Utility twitterStorageOfMainBundle]);
    XCTAssertTrue([YSFileManager fileExistsAtPath:[self twitterStorageOfMainBundlePath]]);
}

@end
