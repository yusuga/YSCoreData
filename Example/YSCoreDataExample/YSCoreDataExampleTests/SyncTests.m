//
//  SyncTests.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/05/06.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TwitterStorage.h"
#import "TwitterRequest.h"
#import "Utility.h"
#import <TKRGuard/TKRGuard.h>

@interface SyncTests : XCTestCase

@end

@implementation SyncTests

- (void)setUp
{
    [super setUp];
    [Utility commonSettins];
    [Utility cleanUpAllDatabase];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - all operations

- (void)testAllOperationInTwitterStorageWithSQLite
{
    [self databaseTestWithTwitterStorage:[Utility twitterStorageWithStoreType:NSSQLiteStoreType]];
}

- (void)testAllOperationInTwitterStorageWithBinary
{
    [self databaseTestWithTwitterStorage:[Utility twitterStorageWithStoreType:NSBinaryStoreType]];
}

- (void)testAllOperationInTwitterStorageWithInMemory
{
    [self databaseTestWithTwitterStorage:[Utility twitterStorageWithStoreType:NSInMemoryStoreType]];
}

- (void)testAllOperationInTwitterStorageOfMainBundle
{
    [self databaseTestWithTwitterStorage:[Utility twitterStorageOfMainBundle]];
}

- (void)databaseTestWithTwitterStorage:(TwitterStorage*)twitterStorage
{
    NSUInteger insertCount = 100;
    NSError *error = nil;
    
    // insert 100
    [TwitterRequest requestTweetsWithCount:insertCount completion:^(NSArray *newTweets) {
        NSError *error = nil;
        XCTAssertTrue([twitterStorage insertTweetsWithTweetJsons:newTweets error:nil didSaveStore:^(NSManagedObjectContext *context, NSError *error)
                         {
                             if (error) {
                                 XCTFail(@"error: %@", error);
                             }
                             RESUME;
                         }]);
        XCTAssertNil(error, @"error: %@", error);
        RESUME;
    }];
    WAIT_TIMES(2);
    
    // count record
    XCTAssertTrue([twitterStorage countTweetRecord] == insertCount, @"count tweet record: %@", @([twitterStorage countTweetRecord]));

    // fetch 10
    NSUInteger fetchNum = 10;
    error = nil;
    NSArray *tweets = [twitterStorage fetchTweetsWithLimit:fetchNum maxId:nil error:&error];
    if (error || [tweets count] != fetchNum) {
        XCTFail(@"%@", tweets);
    }
    for (Tweet *tw in tweets) {
        XCTAssertTrue([tw isKindOfClass:[Tweet class]], @"%@", NSStringFromClass([tw class]));
        XCTAssertTrue([tw.id isKindOfClass:[NSNumber class]], @"%@", NSStringFromClass([tw.id class]));
        XCTAssertTrue([tw.text isKindOfClass:[NSString class]], @"%@", NSStringFromClass([tw.text class]));
        XCTAssertTrue([tw.user_id isKindOfClass:[NSNumber class]], @"%@", NSStringFromClass([tw.id class]));
        
        User *user = tw.user;
        XCTAssertTrue([user isKindOfClass:[User class]], @"%@", NSStringFromClass([user class]));
        XCTAssertTrue([user.id isKindOfClass:[NSNumber class]], @"%@", NSStringFromClass([user class]));
        XCTAssertTrue([user.name isKindOfClass:[NSString class]], @"%@", NSStringFromClass([user class]));
        XCTAssertTrue([user.screen_name isKindOfClass:[NSString class]], @"%@", NSStringFromClass([user class]));
    }


    // is user unique
    NSUInteger savedUserNum = [twitterStorage countUserRecord];
    NSUInteger maxUserNum = [[TwitterRequest userNames] count];
    XCTAssertTrue(savedUserNum == maxUserNum, @"savedUserNum = %@, maxUserNum = %@", @(savedUserNum), @(maxUserNum));
    
    // remove all objects
    error = nil;
    XCTAssertTrue([twitterStorage removeAllObjectsWithError:&error didSaveStore:^(NSManagedObjectContext *context, NSError *error) {
        if (error) {
            XCTFail(@"%@", error);
        }
        RESUME;
    }]);
    XCTAssertNil(error, @"error: %@", error);
    WAIT;
    
    // count all entities
    NSDictionary *countAllEntities = [twitterStorage countAllEntitiesByName];
    XCTAssertTrue([countAllEntities count] > 0, @"countAllEntities count: %@", @([countAllEntities count]));
    for (NSNumber *count in [countAllEntities allValues]) {
        XCTAssertTrue(count.integerValue == 0, @"count: %@", count);
    }
}

@end
