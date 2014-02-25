//
//  YSCoreDataExampleTests.m
//  YSCoreDataExampleTests
//
//  Created by Yu Sugawara on 2014/02/13.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <NSRunLoop-PerformBlock/NSRunLoop+PerformBlock.h>
#import <YSFileManager/YSFileManager.h>
#import "TwitterStorage.h"
#import "TwitterRequest.h"

static NSString * const kCoreDataPath = @"CoreData.db";
static NSString * const kTwitterStoragePath = @"TwitterStorage";
static YSCoreDataDirectoryType const kDirectoryType = YSCoreDataDirectoryTypeDocument;

@interface YSCoreDataExampleTests : XCTestCase

@end

@implementation YSCoreDataExampleTests

- (void)setUp
{
    [[self coreData] deleteDatabase];
    [[self twitterStorage] deleteDatabase];
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (YSCoreData*)coreData
{
    return [[YSCoreData alloc] initWithDirectoryType:kDirectoryType databasePath:kCoreDataPath];
}

- (TwitterStorage*)twitterStorage
{
    return [[TwitterStorage alloc] initWithDirectoryType:kDirectoryType databasePath:kTwitterStoragePath];
}

- (void)testAsyncWirteCancelError
{
    [[NSRunLoop currentRunLoop] performBlockAndWait:^(BOOL *finish) {
        [[self coreData] asyncWriteWithConfigureManagedObject:^(NSManagedObjectContext *context,
                                                                YSCoreDataOperation *operation)
        {
            [operation cancel];
        } success:^{
            XCTFail();
        } failure:^(NSManagedObjectContext *context, NSError *error) {
            XCTAssert([error.domain isEqualToString:YSCoreDataErrorDomain], @"domain = %@;", error.domain);
            XCTAssert(error.code == YSCoreDataErrorCodeCancel, @"code = %@;", @(error.code));
            *finish = YES;
        } didSaveSQLite:^{
            XCTFail();
        }];
    }];
}

- (void)testAsyncFetchCancelError
{
    [[NSRunLoop currentRunLoop] performBlockAndWait:^(BOOL *finish) {
        [[self coreData] asyncFetchWithConfigureFetchRequest:^NSFetchRequest *(NSManagedObjectContext *context,
                                                                               YSCoreDataOperation *operation)
        {
            [operation cancel];
            return [[NSFetchRequest alloc] init];
        } success:^(NSArray *fetchResults) {
            XCTFail();
        } failure:^(NSError *error) {
            XCTAssert([error.domain isEqualToString:YSCoreDataErrorDomain], @"domain = %@;", error.domain);
            XCTAssert(error.code == YSCoreDataErrorCodeCancel, @"code = %@;", @(error.code));
            *finish = YES;
        }];
    }];
}

- (void)testDatabase
{
    TwitterStorage *twitterStorage = [self twitterStorage];
    
    // Delete database file
    NSString *path = [YSFileManager documentDirectoryWithAppendingPathComponent:kTwitterStoragePath];
    XCTAssert([YSFileManager fileExistsAtPath:path]);
    [twitterStorage deleteDatabase];
    XCTAssertFalse([YSFileManager fileExistsAtPath:path]);
    
    NSUInteger insertCount = 100;
    
    // 100件 Insert
    [[NSRunLoop currentRunLoop] performBlockAndWait:^(BOOL *finish) {
        [TwitterRequest requestTweetsWithCount:insertCount completion:^(NSArray *newTweets) {
            [twitterStorage insertTweetsWithTweetJsons:newTweets success:^{
                
            } failure:^(NSManagedObjectContext *context, NSError *error) {
                XCTFail(@"%@", error);
            } didSaveSQLite:^{
                XCTAssert([twitterStorage countTweetRecord] == insertCount, @"count = %@", @([twitterStorage countTweetRecord]));
                *finish = YES;
            }];
        }];
    }];
    
    
    // 10件 Fetch
    [[NSRunLoop currentRunLoop] performBlockAndWait:^(BOOL *finish) {
        [twitterStorage fetchTweetsLimit:10 maxId:nil success:^(NSArray *tweets) {
            if ([tweets count] != 10) {
                XCTFail(@"%@", tweets);
            }
            for (Tweet *tw in tweets) {
                XCTAssert([tw isKindOfClass:[Tweet class]], @"%@", NSStringFromClass([tw class]));
                XCTAssert([tw.id isKindOfClass:[NSNumber class]], @"%@", NSStringFromClass([tw.id class]));
                XCTAssert([tw.text isKindOfClass:[NSString class]], @"%@", NSStringFromClass([tw.text class]));
                XCTAssert([tw.user_id isKindOfClass:[NSNumber class]], @"%@", NSStringFromClass([tw.id class]));
                
                User *user = tw.user;
                XCTAssert([user isKindOfClass:[User class]], @"%@", NSStringFromClass([user class]));
                XCTAssert([user.id isKindOfClass:[NSNumber class]], @"%@", NSStringFromClass([user class]));
                XCTAssert([user.name isKindOfClass:[NSString class]], @"%@", NSStringFromClass([user class]));
                XCTAssert([user.screen_name isKindOfClass:[NSString class]], @"%@", NSStringFromClass([user class]));
            }
            *finish = YES;
        } failure:^(NSError *error) {
            XCTFail(@"%@", error);
        }];
    }];
    
    // UserがUniqueか
    [[NSRunLoop currentRunLoop] performBlockAndWait:^(BOOL *finish) {
        NSUInteger savedUserNum = [twitterStorage countUserRecord];
        NSUInteger maxUserNum = [[TwitterRequest userNames] count];
        XCTAssert(savedUserNum == maxUserNum, @"savedUserNum = %@, maxUserNum = %@", @(savedUserNum), @(maxUserNum));
        *finish = YES;
    }];
    
    // Remove record
    [[NSRunLoop currentRunLoop] performBlockAndWait:^(BOOL *finish) {
        [twitterStorage removeAllTweetRecordWithSuccess:^{
            
        } failure:^(NSManagedObjectContext *context, NSError *error) {
            XCTFail(@"%@", error);
        } didSaveSQLite:^{
            XCTAssert([twitterStorage countTweetRecord] == 0, @"count = %@", @([twitterStorage countTweetRecord]));
            *finish = YES;
        }];
    }];
    
    [twitterStorage deleteDatabase];
}

@end
