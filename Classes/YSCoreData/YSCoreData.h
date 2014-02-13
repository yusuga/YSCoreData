//
//  YSCoreData.h
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/13.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreData;

@interface YSCoreData : NSObject

+ (instancetype)sharedInstance;
- (void)setupWithDatabaseName:(NSString*)dbName;

@property (nonatomic, readonly) NSManagedObjectContext *mainContext;
- (NSManagedObjectContext *)createTemporaryContext;
- (void)saveWithTemporaryContext:(NSManagedObjectContext*)temporaryContext;

- (BOOL)removeDatabase;

+ (dispatch_queue_t)insertQueue;
+ (dispatch_queue_t)fetchQueue;

@end
