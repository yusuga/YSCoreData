//
//  Utility.h
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/05/06.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterStorage.h"

extern NSString * const kTwitterStorageOfMainBundlePath;

@interface Utility : NSObject

+ (YSCoreData*)coreDataWithStoreType:(NSString*)storeType;
+ (TwitterStorage*)twitterStorageWithStoreType:(NSString*)storeType;
+ (TwitterStorage*)twitterStorageOfMainBundle;

+ (NSString*)coreDataPathWithStoreType:(NSString*)storeType;
+ (NSString*)twitterStoragePathWithStoreType:(NSString*)storeType;

+ (void)cleanUpAllDatabase;

+ (void)commonSettins;

@end
