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
     簡易的なNSArrayでのInsert処理
     
     この処理はUserIDが重複する場合があります。(Twitterなので本来はUserの重複を防いで保存したい)
     重複される理由はtemporaryContextを元にUserの重複を確認しているからです。newTemporaryContextは作成した段階でのmainContenxtが
     保持しているNSManagedObjectを参照できます。ですので、下記の方法だと同一のUserが含まれるNSArrayだとその分が重複されます。
     
     Serial Dispatch Queueで防げそうなのですが、
     ・newTemporaryContextの生成で別スレッドからmainContextにアクセスすることになる(mainContextをlockすればいいと思います)
     ・temporaryContextのsave(mainContextへのマージ)が終わるまで次のnewTemporaryContextを生成しない
     の2つが必要になります。
     その場合、mainContextへのマージでコストがかかり保存時間が長くなります。
     
     以上のことから、重複チェックはNSArrayから重複チェックをしinsert or updateをした方がよさそうです。
     */
    for (NSDictionary *twJson in tweetJsons) {
        [self insertTweetWithTweetJson:twJson];
    }
}

- (void)insertTweetWithTweetJson:(NSDictionary*)tweetJson
{
    [self asyncWriteWithConfigureManagedObject:^(NSManagedObjectContext *context) {
        NSNumber *tweetId = [tweetJson objectForKey:@"id"];
        
        // 同一IDのTweetがあるか
        NSFetchRequest *tweetsReq = [[NSFetchRequest alloc] init];
        tweetsReq.predicate = [NSPredicate predicateWithFormat:@"id = %@", tweetId];
        tweetsReq.entity = [NSEntityDescription entityForName:@"Tweet" inManagedObjectContext:context];
        tweetsReq.resultType = NSCountResultType;
        NSError *error = nil;
        NSArray *tweetsResults = [context executeFetchRequest:tweetsReq error:&error];
        if ([((NSNumber*)[tweetsResults firstObject]) integerValue] > 0) {
            // 重複したTweetは保存しない
            NSLog(@"Saved tweet %@", tweetId);
            return;
        }
        
        // Tweetを作成
        NSDictionary *userJson = [tweetJson objectForKey:@"user"];
        Tweet *tweet = (id)[NSEntityDescription insertNewObjectForEntityForName:@"Tweet"
                                                         inManagedObjectContext:context];
        tweet.id = tweetId;
        tweet.text = [tweetJson objectForKey:@"text"];
        tweet.user_id = [userJson objectForKey:@"id"];
        
        NSNumber *userId = [userJson objectForKey:@"id"];
        
        // 同一IDのUserがあるか
        NSFetchRequest *req = [[NSFetchRequest alloc] init];
        req.predicate = [NSPredicate predicateWithFormat:@"id = %@", userId];
        req.entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:context];
        
        error = nil;
        NSArray *fetchResults = [context executeFetchRequest:req error:&error];
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
    } success:nil failure:^(NSManagedObjectContext *context, NSError *error) {
        NSLog(@"Failure: error = %@", error);
    }];
}

- (void)fetchTweetsLimit:(NSUInteger)limit
                   maxId:(NSNumber *)maxId
                 success:(TwitterStorageFetchTweetsSuccess)success
                 failure:(TwitterStorageFetchTweetsFailure)failure;
{
    [self asyncFetchWithConfigureFetchRequest:^NSFetchRequest *(NSManagedObjectContext *context) {        
        // 現在表示しているツイート(maxId)より新しいツイートを取得するリクエストを作成
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        if (maxId) {
            request.predicate = [NSPredicate predicateWithFormat:@"id > %@", maxId];
        }
        request.fetchLimit = limit;
        NSEntityDescription *tweets = [NSEntityDescription entityForName:@"Tweet" inManagedObjectContext:context];
        [request setEntity:tweets];
        
        // 降順にソートする指定
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"id" ascending:NO];
        [request setSortDescriptors:@[sortDescriptor]];
        
        return request;
    } success:^(NSArray *fetchResults) {
        if (success) success(fetchResults);
    } failure:^(NSError *error) {
        if (failure) failure(error);
    }];
}

@end
