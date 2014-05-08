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
#import <UIActionSheet+Blocks/UIActionSheet+Blocks.h>

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

- (IBAction)otherOperationButtonDidPush:(id)sender
{
    [UIActionSheet showInView:self.view
                    withTitle:@"Other operation"
            cancelButtonTitle:@"Cancel"
       destructiveButtonTitle:nil
            otherButtonTitles:@[@"count all objects",
                                @"remove tweets",
                                @"remove all objects",
                                @"delete database"]
                     tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex)
     {
         if (buttonIndex == actionSheet.cancelButtonIndex) {
             return ;
         }
         TwitterStorage *storage = [TwitterStorage sharedInstance];
         switch (buttonIndex) {
             case 0:
                 NSLog(@"%@", [storage countAllEntitiesByName]);
                 break;
             case 1:
                 [self removeTweets];
                 break;
             case 2:
             {
                 NSError *error = nil;
                 BOOL success = [storage removeAllObjectsWithError:&error didSaveSQLite:^(NSManagedObjectContext *context, NSError *error)
                 {
                     if (error) {
                         [[[UIAlertView alloc] initWithTitle:@"Error: removeAllObjects"
                                                     message:[error description]
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil] show];
                     }
                 }];
                 NSLog(@"removeAllObjects: %@", success ? @"success" : @"failure");
                 break;
             }
             case 3:
                 [self deleteDatabase];
                 break;
             default:
                 NSAssert1(0, @"Unknown index: %@", @(buttonIndex));
                 break;
         }
     }];
}

- (void)removeTweets
{
    NSLog(@"%s", __func__);
    TwitterStorage *ts = [TwitterStorage sharedInstance];
    
    __weak typeof(self) wself = self;
    [ts asyncRemoveAllTweetRecordWithCompletion:^(NSManagedObjectContext *context, NSError *error) {
        if (error) {
            NSLog(@"error %@", error);
            return ;
        }
        [wself removeFetchedResultsControllerCache];
        NSLog(@">count Tweet = %@", @([ts countTweetRecord]));
        NSLog(@">count User = %@", @([ts countUserRecord]));
    } didSaveSQLite:nil];
}

- (IBAction)deleteDatabase
{
    BOOL success = [[TwitterStorage sharedInstance] deleteDatabase];
    [TwitterRequest resetState];
    [self removeFetchedResultsControllerCache];
    
    [[[UIAlertView alloc] initWithTitle:success ? @"データベースを削除しました" : @"Error"
                                message:success ? nil : @"database was not deleted."
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
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
