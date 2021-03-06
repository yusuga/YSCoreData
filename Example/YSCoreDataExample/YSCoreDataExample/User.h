//
//  User.h
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/11/30.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Tweet;

@interface User : NSManagedObject

@property (nonatomic) int64_t id;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * screen_name;
@property (nonatomic, retain) NSSet *tweets;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addTweetsObject:(Tweet *)value;
- (void)removeTweetsObject:(Tweet *)value;
- (void)addTweets:(NSSet *)values;
- (void)removeTweets:(NSSet *)values;

@end
