//
//  NSURLRequest+DDMNetworkingMethods.m
//  DDMNetworking
//
//  Created by NEUSOFT on 17/6/20.
//  Copyright © 2017年 NEUSOFT. All rights reserved.
//

#import "NSURLRequest+DDMNetworkingMethods.h"
#import <objc/runtime.h>

static void *CTNetworkingRequestParams;


@implementation NSURLRequest (DDMNetworkingMethods)

- (void)setRequestParams:(NSDictionary *)requestParams
{
    objc_setAssociatedObject(self, &CTNetworkingRequestParams, requestParams, OBJC_ASSOCIATION_COPY);
}

- (NSDictionary *)requestParams
{
    return objc_getAssociatedObject(self, &CTNetworkingRequestParams);
}

@end
