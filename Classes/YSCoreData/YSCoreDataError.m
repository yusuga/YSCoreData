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

+ (NSError *)saveErrorWithType:(YSCoreDataErrorSaveType)saveType
{
    NSString *desc;
    switch (saveType) {
        case YSCoreDataErrorSaveTypeTemporaryContext:
            desc = @"Save failed for temporary context.";
            break;
        case YSCoreDataErrorSaveTypeMainContext:
            desc = @"Save failed for main context.";
            break;
        case YSCoreDataErrorSaveTypePrivateWriterContext:
            desc = @"Save failed for privateWriter context.";
            break;
        default:
            desc = @"Save failed for Unknown context.";
            break;
    }
    return [self errorWithCode:YSCoreDataErrorCodeSave description:desc];
}

@end
