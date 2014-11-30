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

- (void)testCleanUpAllDatabase
{
    [Utility enumerateAllTwitterStorageUsingBlock:^(TwitterStorage *twitterStorage) {
        [Utility addTweetsWithTwitterStorage:twitterStorage count:100];
    }];
    
    [Utility cleanUpAllDatabase];
    
    XCTAssertFalse([YSFileManager fileExistsAtPath:[Utility coreDataDocumentPathWithStoreType:UtilityStoreTypeSQLite]]);
    XCTAssertFalse([YSFileManager fileExistsAtPath:[Utility coreDataDocumentPathWithStoreType:UtilityStoreTypeBinary]]);
    XCTAssertFalse([YSFileManager fileExistsAtPath:[Utility twitterStorageDocumentPathWithStoreType:UtilityStoreTypeSQLite]]);
    XCTAssertFalse([YSFileManager fileExistsAtPath:[Utility twitterStorageDocumentPathWithStoreType:UtilityStoreTypeBinary]]);
    
    XCTAssertTrue([YSFileManager fileExistsAtPath:[Utility twitterStorageMainBundlePath]]);
    
    for (YSCoreData *coreData in @[[Utility twitterStorageOfMainBundle],
                                   [Utility coreDataWithStoreType:UtilityStoreTypeInMemory],
                                   [Utility twitterStorageWithStoreType:UtilityStoreTypeInMemory]])
    {
        for (NSNumber *count in [[coreData countAllEntitiesByName] allValues]) {
            XCTAssertEqual(count.integerValue, 0);
        }
    }
    
    XCTAssertFalse([YSFileManager fileExistsAtPath:[TwitterStorage sharedInstance].databaseFullPath]);
}

- (void)testCreateCoreData
{
    for (NSNumber *storeTypeNum in @[@(UtilityStoreTypeSQLite), @(UtilityStoreTypeBinary)]) {
        UtilityStoreType storeType = [storeTypeNum unsignedIntegerValue];
        XCTAssertNotNil([Utility coreDataWithStoreType:storeType]);
        XCTAssertTrue([YSFileManager fileExistsAtPath:[Utility coreDataDocumentPathWithStoreType:storeType]]);
    }
}

- (void)testCreateTwitterStorage
{
    for (NSNumber *storeTypeNum in @[@(UtilityStoreTypeSQLite), @(UtilityStoreTypeBinary)]) {
        UtilityStoreType storeType = [storeTypeNum unsignedIntegerValue];
        XCTAssertNotNil([Utility twitterStorageWithStoreType:storeType]);
        XCTAssertTrue([YSFileManager fileExistsAtPath:[Utility twitterStorageDocumentPathWithStoreType:storeType]]);
    }
}

- (void)testExistsTwitterStorageOfMainBundle
{
    XCTAssertNotNil([Utility twitterStorageOfMainBundle]);
    XCTAssertTrue([YSFileManager fileExistsAtPath:[Utility twitterStorageMainBundlePath]]);
}

@end
