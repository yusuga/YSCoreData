//
//  CategoryTests.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/11/30.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Models.h"
#import "NSManagedObject+YSCoreData.h"

@interface CategoryTests : XCTestCase

@end

@implementation CategoryTests

- (void)setUp
{
    [super setUp];
}

- (void)testEntityName
{
    XCTAssertEqualObjects([Tweet ys_entityName], @"Tweet");
    XCTAssertEqualObjects([User ys_entityName], @"User");
}

@end
