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
                           userInfo:description ? @{NSLocalizedDescriptionKey : description} : nil];
}

#pragma mark - Public

+ (NSError*)cancelErrorWithType:(YSCoreDataErrorOperationType)operationType
{
    NSString *desc;
    switch (operationType) {
        case YSCoreDataErrorOperationTypeWrite:
            desc = @"Cancel the write operation.";
            break;
        case YSCoreDataErrorOperationTypeFetch:
            desc = @"Cancel the fetch operation.";
            break;
        case YSCoreDataErrorOperationTypeRemove:
            desc = @"Cancel the remove operation.";
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

+ (NSError *)timeoutError
{
    return [self errorWithCode:YSCoreDataErrorCodeTimeout description:nil];
}

@end
