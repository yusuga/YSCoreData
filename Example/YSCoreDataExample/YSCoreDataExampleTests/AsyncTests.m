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
    YSCoreDataOperation *ope = [coreData asyncWriteWithConfigureManagedObject:^(NSManagedObjectContext *context, YSCoreDataOperation *operation) {
        XCTAssertFalse([NSThread isMainThread]);
        
        XCTAssertNotNil(context);
        
        XCTAssertNotNil(operation);
        XCTAssertTrue(operation.isCancelled);
        XCTAssertFalse(operation.isCompleted);
        dispatch_async(dispatch_get_main_queue(), ^{
            RESUME;
        });
    } completion:^(YSCoreDataOperation *operation, NSError *error) {
        XCTAssertTrue([NSThread isMainThread]);
        
        XCTAssertNotNil(operation);
        XCTAssertTrue(operation.isCancelled);
        XCTAssertFalse(operation.isCompleted);

        XCTAssertNotNil(error);
        XCTAssertTrue([error.domain isEqualToString:YSCoreDataErrorDomain], @"domain = %@;", error.domain);
        XCTAssertEqual(error.code, YSCoreDataErrorCodeCancel, @"code: %zd", error.code);
        RESUME;
    } didSaveStore:^(YSCoreDataOperation *operation, NSError *error) {
        XCTAssertTrue([NSThread isMainThread]);
        
        XCTAssertNotNil(operation);
        XCTAssertTrue(operation.isCancelled);
        XCTAssertFalse(operation.isCompleted);
        
        XCTAssertNotNil(error);
        XCTAssertTrue([error.domain isEqualToString:YSCoreDataErrorDomain], @"domain = %@;", error.domain);
        XCTAssertEqual(error.code, YSCoreDataErrorCodeCancel, @"code: %zd", error.code);
        RESUME;
    }];
    [ope cancel];
    WAIT_TIMES(3);
    
    XCTAssertNotNil(ope);
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
    YSCoreDataOperation *ope = [coreData asyncFetchWithConfigureFetchRequest:^NSFetchRequest *(NSManagedObjectContext *context, YSCoreDataOperation *operation) {
        XCTAssertFalse([NSThread isMainThread]);
        
        XCTAssertNotNil(context);
        
        XCTAssertNotNil(operation);
        XCTAssertTrue(operation.isCancelled);
        XCTAssertFalse(operation.isCompleted);
        dispatch_async(dispatch_get_main_queue(), ^{
            RESUME;
        });
        return [[NSFetchRequest alloc] init];
    } completion:^(YSCoreDataOperation *operation, NSArray *fetchResults, NSError *error) {
        XCTAssertTrue([NSThread isMainThread]);
        
        XCTAssertNotNil(operation);
        XCTAssertTrue(operation.isCancelled);
        XCTAssertFalse(operation.isCompleted);
        
        XCTAssertFalse([fetchResults count]);
        
        XCTAssertNotNil(error);
        XCTAssertTrue([error.domain isEqualToString:YSCoreDataErrorDomain], @"domain = %@;", error.domain);
        XCTAssertEqual(error.code, YSCoreDataErrorCodeCancel, @"code: %zd", error.code);
        RESUME;
    }];
    [ope cancel];
    WAIT_TIMES(2);
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
    
    /* insert */
    [TwitterRequest requestTweetsWithCount:insertCount completion:^(NSArray *newTweets) {
        ope = [twitterStorage asyncInsertTweetsWithTweetJsons:newTweets completion:^(YSCoreDataOperation *operation, NSError *error) {
            XCTAssertTrue([NSThread isMainThread]);
            
            XCTAssertNotNil(operation);
            XCTAssertFalse(operation.isCancelled);
            XCTAssertTrue(operation.isCompleted);
            
            XCTAssertNil(error, @"error: %@", error);
            RESUME;
        } didSaveStore:^(YSCoreDataOperation *operation, NSError *error) {
            XCTAssertTrue([NSThread isMainThread]);
            
            XCTAssertNotNil(operation);
            XCTAssertFalse(operation.isCancelled);
            XCTAssertTrue(operation.isCompleted);
            
            XCTAssertNil(error, @"error: %@", error);
            RESUME;
        }];
    }];
    WAIT_TIMES(2);
    
    XCTAssertFalse(ope.isCancelled);
    XCTAssertTrue(ope.isCompleted);
    ope = nil;
    
    /* count record */
    XCTAssertTrue([twitterStorage countTweetRecord] == insertCount, @"count tweet record: %@", @([twitterStorage countTweetRecord]));
    
    /* fetch */
    NSUInteger fetchCount = 90;
    ope = [twitterStorage asyncFetchTweetsLimit:fetchCount maxId:nil completion:^(YSCoreDataOperation *operation, NSArray *fetchResults, NSError *error) {
        XCTAssertTrue([NSThread isMainThread]);
        
        XCTAssertNotNil(operation);
        XCTAssertFalse(operation.isCancelled);
        XCTAssertTrue(operation.isCompleted);
        
        XCTAssertNil(error, @"error: %@", error);
        
        XCTAssertEqual([fetchResults count], fetchCount, @"fetchResults count: %zd", [fetchResults count]);
        for (Tweet *tw in fetchResults) {
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

    /* is user unique */
    NSUInteger savedUserNum = [twitterStorage countUserRecord];
    NSUInteger maxUserNum = [[TwitterRequest userNames] count];
    XCTAssertTrue(savedUserNum == maxUserNum, @"savedUserNum = %@, maxUserNum = %@", @(savedUserNum), @(maxUserNum));
    
    /* remove record */
    ope = [twitterStorage asyncRemoveAllTweetRecordWithCompletion:^(YSCoreDataOperation *operation, NSError *error) {
        XCTAssertTrue([NSThread isMainThread]);
        
        XCTAssertNotNil(operation);
        XCTAssertFalse(operation.isCancelled);
        XCTAssertTrue(operation.isCompleted);
        
        XCTAssertNil(error, @"error: %@", error);
        RESUME;
    } didSaveStore:^(YSCoreDataOperation *operation, NSError *error) {
        XCTAssertTrue([NSThread isMainThread]);
        
        XCTAssertNotNil(operation);
        XCTAssertFalse(operation.isCancelled);
        XCTAssertTrue(operation.isCompleted);
        
        XCTAssertNil(error, @"error: %@", error);
        RESUME;
    }];
    WAIT_TIMES(2);
    
    XCTAssertFalse(ope.isCancelled);
    XCTAssertTrue(ope.isCompleted);
    XCTAssertEqual([twitterStorage countTweetRecord], 0, @"count: %zd", [twitterStorage countTweetRecord]);
}

#pragma mark - unique insert

- (void)testUniqueInsertInTwitterStorageWithSQLite
{
    [self uniqueInsertWithTwitterStorage:[Utility twitterStorageWithStoreType:NSSQLiteStoreType]];
}

- (void)testUniqueInsertInTwitterStorageWithBinary
{
    [self uniqueInsertWithTwitterStorage:[Utility twitterStorageWithStoreType:NSBinaryStoreType]];
}

- (void)testUniqueInsertInTwitterStorageWithInMemory
{
    [self uniqueInsertWithTwitterStorage:[Utility twitterStorageWithStoreType:NSInMemoryStoreType]];
}

- (void)testUniqueInsertInTwitterStorageOfMainBundle
{
    [self uniqueInsertWithTwitterStorage:[Utility twitterStorageOfMainBundle]];
}

- (void)uniqueInsertWithTwitterStorage:(TwitterStorage*)twitterStorage
{
    NSUInteger insertCount = 10;
    NSUInteger repeat = 3;
    NSMutableArray *operations = @[].mutableCopy;
    
    XCTAssertTrue(repeat > 1, @"repeat: %zd", repeat);
    
    /* insert */
    [TwitterRequest requestTweetsWithCount:insertCount completion:^(NSArray *newTweets) {
        for (NSUInteger i = 0; i < repeat; i++) {
            YSCoreDataOperation *ope = [twitterStorage asyncInsertTweetsWithTweetJsons:newTweets completion:^(YSCoreDataOperation *operation, NSError *error) {
                XCTAssertTrue([NSThread isMainThread]);
                
                XCTAssertNotNil(operation);
                XCTAssertFalse(operation.isCancelled);
                XCTAssertTrue(operation.isCompleted);
                
                XCTAssertNil(error, @"error: %@", error);
                RESUME;
            } didSaveStore:^(YSCoreDataOperation *operation, NSError *error) {
                XCTAssertTrue([NSThread isMainThread]);
                
                XCTAssertNotNil(operation);
                XCTAssertFalse(operation.isCancelled);
                XCTAssertTrue(operation.isCompleted);
                
                XCTAssertNil(error, @"error: %@", error);
                RESUME;
            }];
            [operations addObject:ope];
        }
    }];
    WAIT_TIMES(2*repeat);
    
    XCTAssertEqual([operations count], repeat, @"operations count: %zd", [operations count]);
    for (YSCoreDataOperation *ope in operations) {
        XCTAssertFalse(ope.isCancelled);
        XCTAssertTrue(ope.isCompleted);
    }
    
    /* count record */
    XCTAssertTrue([twitterStorage countTweetRecord] == insertCount, @"count tweet record: %@", @([twitterStorage countTweetRecord]));
}

#pragma mark - timeout

- (void)testWriteTimeoutInTwitterStorageWithSQLite
{
    [self writeTimeoutWithTwitterStorage:[Utility twitterStorageWithStoreType:NSSQLiteStoreType]];
}

- (void)testWriteTimeoutInTwitterStorageWithBinary
{
    [self writeTimeoutWithTwitterStorage:[Utility twitterStorageWithStoreType:NSBinaryStoreType]];
}

- (void)testWriteTimeoutInTwitterStorageWithInMemory
{
    [self writeTimeoutWithTwitterStorage:[Utility twitterStorageWithStoreType:NSInMemoryStoreType]];
}

- (void)testWriteTimeoutInTwitterStorageOfMainBundle
{
    [self writeTimeoutWithTwitterStorage:[Utility twitterStorageOfMainBundle]];
}

- (void)writeTimeoutWithTwitterStorage:(TwitterStorage*)twitterStorage
{
    int64_t timeout = 3;
    [[twitterStorage class] setCommonOperationTimeoutPerSec:timeout];
    
    NSUInteger insertCount = 10;
    NSUInteger repeat = 2;
    NSMutableArray *operations = @[].mutableCopy;
    
    XCTAssertTrue(repeat > 1, @"repeat: %zd", repeat);
    
    /* insert */
    [TwitterRequest requestTweetsWithCount:insertCount completion:^(NSArray *newTweets) {
        for (NSUInteger i = 0; i < repeat; i++) {
            YSCoreDataOperation *ope = [twitterStorage asyncWriteWithConfigureManagedObject:^(NSManagedObjectContext *context, YSCoreDataOperation *operation) {
                [NSThread sleepForTimeInterval:timeout];
            } completion:^(YSCoreDataOperation *operation, NSError *error) {
                if (i != 0) {
                    XCTAssertTrue([NSThread isMainThread]);
                    
                    XCTAssertNotNil(operation);
                    XCTAssertFalse(operation.isCancelled);
                    XCTAssertFalse(operation.isCompleted);
                    
                    XCTAssertNotNil(error);
                    XCTAssertTrue([error.domain isEqualToString:YSCoreDataErrorDomain], @"domain: %@", error.domain);
                    XCTAssertEqual(error.code, YSCoreDataErrorCodeTimeout, @"code: %zd", error.code);
                }
                RESUME;
            } didSaveStore:^(YSCoreDataOperation *operation, NSError *error) {
                if (i != 0) {
                    XCTAssertTrue([NSThread isMainThread]);
                    
                    XCTAssertNotNil(operation);
                    XCTAssertFalse(operation.isCancelled);
                    XCTAssertFalse(operation.isCompleted);
                    
                    XCTAssertNotNil(error);
                    XCTAssertTrue([error.domain isEqualToString:YSCoreDataErrorDomain], @"domain: %@", error.domain);
                    XCTAssertEqual(error.code, YSCoreDataErrorCodeTimeout, @"code: %zd", error.code);
                }
                RESUME;
            }];
            [operations addObject:ope];
        }
    }];
    WAIT_TIMES(2*repeat);
    
    XCTAssertEqual([operations count], repeat, @"operations count: %zd", [operations count]);
}

@end
