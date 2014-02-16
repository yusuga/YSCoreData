//
//  TwitterStorage.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/13.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "TwitterStorage.h"

@implementation TwitterStorage

- (void)insertTweetsWithTweetJsons:(NSArray*)tweetJsons
{
    if (![tweetJsons isKindOfClass:[NSArray class]]) {
        NSLog(@"Error: %s; tweetJsons != NSArray class; tweetJsons class = %@;", __func__, NSStringFromClass([tweetJsons class]));
        return;
    }
    for (NSDictionary *twJson in tweetJsons) {
        [self insertTweetWithTweetJson:twJson];
    }
}

- (void)insertTweetWithTweetJson:(NSDictionary*)tweetJson
{
    __weak typeof(self) wself = self;
    dispatch_async([[self class] insertQueue], ^{
        // テンポラリなContextを取得
        NSManagedObjectContext *temporaryContext = [wself createTemporaryContext];
        
        NSNumber *tweetId = [tweetJson objectForKey:@"id"];
        
        // 同一IDのTweetがあるか
        NSFetchRequest *tweetsReq = [[NSFetchRequest alloc] init];
        tweetsReq.predicate = [NSPredicate predicateWithFormat:@"id = %@", tweetId];
        tweetsReq.entity = [NSEntityDescription entityForName:@"Tweet" inManagedObjectContext:temporaryContext];
        tweetsReq.resultType = NSCountResultType;
        NSError *error = nil;
        NSArray *tweetsResults = [temporaryContext executeFetchRequest:tweetsReq error:&error];
        if ([((NSNumber*)[tweetsResults firstObject]) integerValue] > 0) {
            // 重複したTweetは保存しない
            NSLog(@"Saved tweet %@", tweetId);
            return;
        }
        
        // Tweetを作成
        NSDictionary *userJson = [tweetJson objectForKey:@"user"];
        Tweet *tweet = (id)[NSEntityDescription insertNewObjectForEntityForName:@"Tweet"
                                                           inManagedObjectContext:temporaryContext];
        tweet.id = tweetId;
        tweet.text = [tweetJson objectForKey:@"text"];
        tweet.user_id = [userJson objectForKey:@"id"];
        
        NSString *name = [userJson objectForKey:@"name"];
        NSNumber *userId = [userJson objectForKey:@"id"];
        
        // 同一IDのUserがあるか
        NSFetchRequest *req = [[NSFetchRequest alloc] init];
        req.predicate = [NSPredicate predicateWithFormat:@"id = %@", userId];
        req.entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:temporaryContext];
        
        error = nil;
        NSArray *fetchResults = [temporaryContext executeFetchRequest:req error:&error];
        User *user = [fetchResults firstObject];
        
        // 同一IDのUser(保存してたUser)があればUpdate。なければ新規のUesrをInsert
        if (user) {
            NSLog(@"User update %@", userId);
            user.name = name;
        } else {
            NSLog(@"User insert");
            // 新しいUserを作成
            user = (id)[NSEntityDescription insertNewObjectForEntityForName:@"User"
                                                      inManagedObjectContext:tweet.managedObjectContext];
            user.id = userId;
            user.name = name;
        }
        tweet.user = user;
        
        // コンテキストを保存。最終的にprivateWriterContextによりsqliteへ保存される
        [wself saveWithTemporaryContext:temporaryContext];
    });
}

- (void)fetchTweetsLimit:(NSUInteger)limit maxId:(NSNumber *)maxId completion:(TwitterStorageFetchTweetsCompletion)completion
{
    __weak typeof(self) wself = self;
    dispatch_async([[self class] fetchQueue], ^{
        // maxIdから現在表示しているツイートより新しいツイートをデータベースから取得
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        if (maxId) {
            request.predicate = [NSPredicate predicateWithFormat:@"id > %@", maxId];
        }
        request.fetchLimit = limit;
        NSEntityDescription *tweets = [NSEntityDescription entityForName:@"Tweet" inManagedObjectContext:wself.mainContext];
        [request setEntity:tweets];
        
        // 降順にソートする指定
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"id" ascending:NO];
        [request setSortDescriptors:@[sortDescriptor]];
        
        // Fetch
        NSError *error = nil;
        NSArray *fetchResults = [wself.mainContext executeFetchRequest:request error:&error];
        
        if (error) {
            NSLog(@"%s; error = %@;", __func__, error);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(fetchResults);
        });
    });
}

@end
