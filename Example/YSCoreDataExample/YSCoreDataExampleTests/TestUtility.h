//
//  TestUtility.h
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/05/06.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterStorage.h"

extern NSString * const kCoreDataPath;
extern NSString * const kTwitterStoragePath;

@interface TestUtility : NSObject

+ (YSCoreData*)coreDataWithStoreType:(NSString*)storeType;
+ (TwitterStorage*)twitterStorageWithStoreType:(NSString*)storeType;
+ (TwitterStorage*)twitterStorageOfMainBundleWithStoreType:(NSString*)storeType;

+ (void)cleanUpAllDatabase;

@end
