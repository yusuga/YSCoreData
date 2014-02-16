//
//  ViewController.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/13.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "ViewController.h"
#import "TwitterStorage.h"

#define kVirtualTweetId @"kVirtualTweetId"

@interface ViewController ()

@property (nonatomic) NSMutableArray *tweets;

@property (nonatomic) NSUInteger virtualTweetId; // Twitterの仮想なリクエストのためのId

@end

@implementation ViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tweets = [NSMutableArray array];

    // データベース名を設定
    [[TwitterStorage sharedInstance] setupWithDatabaseName:@"Twitter.db"];
    
    // ツイートの仮想なリクエストのためのID設定
    self.virtualTweetId = [[NSUserDefaults standardUserDefaults] integerForKey:kVirtualTweetId];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tweets count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Tweet *tw = [self.tweets objectAtIndex:indexPath.row];
    User *user = tw.user;
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (user id: %@)", user.name, user.id];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (tweet id: %@)", tw.text, tw.id];
    
    return cell;
}

#pragma mark - Button action

- (IBAction)getTweetsButtonDidPush:(id)sender
{
    NSUInteger count = arc4random_uniform(10) + 1; // 1〜10個のツイートを取得
    
    // ツイートを取得する仮想なリクエスト
    NSMutableArray *newTweets = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        NSArray *texts = @[@"おはようございます", @"こんにちは", @"こんばんは", @"さようなら", @"いい天気ですね"];
        NSString *text = [texts objectAtIndex:arc4random_uniform([texts count])]; // ランダムなtext
        NSArray *names = @[@"田中", @"佐藤", @"小林", @"近藤", @"江口", @"河合"];
        NSUInteger userId = arc4random_uniform([names count]); // ランダムなuser id
        NSString *name = [names objectAtIndex:userId];
        
        // 超簡易なTwitterのJSON (本来のJSON https://dev.twitter.com/docs/api/1.1/get/statuses/show/%3Aid )
        NSDictionary *json = @{
                               @"id" : @(self.virtualTweetId + i),
                               @"text" : text,
                               @"user" : @{
                                       @"id" : @(userId),
                                       @"name" : name}
                               };

        [newTweets addObject:json];
    }
    
    // TweetIdを更新
    self.virtualTweetId += count;
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setInteger:self.virtualTweetId forKey:kVirtualTweetId];
    [ud synchronize];
    
//    NSLog(@"get new tweets = \n%@", newTweets);
    
    // 取得したツイートをCoreDataに保存
    [[TwitterStorage sharedInstance] insertTweetsWithTweetJsons:newTweets];
}

- (IBAction)fetchButtonDidPush:(id)sender
{
    // CoreDataからツイートを取得
    __weak typeof(self) wself = self;
    Tweet *tw = [self.tweets firstObject];
    [[TwitterStorage sharedInstance] fetchTweetsLimit:10 maxId:tw.id completion:^(NSArray *tweets) {
        NSUInteger tweetsCount = [tweets count];
        NSLog(@"fetch tweets %d", tweetsCount);
        if (tweetsCount == 0) {
            return;
        }
        
        // テーブルに反映
        NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, tweetsCount)];
        [wself.tweets insertObjects:tweets atIndexes:set];
        NSMutableArray *paths = [NSMutableArray arrayWithCapacity:tweetsCount];
        for (int i = 0; i < tweetsCount; i++) {
            [paths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        [wself.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
    }];
}

- (IBAction)removeDatabase:(id)sender
{
    [[TwitterStorage sharedInstance] removeDatabase];
    [self.tweets removeAllObjects];
    [self.tableView reloadData];
    self.virtualTweetId = 0;
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setInteger:0 forKey:kVirtualTweetId];
    [ud synchronize];
}

@end
