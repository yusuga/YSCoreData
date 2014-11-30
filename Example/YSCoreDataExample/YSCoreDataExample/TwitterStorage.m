//
//  TwitterStorage.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/13.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "TwitterStorage.h"

@implementation TwitterStorage

+ (instancetype)sharedInstance
{
    static id s_sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_sharedInstance =  [[self alloc] initWithDirectoryType:YSCoreDataDirectoryTypeDocument
                                                   databasePath:@"Twitter.db"
                                                      modelName:@"Twitter"];
    });
    return s_sharedInstance;
}

#pragma mark - insert

- (BOOL)insertTweetsWithTweetJsons:(NSArray*)tweetJsons
                             error:(NSError**)errorPtr
{
    return [self writeWithWriteBlock:^(NSManagedObjectContext *context, YSCoreDataOperation *operation) {
        [self insertTweetsWithContext:context operation:operation tweetJsons:tweetJsons];
    } error:errorPtr];
}

- (YSCoreDataOperation*)insertTweetsWithTweetJsons:(NSArray*)tweetJsons
                                        completion:(YSCoreDataOperationCompletion)completion
{
    if (![tweetJsons isKindOfClass:[NSArray class]]) {
        NSAssert1(0, @"%s; tweetJsons is not NSArray class;", __func__);
        NSLog(@"Error: %s; tweetJsons != NSArray class; tweetJsons class = %@;", __func__, NSStringFromClass([tweetJsons class]));
        return nil;
    }
    
    return [self writeWithWriteBlock:^(NSManagedObjectContext *context,
                                                        YSCoreDataOperation *operation)
            {
                [self insertTweetsWithContext:context operation:operation tweetJsons:tweetJsons];
            } completion:completion];
}

- (void)insertTweetsWithContext:(NSManagedObjectContext*)context
                      operation:(YSCoreDataOperation*)operation
                     tweetJsons:(NSArray*)tweetJsons
{
    NSLog(@"Start: Insert %@", @([tweetJsons count]));
    for (NSDictionary *tweetJson in tweetJsons) {
        if (operation.isCancelled) {
            return;
        }
        
        int64_t tweetID = [[tweetJson objectForKey:@"id"] longLongValue];
        
        // 同一IDのTweetがあるか
        NSFetchRequest *tweetsReq = [[NSFetchRequest alloc] init];
        tweetsReq.predicate = [NSPredicate predicateWithFormat:@"id = %lld", tweetID];
        tweetsReq.entity = [NSEntityDescription entityForName:@"Tweet" inManagedObjectContext:context];
        NSError *error = nil;
        Tweet *tweet = [[context executeFetchRequest:tweetsReq error:&error] firstObject];
        if (tweet) {
            // 重複したTweetは保存しない
            NSLog(@"Saved tweet %lld (%p)", tweetID, context);
            continue;
        }
        
        // Tweetを作成
        NSDictionary *userJson = [tweetJson objectForKey:@"user"];
        tweet = (id)[NSEntityDescription insertNewObjectForEntityForName:@"Tweet"
                                                  inManagedObjectContext:context];
        tweet.id = tweetID;
        tweet.text = [tweetJson objectForKey:@"text"];
        
        int64_t userID = [[userJson objectForKey:@"id"] longLongValue];
        
        // 同一IDのUserがあるか
        NSFetchRequest *req = [[NSFetchRequest alloc] init];
        req.predicate = [NSPredicate predicateWithFormat:@"id = %lld", userID];
        req.entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:context];
        
        error = nil;
        User *user = [[context executeFetchRequest:req error:&error] firstObject];
        
        // 同一IDのUser(保存してたUser)があればUpdate。なければ新規のUesrをInsert
        if (user) {
            NSLog(@"User update %lld (%p)", userID, context);
        } else {
            NSLog(@"User insert %lld (%p)", userID, context);
            // 新しいUserを作成
            user = (id)[NSEntityDescription insertNewObjectForEntityForName:@"User"
                                                     inManagedObjectContext:tweet.managedObjectContext];
            user.id = userID;
            user.name = [userJson objectForKey:@"name"];
            user.screen_name = [userJson objectForKey:@"screen_name"];
        }
        
        tweet.user = user;
    }
}

#pragma mark - fetch

- (NSArray*)fetchTweetsWithLimit:(NSUInteger)limit
                           maxId:(int64_t)maxId
                           error:(NSError**)errorPtr
{
    return [self fetchWithFetchRequestBlock:^NSFetchRequest *(NSManagedObjectContext *context, YSCoreDataOperation *operation) {
        return [self fetchTweetsRequestWithContext:context Limit:limit maxId:maxId];
    } error:errorPtr];
}

- (YSCoreDataOperation*)fetchTweetsLimit:(NSUInteger)limit
                                   maxId:(int64_t)maxId
                              completion:(YSCoreDataOperationFetchCompletion)completion
{
    return [self fetchWithFetchRequestBlock:^NSFetchRequest *(NSManagedObjectContext *context,
                                                                       YSCoreDataOperation *operation)
            {
                return [self fetchTweetsRequestWithContext:context Limit:limit maxId:maxId];
            } completion:completion];
}

- (NSFetchRequest*)fetchTweetsRequestWithContext:(NSManagedObjectContext*)context
                                           Limit:(NSUInteger)limit
                                           maxId:(int64_t)maxId
{
    // 現在表示しているツイート(maxId)より新しいツイートを取得するリクエストを作成
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    if (maxId > 0) {
        request.predicate = [NSPredicate predicateWithFormat:@"id > %lld", maxId];
    }
    if (limit > 0) {
        request.fetchLimit = limit;
    }
    NSEntityDescription *tweets = [NSEntityDescription entityForName:@"Tweet" inManagedObjectContext:context];
    [request setEntity:tweets];
    
    // 降順にソートする指定
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"id" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];
    
    return request;
}

#pragma mark - remove

- (BOOL)removeAllTweetsWithError:(NSError**)errorPtr
{
    __weak typeof(self) wself = self;
    return [self removeObjectsWithFetchRequestBlock:^NSFetchRequest *(NSManagedObjectContext *context, YSCoreDataOperation *operation) {
        return [wself removeAllTweetRecordRequestWithContext:context];
    } error:errorPtr];
}

- (YSCoreDataOperation *)removeAllTweetsWithCompletion:(YSCoreDataOperationCompletion)completion
{
    return [self removeObjectsWithFetchRequestBlock:^NSFetchRequest *(NSManagedObjectContext *context, YSCoreDataOperation *operation) {
        return [self removeAllTweetRecordRequestWithContext:context];
    } completion:completion];
}

- (NSFetchRequest*)removeAllTweetRecordRequestWithContext:(NSManagedObjectContext*)context
{
    NSFetchRequest* req = [[NSFetchRequest alloc] init];
    [req setEntity:[NSEntityDescription entityForName:@"Tweet"
                               inManagedObjectContext:context]];
    return req;
}

#pragma mark - count

- (NSUInteger)countTweetObjects
{
    return [self countObjectsWithEntitiyName:@"Tweet"];
}

- (NSUInteger)countUserObjects
{
    return [self countObjectsWithEntitiyName:@"User"];
}

@end
