//
//  YSCoreDataError.h
//  YSCoreDataExample
//
//  Created by Yu Sugawara on 2014/02/24.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const YSCoreDataErrorDomain;

typedef enum {
    YSCoreDataErrorCodeUnknown,
    YSCoreDataErrorCodeCancel,
    YSCoreDataErrorCodeRequiredArgumentIsNil,
    YSCoreDataErrorCodeSave,
} YSCoreDataErrorCode;

typedef enum {
    YSCoreDataErrorOperationTypeUnkwnon,
    YSCoreDataErrorOperationTypeWrite,
    YSCoreDataErrorOperationTypeFetch,
    YSCoreDataErrorOperationTypeRemove,
} YSCoreDataErrorOperationType;

@interface YSCoreDataError : NSObject

+ (NSError*)cancelErrorWithType:(YSCoreDataErrorOperationType)operationType;
+ (NSError*)requiredArgumentIsNilErrorWithDescription:(NSString*)description;

@end
