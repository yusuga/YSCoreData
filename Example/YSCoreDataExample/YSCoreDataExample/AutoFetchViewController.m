//
//  AutoFetchViewController.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/17.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "AutoFetchViewController.h"

#if DEBUG
    #if 0
        #define LOG_AUTO_FETCH_FLOW NSLog(@"%s", __func__)
    #endif
#endif

#ifndef LOG_AUTO_FETCH_FLOW
    #define LOG_AUTO_FETCH_FLOW
#endif

@interface AutoFetchViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation AutoFetchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.getTweetLimit = 1;

    NSError *error;
    if (![[self fetchedResultsController] performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

#pragma mark - DetailViewControllerProtocol

- (void)configureCell:(TweetCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Tweet *tw = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [cell configureContentWithTweet:tw];
}

#pragma mark - Property

/**
 NSFetchRequestを元にFetch結果(Modelオブジェクト)が入るコントローラ
 初期化で設定したcontextが更新(-save:)されると保持している結果が変更される
 */
- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController == nil) {
        NSManagedObjectContext *mainContext = [TwitterStorage sharedInstance].mainContext;
        
        // Fetch条件
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Tweet" inManagedObjectContext:mainContext];
        [fetchRequest setEntity:entity];
        
        // idを降順ソート
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"id" ascending:NO];
        [fetchRequest setSortDescriptors:@[sortDescriptor]];
        
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:mainContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:@"Twitter"];
        _fetchedResultsController.delegate = self;
    }
    return _fetchedResultsController;
}

#pragma mark - NSFetchedResultsControllerDelegate

/**
 fetchedResultsControllerの初期化で設定したcontextが更新(-save:)されたら呼び出されるデリゲートメソッド
 データベースが更新されたら(mainContextに変更がマージされたら)NSFetchRequestに従いNSFetchedResultsChangeType等が決められ
 各デリゲートメソッドが呼ばれる。
 */

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    LOG_AUTO_FETCH_FLOW;
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    LOG_AUTO_FETCH_FLOW;
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeUpdate:
            [self configureCell:(TweetCell*)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    LOG_AUTO_FETCH_FLOW;
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    LOG_AUTO_FETCH_FLOW;
    [self.tableView endUpdates];
}

@end
