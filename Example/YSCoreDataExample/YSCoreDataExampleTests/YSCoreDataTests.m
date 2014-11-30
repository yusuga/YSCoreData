//
//  YSCoreDataTests.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/11/28.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Utility.h"
#import "YSCoreData.h"
#import "NSManagedObject+YSCoreData.h"
#import "TwitterRequest.h"

@interface YSCoreDataTests : XCTestCase

@end

@implementation YSCoreDataTests

- (void)setUp
{
    [super setUp];
    
    [Utility commonSettins];
    [Utility cleanUpAllDatabase];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - State

- (void)testStateInWrite
{
    [Utility enumerateAllCoreDataUsingBlock:^(YSCoreData *coreData) {
        XCTestExpectation *expectation = [self expectationWithDescription:nil];
        
        YSCoreDataOperation *ope = [coreData writeWithWriteBlock:^(NSManagedObjectContext *context, YSCoreDataOperation *operation) {
            XCTAssertFalse([NSThread isMainThread]);
            XCTAssertNotNil(context);
            XCTAssertNotNil(operation);
            XCTAssertFalse(operation.isCancelled);
        } completion:^(YSCoreDataOperation *operation, NSError *error) {
            XCTAssertTrue([NSThread isMainThread]);
            XCTAssertNotNil(operation);
            XCTAssertFalse(operation.isCancelled);
            XCTAssertNil(error);
        }];
        
        ope.didSaveStore = ^(YSCoreDataOperation *operation, NSError *error) {
            XCTAssertTrue([NSThread isMainThread]);
            XCTAssertNotNil(operation);
            XCTAssertFalse(operation.isCancelled);
            XCTAssertNil(error);
            [expectation fulfill];
        };
        
        [self waitForExpectationsWithTimeout:10. handler:^(NSError *error) {
            XCTAssertNil(error, @"error: %@", error);
        }];
    }];
}

- (void)testStateInFetch
{
    [Utility enumerateAllCoreDataUsingBlock:^(YSCoreData *coreData) {
        XCTestExpectation *expectation = [self expectationWithDescription:nil];
        
        [coreData fetchWithFetchRequestBlock:^NSFetchRequest *(NSManagedObjectContext *context, YSCoreDataOperation *operation) {
            XCTAssertFalse([NSThread isMainThread]);
            XCTAssertNotNil(context);
            XCTAssertNotNil(operation);
            XCTAssertFalse(operation.isCancelled);
            
            return [NSFetchRequest fetchRequestWithEntityName:[Tweet ys_entityName]];
        } completion:^(YSCoreDataOperation *operation, NSArray *fetchResults, NSError *error) {
            XCTAssertTrue([NSThread isMainThread]);
            XCTAssertNotNil(operation);
            XCTAssertFalse(operation.isCancelled);
            XCTAssertNil(error);
            [expectation fulfill];
        }];
        
        [self waitForExpectationsWithTimeout:10. handler:^(NSError *error) {
            XCTAssertNil(error, @"error: %@", error);
        }];
    }];
}

- (void)testStateInRemove
{
    [Utility enumerateAllCoreDataUsingBlock:^(YSCoreData *coreData) {
        XCTestExpectation *expectation = [self expectationWithDescription:nil];
        
        YSCoreDataOperation *ope = [coreData removeObjectsWithFetchRequestBlock:^NSFetchRequest *(NSManagedObjectContext *context, YSCoreDataOperation *operation) {
            XCTAssertFalse([NSThread isMainThread]);
            XCTAssertNotNil(context);
            XCTAssertNotNil(operation);
            XCTAssertFalse(operation.isCancelled);
            
            return [NSFetchRequest fetchRequestWithEntityName:[Tweet ys_entityName]];
        } completion:^(YSCoreDataOperation *operation, NSError *error) {
            XCTAssertTrue([NSThread isMainThread]);
            XCTAssertNotNil(operation);
            XCTAssertFalse(operation.isCancelled);
            XCTAssertNil(error);
        }];
        
        ope.didSaveStore = ^(YSCoreDataOperation *operation, NSError *error) {
            XCTAssertTrue([NSThread isMainThread]);
            XCTAssertNotNil(operation);
            XCTAssertFalse(operation.isCancelled);
            XCTAssertNil(error);
            [expectation fulfill];
        };
        
        [self waitForExpectationsWithTimeout:10. handler:^(NSError *error) {
            XCTAssertNil(error, @"error: %@", error);
        }];
    }];
}

#pragma mark - Insert

- (void)testInsert
{
    [Utility enumerateAllTwitterStorageUsingBlock:^(TwitterStorage *twitterStorage) {
        NSUInteger count = 100;
        
        [Utility addTweetsWithTwitterStorage:twitterStorage count:count];
        
        XCTAssertEqual([twitterStorage countTweetObjects], count);
        XCTAssertEqual([twitterStorage countUserObjects], count);
    }];
}

- (void)testAsyncInsert
{
    [Utility enumerateAllTwitterStorageUsingBlock:^(TwitterStorage *twitterStorage) {
        NSUInteger count = 100;
        
        XCTestExpectation *expectation = [self expectationWithDescription:nil];
        
        [twitterStorage insertTweetsWithTweetJsons:[Utility tweetsWithCount:count] completion:^(YSCoreDataOperation *operation, NSError *error) {
            XCTAssertNil(error);
            
            XCTAssertEqual([twitterStorage countTweetObjects], count);
            XCTAssertEqual([twitterStorage countUserObjects], count);
            [expectation fulfill];
        }];
        
        [self waitForExpectationsWithTimeout:10. handler:^(NSError *error) {
            XCTAssertNil(error, @"error: %@", error);
        }];
    }];
}

#pragma mark - Fetch

- (void)testFetch
{
    [Utility enumerateAllTwitterStorageUsingBlock:^(TwitterStorage *twitterStorage) {
        NSUInteger count = 100;
        
        [Utility addTweetsWithTwitterStorage:twitterStorage count:count];
    
        NSArray *tweets = [Utility fetchAllTweetsWithTwitterStorage:twitterStorage];
        XCTAssertEqual([tweets count], count);
    }];
}

- (void)testAsyncFetch
{
    [Utility enumerateAllTwitterStorageUsingBlock:^(TwitterStorage *twitterStorage) {
        NSUInteger count = 100;
        
        [Utility addTweetsWithTwitterStorage:twitterStorage count:count];
        
        XCTestExpectation *expectation = [self expectationWithDescription:nil];
        
        [twitterStorage fetchTweetsLimit:0 maxId:0 completion:^(YSCoreDataOperation *operation, NSArray *fetchResults, NSError *error) {
            XCTAssertNil(error);
            XCTAssertEqual([fetchResults count], count);
            [expectation fulfill];
        }];
        
        [self waitForExpectationsWithTimeout:10. handler:^(NSError *error) {
            XCTAssertNil(error, @"error: %@", error);
        }];
    }];
}

- (void)testFetchZero
{
    [Utility enumerateAllTwitterStorageUsingBlock:^(TwitterStorage *twitterStorage) {
        XCTAssertEqual([[Utility fetchAllTweetsWithTwitterStorage:twitterStorage] count], 0);
    }];
}

- (void)testAsyncFetchZero
{
    [Utility enumerateAllTwitterStorageUsingBlock:^(TwitterStorage *twitterStorage) {
        XCTestExpectation *expectation = [self expectationWithDescription:nil];
        
        [twitterStorage fetchTweetsLimit:0 maxId:0 completion:^(YSCoreDataOperation *operation, NSArray *fetchResults, NSError *error) {
            XCTAssertNil(error);
            XCTAssertEqual([fetchResults count], 0);
            [expectation fulfill];
        }];
        
        [self waitForExpectationsWithTimeout:10. handler:^(NSError *error) {
            XCTAssertNil(error, @"error: %@", error);
        }];
    }];
}

#pragma mark - Remove

- (void)testRemove
{
    [Utility enumerateAllTwitterStorageUsingBlock:^(TwitterStorage *twitterStorage) {
        NSUInteger count = 100;
        
        [Utility addTweetsWithTwitterStorage:twitterStorage count:count];
        
        NSError *error = nil;
        XCTAssertTrue([twitterStorage removeAllTweetsWithError:&error]);
        XCTAssertNil(error);
        XCTAssertEqual([twitterStorage countTweetObjects], 0);
    }];
}

- (void)testAsyncRemove
{
    [Utility enumerateAllTwitterStorageUsingBlock:^(TwitterStorage *twitterStorage) {
        NSUInteger count = 100;
        
        [Utility addTweetsWithTwitterStorage:twitterStorage count:count];
        
        XCTestExpectation *expectation = [self expectationWithDescription:nil];
        
        [twitterStorage removeAllTweetsWithCompletion:^(YSCoreDataOperation *operation, NSError *error) {
            XCTAssertNil(error);
            XCTAssertEqual([twitterStorage countTweetObjects], 0);
            [expectation fulfill];
        }];
        
        [self waitForExpectationsWithTimeout:10. handler:^(NSError *error) {
            XCTAssertNil(error, @"error: %@", error);
        }];
    }];
}

#pragma mark - Count

- (void)testCount
{
    [Utility enumerateAllTwitterStorageUsingBlock:^(TwitterStorage *twitterStorage) {
        NSUInteger count = 1;
        [Utility addTweetsWithTwitterStorage:twitterStorage count:count];
        
        XCTAssertEqual([twitterStorage countTweetObjects], count);
        XCTAssertEqual([twitterStorage countUserObjects], count);
    }];
}

- (void)testAllCount
{
    [Utility enumerateAllTwitterStorageUsingBlock:^(TwitterStorage *twitterStorage) {
        NSArray *allKeys = @[[Tweet ys_entityName], [User ys_entityName]];
        NSUInteger count = 1;
        [Utility addTweetsWithTwitterStorage:twitterStorage count:count];
        
        NSDictionary *entitiesByName = [twitterStorage countAllEntitiesByName];
        for (NSString *key in [entitiesByName allKeys]) {
            XCTAssertTrue([allKeys containsObject:key]);
            XCTAssertEqual([[entitiesByName objectForKey:key] integerValue], count);
        }
    }];
}

@end
