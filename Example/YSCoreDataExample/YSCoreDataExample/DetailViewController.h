//
//  ViewController.h
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/13.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TweetCell.h"
#import "TwitterStorage.h"

@protocol DetailViewControllerProtocol <NSObject>

- (void)configureCell:(TweetCell*)cell atIndexPath:(NSIndexPath*)indexPath;

@end

@interface DetailViewController : UITableViewController <DetailViewControllerProtocol>

@property (nonatomic) NSUInteger getTweetLimit;

@end
