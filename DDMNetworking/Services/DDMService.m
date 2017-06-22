//
//  DDMService.m
//  DDMNetworking
//
//  Created by NEUSOFT on 17/6/20.
//  Copyright © 2017年 NEUSOFT. All rights reserved.
//

#import "DDMService.h"
#import "NSObject+DDMNetworkingMethods.h"

@interface DDMService()

@property (nonatomic, weak, readwrite) id<DDMServiceProtocol> child;

@end

@implementation DDMService

- (instancetype)init
{
    self = [super init];
    if (self) {
        if ([self conformsToProtocol:@protocol(DDMServiceProtocol)]) {
            self.child = (id<DDMServiceProtocol>)self;
        }
    }
    return self;
}

- (NSString *)urlGeneratingRuleByMethodName:(NSString *)methodName {
    NSString *urlString = nil;
    if (self.apiVersion.length != 0) {
        urlString = [NSString stringWithFormat:@"%@/%@/%@", self.apiBaseUrl, self.apiVersion, methodName];
    } else {
        urlString = [NSString stringWithFormat:@"%@/%@", self.apiBaseUrl, methodName];
    }
    return urlString;
}


#pragma mark - getters and setters
- (NSString *)privateKey
{
    return self.child.isOnline ? self.child.onlinePrivateKey : self.child.offlinePrivateKey;
}

- (NSString *)publicKey
{
    return self.child.isOnline ? self.child.onlinePublicKey : self.child.offlinePublicKey;
}

- (NSString *)apiBaseUrl
{
    return self.child.isOnline ? self.child.onlineApiBaseUrl : self.child.offlineApiBaseUrl;
}

- (NSString *)apiVersion
{
    return self.child.isOnline ? self.child.onlineApiVersion : self.child.offlineApiVersion;
}


@end
