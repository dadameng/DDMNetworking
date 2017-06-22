//
//  DDMLogger.h
//  DDMNetworking
//
//  Created by NEUSOFT on 17/6/20.
//  Copyright © 2017年 NEUSOFT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDMService.h"
#import "DDMLoggerConfiguration.h"
#import "DDMURLResponse.h"
@interface DDMLogger : NSObject

@property (nonatomic, strong, readonly) DDMLoggerConfiguration *configParams;

+ (void)logDebugInfoWithRequest:(NSURLRequest *)request apiName:(NSString *)apiName service:(DDMService *)service requestParams:(id)requestParams httpMethod:(NSString *)httpMethod;
+ (void)logDebugInfoWithResponse:(NSHTTPURLResponse *)response responseString:(NSString *)responseString request:(NSURLRequest *)request error:(NSError *)error;
+ (void)logDebugInfoWithCachedResponse:(DDMURLResponse *)response methodName:(NSString *)methodName serviceIdentifier:(DDMService *)service;

+ (instancetype)sharedInstance;
- (void)logWithActionCode:(NSString *)actionCode params:(NSDictionary *)params;
@end
