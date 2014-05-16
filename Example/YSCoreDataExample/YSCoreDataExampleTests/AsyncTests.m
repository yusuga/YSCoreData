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
#import "Utility.h"
#import <TKRGuard/TKRGuard.h>

@interface AsyncTests : XCTestCase

@end

@implementation AsyncTests

- (void)setUp
{
    [super setUp];
    [Utility commonSettins];
    [Utility cleanUpAllDatabase];
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - cancel write

- (void)testCancelWirteWithSQLite
{
    [self cancelWriteWithCoreData:[Utility coreDataWithStoreType:NSSQLiteStoreType]];
}

- (void)testCancelWirteWithBinary
{
    [self cancelWriteWithCoreData:[Utility coreDataWithStoreType:NSBinaryStoreType]];
}

- (void)testCancelWirteWithInMemory
{
    [self cancelWriteWithCoreData:[Utility coreDataWithStoreType:NSInMemoryStoreType]];
}

- (void)cancelWriteWithCoreData:(YSCoreData*)coreData
{
    YSCoreDataOperation *ope = [coreData asyncWriteWithConfigureManagedObject:^(NSManagedObjectContext *context,
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
                                } didSaveStore:^(NSManagedObjectContext *context, NSError *error) {
                                    XCTAssertNotNil(error, @"error: %@", error);
                                    RESUME;
                                }];
    WAIT_TIMES(2);
    XCTAssertTrue(ope.isCancelled);
    XCTAssertFalse(ope.isCompleted);
}

#pragma mark - cancel fetch

- (void)testCancelFetchWithSQLite
{
    [self cancelFetchWithCoreData:[Utility coreDataWithStoreType:NSSQLiteStoreType]];
}

- (void)testCancelFetchWithBinary
{
    [self cancelFetchWithCoreData:[Utility coreDataWithStoreType:NSBinaryStoreType]];
}

- (void)testCancelFetchWithInMemory
{
    [self cancelFetchWithCoreData:[Utility coreDataWithStoreType:NSInMemoryStoreType]];
}

- (void)cancelFetchWithCoreData:(YSCoreData*)coreData
{
    YSCoreDataOperation *ope = [coreData asyncFetchWithConfigureFetchRequest:^NSFetchRequest *(NSManagedObjectContext *context,
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
    XCTAssertTrue(ope.isCancelled);
    XCTAssertFalse(ope.isCompleted);
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
    __block YSCoreDataOperation *ope;
    
    // insert 100
    [TwitterRequest requestTweetsWithCount:insertCount completion:^(NSArray *newTweets) {
        ope = [twitterStorage asyncInsertTweetsWithTweetJsons:newTweets completion:^(NSManagedObjectContext *context, NSError *error) {
            if (error) {
                XCTFail(@"%@", error);
            }
            RESUME;
        } didSaveStore:^(NSManagedObjectContext *context, NSError *error) {
            XCTAssertTrue([twitterStorage countTweetRecord] == insertCount, @"count = %@", @([twitterStorage countTweetRecord]));
            RESUME;
        }];
    }];
    WAIT_TIMES(2);
    
    XCTAssertFalse(ope.isCancelled);
    XCTAssertTrue(ope.isCompleted);
    ope = nil;
    
    // count record
    XCTAssertTrue([twitterStorage countTweetRecord] == insertCount, @"count tweet record: %@", @([twitterStorage countTweetRecord]));
    
    // fetch 10
    ope = [twitterStorage asyncFetchTweetsLimit:10 maxId:nil completion:^(NSManagedObjectContext *context, NSArray *tweets, NSError *error)
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
    
    XCTAssertFalse(ope.isCancelled);
    XCTAssertTrue(ope.isCompleted);
    ope = nil;

    // is user unique
    NSUInteger savedUserNum = [twitterStorage countUserRecord];
    NSUInteger maxUserNum = [[TwitterRequest userNames] count];
    XCTAssertTrue(savedUserNum == maxUserNum, @"savedUserNum = %@, maxUserNum = %@", @(savedUserNum), @(maxUserNum));
    
    // remove record
    ope = [twitterStorage asyncRemoveAllTweetRecordWithCompletion:^(NSManagedObjectContext *context, NSError *error) {
        if (error) {
            XCTFail(@"%@", error);
        }
        RESUME;
    } didSaveStore:^(NSManagedObjectContext *context, NSError *error) {
        XCTAssertTrue([twitterStorage countTweetRecord] == 0, @"count = %@", @([twitterStorage countTweetRecord]));
        RESUME;
    }];
    WAIT_TIMES(2);
    
    XCTAssertFalse(ope.isCancelled);
    XCTAssertTrue(ope.isCompleted);
}

@end
