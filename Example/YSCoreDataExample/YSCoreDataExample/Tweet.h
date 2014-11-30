//
//  Tweet.h
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/11/30.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Tweet : NSManagedObject

@property (nonatomic) int64_t id;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) User *user;

@end
