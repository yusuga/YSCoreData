//
//  Tweet.h
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/13.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Tweet : NSManagedObject

@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSNumber * user_id;
@property (nonatomic, retain) User *user;

@end
