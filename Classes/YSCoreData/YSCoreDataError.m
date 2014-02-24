//
//  YSCoreDataError.m
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/24.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "YSCoreDataError.h"

NSString * const YSCoreDataErrorDomain = @"YSCoreDataErrorDomain";

@implementation YSCoreDataError

+ (NSError*)errorWithCode:(YSCoreDataErrorCode)code description:(NSString*)description
{
    return [NSError errorWithDomain:YSCoreDataErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey : description}];
}

#pragma mark - Public

+ (NSError*)cancelErrorWithOperationType:(YSCoreDataErrorOperationType)operationType
{
    NSString *desc;
    switch (operationType) {
        case YSCoreDataErrorOperationTypeWrite:
            desc = @"Cancel write";
            break;
        case YSCoreDataErrorOperationTypeFetch:
            desc = @"Cancel fetch";
            break;
        case YSCoreDataErrorOperationTypeRemove:
            desc = @"Cancel remove";
            break;
        default:
            desc = [NSString stringWithFormat:@"Cancel Unknown (%@)", @(operationType)];
            break;
    }
    return [self errorWithCode:YSCoreDataErrorCodeCancel description:desc];
}

+ (NSError*)requiredArgumentIsNilErrorWithDescription:(NSString*)description
{
    return [self errorWithCode:YSCoreDataErrorCodeRequiredArgumentIsNil description:description];
}

@end
