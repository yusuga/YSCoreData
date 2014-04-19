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

- (YSCoreDataOperation*)insertTweetWithTweetJson:(NSDictionary*)tweetJson
                                      completion:(YSCoreDataOperationCompletion)completion
                                   didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite
{
    return [self insertTweetsWithTweetJsons:@[tweetJson]
                                 completion:completion
                              didSaveSQLite:didSaveSQLite];
}

- (YSCoreDataOperation*)insertTweetsWithTweetJsons:(NSArray*)tweetJsons
                                        completion:(YSCoreDataOperationCompletion)completion
                                     didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite
{
    if (![tweetJsons isKindOfClass:[NSArray class]]) {
        NSAssert1(0, @"%s; tweetJsons is not NSArray class;", __func__);
        NSLog(@"Error: %s; tweetJsons != NSArray class; tweetJsons class = %@;", __func__, NSStringFromClass([tweetJsons class]));
        return nil;
    }
    
    return [self asyncWriteWithConfigureManagedObject:^(NSManagedObjectContext *context,
                                                        YSCoreDataOperation *operation)
    {
        NSLog(@"Start: Insert %@", @([tweetJsons count]));
        for (NSDictionary *tweetJson in tweetJsons) {
            if (operation.isCancelled) {
                return;
            }
            
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
                continue;
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
                NSLog(@"User insert %@", userId);
                // 新しいUserを作成
                user = (id)[NSEntityDescription insertNewObjectForEntityForName:@"User"
                                                         inManagedObjectContext:tweet.managedObjectContext];
                user.id = userId;
            }
            user.name = [userJson objectForKey:@"name"];
            user.screen_name = [userJson objectForKey:@"screen_name"];
            
            tweet.user = user;
        }
    } completion:completion didSaveSQLite:didSaveSQLite];
}

- (YSCoreDataOperation*)fetchTweetsLimit:(NSUInteger)limit
                                   maxId:(NSNumber *)maxId
                              completion:(YSCoreDataOperationFetchCompletion)completion
{
    return [self asyncFetchWithConfigureFetchRequest:^NSFetchRequest *(NSManagedObjectContext *context,
                                                                       YSCoreDataOperation *operation)
            {
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
            } completion:completion];
}

- (YSCoreDataOperation*)removeAllTweetRecordWithCompletion:(YSCoreDataOperationCompletion)completion
                                             didSaveSQLite:(YSCoreDataOperationCompletion)didSaveSQLite
{
    return [self asyncRemoveRecordWithConfigureFetchRequest:^NSFetchRequest *(NSManagedObjectContext *context,
                                                                              YSCoreDataOperation *operation) {

        NSFetchRequest* req = [[NSFetchRequest alloc] init];
        [req setEntity:[NSEntityDescription entityForName:@"Tweet"
                                   inManagedObjectContext:context]];
        return req;
    } completion:completion didSaveSQLite:didSaveSQLite];
}

- (NSUInteger)countTweetRecord
{
    return [self countRecordWithEntitiyName:@"Tweet"];
}

- (NSUInteger)countUserRecord
{
    return [self countRecordWithEntitiyName:@"User"];
}


@end
