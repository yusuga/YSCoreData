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

#pragma mark - Button action

- (IBAction)removeDatabaseButtonDidPush:(id)sender
{
    [[TwitterStorage sharedInstance] removeDatabase];
    [TwitterRequest resetState];
    
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
    
    [[[UIAlertView alloc] initWithTitle:@"データベースを削除しました" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

@end
