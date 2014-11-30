//
//  ManualFetchViewController.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/17.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "ManualFetchViewController.h"

@interface ManualFetchViewController ()

@property (nonatomic) NSMutableArray *tweets;
@property (nonatomic) YSCoreDataOperation *fetchOperation;

@end

@implementation ManualFetchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tweets = [NSMutableArray array];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.fetchOperation cancel];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tweets count];
}

#pragma mark - DetailViewControllerProtocol

- (void)configureCell:(TweetCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Tweet *tw = [self.tweets objectAtIndex:indexPath.row];
    [cell configureContentWithTweet:tw];
}

#pragma mark - Button action

- (IBAction)updateButtonDidPush:(id)sender
{
    Tweet *tweet = [self.tweets firstObject];
    NSError *error = nil;
    [[TwitterStorage sharedInstance] writeWithWriteBlock:^(NSManagedObjectContext *context, YSCoreDataOperation *operation) {
        tweet.text = @"UPDATE";
        tweet.user.name = @"NAME";
    } error:&error];
    [self.tableView reloadData];
}

- (IBAction)asyncUpdate:(id)sender
{
    Tweet *tweet = [self.tweets firstObject];
    
    __weak typeof(self) wself = self;
    NSManagedObjectID *objectID = tweet.objectID;
    [[TwitterStorage sharedInstance] writeWithWriteBlock:^(NSManagedObjectContext *context, YSCoreDataOperation *operation) {
        NSFetchRequest *req = [[NSFetchRequest alloc] initWithEntityName:tweet.entity.name];
        req.predicate = [NSPredicate predicateWithFormat:@"self = %@", objectID];
        req.fetchLimit = 1;
        
        NSError *error = nil;
        Tweet *tweet = [[context executeFetchRequest:req error:&error] firstObject];
        tweet.text = @"UPDATE";
        tweet.user.name = @"NAME";
    } completion:^(YSCoreDataOperation *operation, NSError *error) {
        NSAssert1(error == nil, @"error: %@", error);
        [wself.tableView reloadData];
    }];
}

- (IBAction)fetchButtonDidPush:(id)sender
{    
    // CoreDataからツイートを取得
    __weak typeof(self) wself = self;
    Tweet *tw = [self.tweets firstObject];
    self.fetchOperation = [[TwitterStorage sharedInstance] fetchTweetsLimit:10 maxId:tw.id completion:^(YSCoreDataOperation *operation, NSArray *tweets, NSError *error) {
        if (error) {
            NSLog(@"Failure: error = %@", error);
            return ;
        }
        NSUInteger tweetsCount = [tweets count];
        NSLog(@"fetch tweets %@", @(tweetsCount));
        if (tweetsCount == 0) {
            return;
        }
        
        // TableViewに反映
        NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, tweetsCount)];
        [wself.tweets insertObjects:tweets atIndexes:set];
        NSMutableArray *paths = [NSMutableArray arrayWithCapacity:tweetsCount];
        for (int i = 0; i < tweetsCount; i++) {
            [paths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        [wself.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
    }];
}

@end
