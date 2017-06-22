//
//  DDMNetworkingConfigurationManager.m
//  DDMNetworking
//
//  Created by NEUSOFT on 17/6/20.
//  Copyright © 2017年 NEUSOFT. All rights reserved.
//

#import "DDMNetworkingConfigurationManager.h"
#import "AFNetworking.h"

@implementation DDMNetworkingConfigurationManager
+ (instancetype)sharedInstance
{
    static DDMNetworkingConfigurationManager *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DDMNetworkingConfigurationManager alloc] init];
        sharedInstance.shouldCache = YES;
        sharedInstance.serviceIsOnline = NO;
        sharedInstance.apiNetworkingTimeoutSeconds = 20.0f;
        sharedInstance.cacheOutdateTimeSeconds = 300;
        sharedInstance.cacheCountLimit = 1000;
        sharedInstance.shouldSetParamsInHTTPBodyButGET = NO;
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    });
    return sharedInstance;
}

- (BOOL)isReachable
{
    if ([AFNetworkReachabilityManager sharedManager].networkReachabilityStatus == AFNetworkReachabilityStatusUnknown) {
        return YES;
    } else {
        return [[AFNetworkReachabilityManager sharedManager] isReachable];
    }
}

@end
