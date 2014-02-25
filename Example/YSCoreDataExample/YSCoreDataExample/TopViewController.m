//
//  TopViewController.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/18.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "TopViewController.h"
#import "TwitterStorage.h"
#import "TwitterRequest.h"

@interface TopViewController ()

@end

@implementation TopViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    TwitterStorage *ts = [TwitterStorage sharedInstance];
    NSLog(@"count Tweet = %@", @([ts countTweetRecord]));
    NSLog(@"count User = %@", @([ts countUserRecord]));
}

#pragma mark - Button action

- (IBAction)removeTweetButtonDidPush:(id)sender
{
    NSLog(@"%s", __func__);
    TwitterStorage *ts = [TwitterStorage sharedInstance];
    
    __weak typeof(self) wself = self;
    [ts removeAllTweetRecordWithSuccess:^{
        [wself removeFetchedResultsControllerCache];
        NSLog(@">count Tweet = %@", @([ts countTweetRecord]));
        NSLog(@">count User = %@", @([ts countUserRecord]));
    } failure:^(NSManagedObjectContext *context, NSError *error) {
        NSLog(@"error %@", error);
    } didSaveSQLite:nil];
}

- (IBAction)deleteDatabaseButtonDidPush:(id)sender
{
    [[TwitterStorage sharedInstance] deleteDatabase];
    [TwitterRequest resetState];
    [self removeFetchedResultsControllerCache];
    
    [[[UIAlertView alloc] initWithTitle:@"データベースを削除しました" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark -

- (void)removeFetchedResultsControllerCache
{
    /**
     NSFetchedResultsControllerのキャッシュを削除
     データベースだけ削除してNSFetchedResultsControllerのキャッシュを削除しなかった場合に、例えば
     
     - (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
     {
     id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
     return [sectionInfo numberOfObjects];
     }
     
     でキャッシュのデータを返されてしまう場合がある
     */
    [NSFetchedResultsController deleteCacheWithName:@"Twitter"];
}

@end
