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
    // ツイートの仮想なリクエストのためのID設定
    s_virtualTweetId = [[NSUserDefaults standardUserDefaults] integerForKey:kVirtualTweetId];
}


+ (void)requestTweetsWithMaxCount:(NSUInteger)maxCount completion:(RequestTwitterCompletion)completion
{
    NSUInteger count = arc4random_uniform((u_int32_t)maxCount) + 1; // limit個のツイートを取得
    [self requestTweetsWithCount:count completion:completion];
}

+ (void)requestTweetsWithCount:(NSUInteger)count completion:(RequestTwitterCompletion)completion
{
    // ツイートを取得する仮想なリクエスト
    NSMutableArray *newTweets = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        NSArray *texts = @[@"おはようございます", @"こんにちは", @"こんばんは", @"さようなら", @"いい天気ですね"];
        NSString *text = [texts objectAtIndex:arc4random_uniform((u_int32_t)[texts count])]; // ランダムなtext
        NSArray *names = [self userNames];
        NSArray *screenNames = [self screenNames];
        NSAssert2([names count] == [screenNames count], @"[names count] != [screenNames count]; [names count] = %@; [screenNames count] = %@;", @([names count]), @([screenNames count]));
        NSUInteger userId = arc4random_uniform((u_int32_t)[names count]); // ランダムなuser id
        NSString *name = [names objectAtIndex:userId];
        NSString *screenName = [screenNames objectAtIndex:userId];
        
        // 超簡易なTwitterのJSON (本来のJSON https://dev.twitter.com/docs/api/1.1/get/statuses/show/%3Aid )
        NSDictionary *json = @{
                               @"id" : @(s_virtualTweetId + i),
                               @"text" : text,
                               @"user" : @{
                                       @"id" : @(userId),
                                       @"name" : name,
                                       @"screen_name" : screenName}
                               };
        
        [newTweets addObject:json];
    }
    
    // TweetIdを更新
    s_virtualTweetId += count;
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setInteger:s_virtualTweetId forKey:kVirtualTweetId];
    [ud synchronize];
    
    //    NSLog(@"get new tweets = \n%@", newTweets);
    
    if (completion) completion(newTweets);
}

+ (NSArray*)userNames
{
    return @[@"羽生", @"高橋", @"町田", @"小塚", @"織田"];
}

+ (NSArray*)screenNames
{
    return @[@"hanyu", @"takahashi", @"machida", @"kozuka", @"oda"];
}

+ (void)resetState
{
    s_virtualTweetId = 0;
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setInteger:0 forKey:kVirtualTweetId];
    [ud synchronize];
}

@end
