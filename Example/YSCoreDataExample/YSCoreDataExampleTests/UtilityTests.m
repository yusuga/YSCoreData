//
//  UtilityTests.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/05/06.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TestUtility.h"
#import <YSFileManager/YSFileManager.h>

@interface UtilityTests : XCTestCase

@end

@implementation UtilityTests

- (void)setUp
{
    [super setUp];
    [TestUtility cleanUpAllDatabase];
}

- (NSString*)coreDataPath
{
    return [YSFileManager documentDirectoryWithAppendingPathComponent:kCoreDataPath];
}

- (NSString*)twitterStoragePath
{
    return [YSFileManager documentDirectoryWithAppendingPathComponent:kTwitterStoragePath];
}

- (NSString*)twitterStorageOfMainBundlePath
{
    return [[NSBundle mainBundle] pathForResource:kTwitterStoragePath ofType:nil];
}

- (void)testCleanUpAllDatabase
{
    [TestUtility cleanUpAllDatabase];
    XCTAssertFalse([YSFileManager fileExistsAtPath:[self coreDataPath]]);
    XCTAssertFalse([YSFileManager fileExistsAtPath:[self twitterStoragePath]]);
    XCTAssertTrue([YSFileManager fileExistsAtPath:[self twitterStorageOfMainBundlePath]]);
}

- (void)testCreateCoreData
{
    XCTAssertNotNil([TestUtility coreData]);
    XCTAssertTrue([YSFileManager fileExistsAtPath:[self coreDataPath]]);
}

- (void)testCreateTwitterStorage
{
    XCTAssertNotNil([TestUtility twitterStorage]);
    XCTAssertTrue([YSFileManager fileExistsAtPath:[self twitterStoragePath]]);
}

- (void)testExistsTwitterStorageOfMainBundle
{
    XCTAssertNotNil([TestUtility twitterStorageOfMainBundle]);
    XCTAssertTrue([YSFileManager fileExistsAtPath:[self twitterStorageOfMainBundlePath]]);
}


@end
