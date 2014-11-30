//
//  NSManagedObject+YSCoreData.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/11/29.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "NSManagedObject+YSCoreData.h"

@implementation NSManagedObject (YSCoreData)

+ (NSString *)ys_entityName
{
    return NSStringFromClass([self class]);
}

- (NSString *)ys_entityName
{
    return [[self class] ys_entityName];
}

@end
