//
//  ViewController.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/13.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "DetailViewController.h"
#import "TwitterRequest.h"

@interface DetailViewController ()

@property (nonatomic) YSCoreDataOperation *insertOperation;

@end

@implementation DetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerNib:[TweetCell nib] forCellReuseIdentifier:@"Cell"];
    
    self.getTweetLimit = 5;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.insertOperation cancel];
}

#pragma mark - Table view data source

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    abort();
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    TweetCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [TweetCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Button action

- (IBAction)insertTweetsButtonDidPush:(id)sender
{
    // 取得したツイートをCoreDataに保存
    self.insertOperation = [[TwitterStorage sharedInstance] insertTweetsWithTweetJsons:[TwitterRequest requestTweetsWithMaxCount:self.getTweetLimit]
                                                                            completion:nil];
}

@end
