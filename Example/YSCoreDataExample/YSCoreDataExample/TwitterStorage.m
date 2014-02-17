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
    /*
        一つのコンテキストで一気にinsertした方が良いのですが、Userの重複を防ぐために一つづつ処理しています
        一度にinsertする場合は以下。
     
        __weak typeof(self) wself = self;
        dispatch_async([[self class] insertQueue], ^{
            NSManagedObjectContext *temporaryContext = [wself createTemporaryContext];
            for (NSDictionary *twJson in tweetJsons) {
                // temporaryContextにinsertする処理
            }
            [wself saveWithTemporaryContext:temporaryContext];
        });
     
     */
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
        } else {
            NSLog(@"User insert");
            // 新しいUserを作成
            user = (id)[NSEntityDescription insertNewObjectForEntityForName:@"User"
                                                      inManagedObjectContext:tweet.managedObjectContext];
            user.id = userId;
        }
        user.name = [userJson objectForKey:@"name"];
        user.screen_name = [userJson objectForKey:@"screen_name"];
        
        tweet.user = user;
        
        // コンテキストを保存。最終的にprivateWriterContextによりsqliteへ保存される
        [wself saveWithTemporaryContext:temporaryContext];
    });
}

- (void)fetchTweetsLimit:(NSUInteger)limit maxId:(NSNumber *)maxId completion:(TwitterStorageFetchTweetsCompletion)completion
{
    __weak typeof(self) wself = self;
    dispatch_async([[self class] fetchQueue], ^{
        NSManagedObjectContext *temporaryContext = [wself createTemporaryContext];
        
        // 現在表示しているツイート(maxId)より新しいツイートをデータベースから取得
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        if (maxId) {
            request.predicate = [NSPredicate predicateWithFormat:@"id > %@", maxId];
        }
        request.fetchLimit = limit;
        NSEntityDescription *tweets = [NSEntityDescription entityForName:@"Tweet" inManagedObjectContext:temporaryContext];
        [request setEntity:tweets];
        
        // 降順にソートする指定
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"id" ascending:NO];
        [request setSortDescriptors:@[sortDescriptor]];
        
        // Fetch
        NSError *error = nil;
        NSArray *fetchResults = [temporaryContext executeFetchRequest:request error:&error];
        if (error) {
            NSLog(@"%s; error = %@;", __func__, error);
        }
        
        /*
         FetchしたNSManagedObjectを別スレッドに渡せない(temporaryContextと共に解放される)ので
         スレッドセーフなNSManagedObjectIDを保持する
         */
        NSMutableArray *ids = [NSMutableArray arrayWithCapacity:[fetchResults count]];
        for (NSManagedObject *obj in fetchResults) {
            [ids addObject:obj.objectID];
        }
        [wself.mainContext performBlock:^{
            /*
             mainContext(NSMainQueueConcurrencyTypeで初期化したContext)から
             保持していたNSManagedObjectIDを元にNSManagedObjectを取得
             */
             
            NSMutableArray *fetchResults = [NSMutableArray arrayWithCapacity:[ids count]];
            for (NSManagedObjectID *objId in ids) {
                [fetchResults addObject:[wself.mainContext objectWithID:objId]];
            }
            if (completion) completion(fetchResults);
        }];
    });
}

@end
