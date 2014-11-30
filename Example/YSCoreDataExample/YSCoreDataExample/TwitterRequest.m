//
//  TwitterRequest.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/18.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "TwitterRequest.h"

#define kVirtualTweetId @"kVirtualTweetId"
static NSUInteger s_virtualTweetId; // Twitterの仮想なリクエストのためのId

@implementation TwitterRequest

+ (void)initialize
{
    if (self == [TwitterRequest class]) {
        // ツイートの仮想なリクエストのためのID設定
        s_virtualTweetId = [[NSUserDefaults standardUserDefaults] integerForKey:kVirtualTweetId];
        
        NSAssert([[self userNames] count] == [[self screenNames] count], nil);
        NSAssert([[self userNames] count] == [[self greetings] count], nil);
    }
}

+ (NSArray *)requestTweetsWithMaxCount:(NSUInteger)maxCount
{
    return [self requestTweetsWithCount:arc4random_uniform((u_int32_t)maxCount) + 1]; // limit個のツイートを取得;
}

+ (NSArray *)requestTweetsWithCount:(NSUInteger)count
{
    // ツイートを取得する仮想なリクエスト
    NSMutableArray *newTweets = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        NSUInteger idx = arc4random_uniform((u_int32_t)[[self userNames] count]); // ランダムなidx
        NSString *name = [[self class] userNames][idx];
        NSString *screenName = [[self class] screenNames][idx];
        NSString *text = [[self class] greetings][idx];
        
        [newTweets addObject:[self tweetWithTweetID:s_virtualTweetId + i
                                               text:text
                                             userID:idx
                                               name:name
                                         screenName:screenName]];
    }
    
    // TweetIdを更新
    s_virtualTweetId += count;
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setInteger:s_virtualTweetId forKey:kVirtualTweetId];
    [ud synchronize];
    
    //    NSLog(@"get new tweets = \n%@", newTweets);
    
    return newTweets;
}

+ (NSArray*)userNames
{
    return @[@"田中太郎", @"John Smith", @"Иван Иванович Иванов", @"Hans Schmidt", @"張三李四"];
}

+ (NSArray*)screenNames
{
    return @[@"taro", @"john", @"ivan", @"hans", @"cho"];
}

+ (NSArray*)greetings
{
    return @[@"おはようございます。", @"Good morning.", @"Доброе утро.", @"Guten Morgen.", @"你早。"];
}

+ (void)resetState
{
    s_virtualTweetId = 0;
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setInteger:0 forKey:kVirtualTweetId];
    [ud synchronize];
}

+ (NSDictionary*)tweetWithTweetID:(int64_t)tweetID
                           userID:(int64_t)userID
{
    return [TwitterRequest tweetWithTweetID:tweetID
                                       text:[NSString stringWithFormat:@"text%zd", tweetID]
                                     userID:userID
                                       name:[NSString stringWithFormat:@"name%zd", userID]
                                 screenName:[NSString stringWithFormat:@"screen_name%zd", userID]];
}

+ (NSDictionary*)tweetWithTweetID:(int64_t)tweetID
                             text:(NSString*)text
                           userID:(int64_t)userID
                             name:(NSString*)name
                       screenName:(NSString*)screenName
{
    // 超簡易なTwitterのJSON (本来のJSON https://dev.twitter.com/docs/api/1.1/get/statuses/show/%3Aid )
    return @{@"id" : @(tweetID),
             @"text" : text,
             @"user" : @{
                     @"id" : @(userID),
                     @"name" : name,
                     @"screen_name" : screenName}
             };
}

@end
