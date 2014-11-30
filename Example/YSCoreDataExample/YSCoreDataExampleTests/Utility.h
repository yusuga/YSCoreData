//
//  Utility.h
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/05/06.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterStorage.h"
#import "Models.h"

extern NSString * const kTwitterStorageOfMainBundlePath;

typedef NS_ENUM(NSUInteger, UtilityStoreType) {
    UtilityStoreTypeSQLite,
    UtilityStoreTypeBinary,
    UtilityStoreTypeInMemory,
    UtilityStoreType_MAX,
};

@interface Utility : NSObject

+ (void)commonSettins;
+ (void)cleanUpAllDatabase;

+ (YSCoreData*)coreDataWithStoreType:(UtilityStoreType)storeType;
+ (TwitterStorage*)twitterStorageWithStoreType:(UtilityStoreType)storeType;
+ (TwitterStorage*)twitterStorageOfMainBundle;

+ (NSArray*)allStoreType;
+ (void)enumerateAllCoreDataUsingBlock:(void(^)(YSCoreData *coreData))block;
+ (void)enumerateAllTwitterStorageUsingBlock:(void(^)(TwitterStorage *twitterStorage))block;

+ (NSString*)coreDataFileNameWithStoreType:(UtilityStoreType)storeType;
+ (NSString*)twitterStorageFileNameWithStoreType:(UtilityStoreType)storeType;

+ (NSString*)coreDataDocumentPathWithStoreType:(UtilityStoreType)storeType;
+ (NSString*)twitterStorageDocumentPathWithStoreType:(UtilityStoreType)storeType;
+ (NSString*)twitterStorageMainBundlePath;

+ (NSArray*)tweetsWithCount:(int64_t)count;
+ (void)addTweetsWithTwitterStorage:(TwitterStorage*)storage
                              count:(int64_t)count;
+ (void)addTweetWithTwitterStorage:(TwitterStorage*)storage
                  tweetJsonObjects:(NSArray*)tweetJsonObjects;
+ (NSArray*)fetchAllTweetsWithTwitterStorage:(TwitterStorage*)twitterStorage;

@end
