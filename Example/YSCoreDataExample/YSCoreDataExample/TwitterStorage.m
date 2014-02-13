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
        NSManagedObjectContext *temporaryContext = [wself createTemporaryContext];
        
        NSNumber *tweetId = [tweetJson objectForKey:@"id"];
        
        NSFetchRequest *tweetsReq = [[NSFetchRequest alloc] init];
        tweetsReq.predicate = [NSPredicate predicateWithFormat:@"id = %@", tweetId];
        tweetsReq.entity = [NSEntityDescription entityForName:@"Tweet" inManagedObjectContext:temporaryContext];
        tweetsReq.resultType = NSCountResultType;
        NSError *error = nil;
        NSArray *tweetsResults = [temporaryContext executeFetchRequest:tweetsReq error:&error];
        if ([((NSNumber*)[tweetsResults firstObject]) integerValue] > 0) {
            NSLog(@"Saved tweet");
            return;
        }
        
        NSDictionary *userJson = [tweetJson objectForKey:@"user"];
        Tweet *tweet = (id)[NSEntityDescription insertNewObjectForEntityForName:@"Tweet"
                                                           inManagedObjectContext:temporaryContext];
        tweet.id = tweetId;
        tweet.text = [tweetJson objectForKey:@"text"];
        tweet.user_id = [userJson objectForKey:@"id"];
        
        NSString *name = [userJson objectForKey:@"name"];
        NSNumber *userId = [userJson objectForKey:@"id"];
        
        NSFetchRequest *req = [[NSFetchRequest alloc] init];
        req.predicate = [NSPredicate predicateWithFormat:@"id = %@", userId];
        req.entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:temporaryContext];
        
        error = nil;
        NSArray *fetchResults = [temporaryContext executeFetchRequest:req error:&error];
        User *user = [fetchResults firstObject];
        
        if (user) {
            NSLog(@"User update %@", userId);
            user.name = name;
        } else {
            NSLog(@"User insert");
            user = (id)[NSEntityDescription insertNewObjectForEntityForName:@"User"
                                                      inManagedObjectContext:tweet.managedObjectContext];
            user.id = userId;
            user.name = name;
        }
        tweet.user = user;
        
        [wself saveWithTemporaryContext:temporaryContext];
    });
}

- (void)fetchTweetsLimit:(NSUInteger)limit maxId:(NSNumber *)maxId completion:(TwitterStorageFetchTweetsCompletion)completion
{
    __weak typeof(self) wself = self;
    dispatch_async([[self class] fetchQueue], ^{
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        if (maxId) {
            request.predicate = [NSPredicate predicateWithFormat:@"id > %@", maxId];
        }
        request.fetchLimit = limit;
        
        NSEntityDescription *tweets = [NSEntityDescription entityForName:@"Tweet" inManagedObjectContext:wself.mainContext];
        [request setEntity:tweets];
        
        // Order the events by creation date, most recent first.
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"id" ascending:NO];
        [request setSortDescriptors:@[sortDescriptor]];
        
        // Execute the fetch -- create a mutable copy of the result.
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
