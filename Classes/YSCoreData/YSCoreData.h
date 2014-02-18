//
//  YSCoreData.h
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/13.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreData;

typedef void(^YSCoreDataAysncWriteConfigure)(NSManagedObjectContext *context);
typedef void(^YSCoreDataAysncWriteFailure)(NSError *error);

typedef NSFetchRequest*(^YSCoreDataAysncFetchConfigure)(NSManagedObjectContext *context);
typedef void(^YSCoreDataAysncFetchSuccess)(NSArray *fetchResults);
typedef void(^YSCoreDataAysncFetchFailure)(NSError *error);

@interface YSCoreData : NSObject

+ (instancetype)sharedInstance;
- (void)setupWithDatabaseName:(NSString*)dbName;

@property (nonatomic, readonly) NSManagedObjectContext *mainContext;

- (void)asyncWriteWithConfigureManagedObject:(YSCoreDataAysncWriteConfigure)configure
                                   failure:(YSCoreDataAysncWriteFailure)failure;

- (void)asyncFetchWithConfigureFetchRequest:(YSCoreDataAysncFetchConfigure)configure
                                  success:(YSCoreDataAysncFetchSuccess)success
                                  failure:(YSCoreDataAysncFetchFailure)failure;

- (BOOL)removeDatabase;

@end
