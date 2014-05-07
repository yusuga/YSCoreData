//
//  AsyncTests.m
//  AsyncTests
//
//  Created by Yu Sugawara on 2014/02/13.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <YSFileManager/YSFileManager.h>
#import "TwitterStorage.h"
#import "TwitterRequest.h"
#import "TestUtility.h"
#import <TKRGuard/TKRGuard.h>

@interface AsyncTests : XCTestCase

@end

@implementation AsyncTests

- (void)setUp
{
    [super setUp];
    [TestUtility cleanUpAllDatabase];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testCancelWirte
{
    [[TestUtility coreData] asyncWriteWithConfigureManagedObject:^(NSManagedObjectContext *context,
                                                                   YSCoreDataOperation *operation)
     {
         [operation cancel];
     } completion:^(NSManagedObjectContext *context, NSError *error) {
         if (error == nil) {
             XCTFail();
         }
         XCTAssertTrue([error.domain isEqualToString:YSCoreDataErrorDomain], @"domain = %@;", error.domain);
         XCTAssertTrue(error.code == YSCoreDataErrorCodeCancel, @"code = %@;", @(error.code));
         RESUME;
     } didSaveSQLite:^(NSManagedObjectContext *context, NSError *error) {
         XCTFail();
     }];
    WAIT;
}

- (void)testCancelFetch
{
    [[TestUtility coreData] asyncFetchWithConfigureFetchRequest:^NSFetchRequest *(NSManagedObjectContext *context,
                                                                                  YSCoreDataOperation *operation)
     {
         [operation cancel];
         return [[NSFetchRequest alloc] init];
     } completion:^(NSManagedObjectContext *context, NSArray *fetchResults, NSError *error) {
         if (error == nil) {
             XCTFail();
         }
         XCTAssertTrue([error.domain isEqualToString:YSCoreDataErrorDomain], @"domain = %@;", error.domain);
         XCTAssertTrue(error.code == YSCoreDataErrorCodeCancel, @"code = %@;", @(error.code));
         RESUME;
     }];
    WAIT;
}


- (void)testAllOperationInTwitterStorage
{
    [self databaseTestWithTwitterStorage:[TestUtility twitterStorage]];
}

- (void)testAllOperationInTwitterStorageOfMainBundle
{
    [self databaseTestWithTwitterStorage:[TestUtility twitterStorageOfMainBundle]];
}

- (void)databaseTestWithTwitterStorage:(TwitterStorage*)twitterStorage
{
    NSUInteger insertCount = 100;
    
    // insert 100
    [TwitterRequest requestTweetsWithCount:insertCount completion:^(NSArray *newTweets) {
        [twitterStorage asyncInsertTweetsWithTweetJsons:newTweets completion:^(NSManagedObjectContext *context, NSError *error) {
            if (error) {
                XCTFail(@"%@", error);
            }
            RESUME;
        } didSaveSQLite:^(NSManagedObjectContext *context, NSError *error) {
            XCTAssertTrue([twitterStorage countTweetRecord] == insertCount, @"count = %@", @([twitterStorage countTweetRecord]));
            RESUME;
        }];
    }];
    WAIT_TIMES(2);

    // count record
    XCTAssertTrue([twitterStorage countTweetRecord] == insertCount, @"count tweet record: %@", @([twitterStorage countTweetRecord]));
    
    // fetch 10
    [twitterStorage asyncFetchTweetsLimit:10 maxId:nil completion:^(NSManagedObjectContext *context, NSArray *tweets, NSError *error)
     {
         if (error || [tweets count] != 10) {
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
         RESUME;
     }];
    WAIT;

    // is user unique
    NSUInteger savedUserNum = [twitterStorage countUserRecord];
    NSUInteger maxUserNum = [[TwitterRequest userNames] count];
    XCTAssertTrue(savedUserNum == maxUserNum, @"savedUserNum = %@, maxUserNum = %@", @(savedUserNum), @(maxUserNum));
    
    // remove record
    [twitterStorage asyncRemoveAllTweetRecordWithCompletion:^(NSManagedObjectContext *context, NSError *error) {
        if (error) {
            XCTFail(@"%@", error);
        }
        RESUME;
    } didSaveSQLite:^(NSManagedObjectContext *context, NSError *error) {
        XCTAssertTrue([twitterStorage countTweetRecord] == 0, @"count = %@", @([twitterStorage countTweetRecord]));
        RESUME;
    }];
    WAIT_TIMES(2);
}

@end
