//
//  DDMServiceFaDDMory.m
//  DDMNetworking
//
//  Created by NEUSOFT on 17/6/20.
//  Copyright © 2017年 NEUSOFT. All rights reserved.
//

#import "DDMServiceFactory.h"
#import "DDMService.h"

/*************************************************************************/

// service name list


@interface DDMServiceFactory ()

@property (nonatomic, strong) NSMutableDictionary *serviceStorage;

@end

@implementation DDMServiceFactory

#pragma mark - getters and setters
- (NSMutableDictionary *)serviceStorage
{
    if (_serviceStorage == nil) {
        _serviceStorage = [[NSMutableDictionary alloc] init];
    }
    return _serviceStorage;
}

#pragma mark - life cycle
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static DDMServiceFactory *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DDMServiceFactory alloc] init];
    });
    return sharedInstance;
}

#pragma mark - public methods
- (DDMService<DDMServiceProtocol> *)serviceWithIdentifier:(NSString *)identifier
{
    NSAssert(self.dataSource, @"必须提供dataSource绑定并实现servicesKindsOfServiceFaDDMory方法，否则无法正常使用Service模块");
    
    if (self.serviceStorage[identifier] == nil) {
        self.serviceStorage[identifier] = [self newServiceWithIdentifier:identifier];
    }
    return self.serviceStorage[identifier];
}

#pragma mark - private methods
- (DDMService<DDMServiceProtocol> *)newServiceWithIdentifier:(NSString *)identifier
{
    NSAssert([self.dataSource respondsToSelector:@selector(servicesKindsOfServiceFactory)], @"请实现DDMServiceFaDDMoryDataSource的servicesKindsOfServiceFaDDMory方法");
    
    if ([[self.dataSource servicesKindsOfServiceFactory]valueForKey:identifier]) {
        NSString *classStr = [[self.dataSource servicesKindsOfServiceFactory]valueForKey:identifier];
        id service = [[NSClassFromString(classStr) alloc]init];
        NSAssert(service, [NSString stringWithFormat:@"无法创建service，请检查servicesKindsOfServiceFaDDMory提供的数据是否正确"],service);
        NSAssert([service conformsToProtocol:@protocol(DDMServiceProtocol)], @"你提供的Service没有遵循DDMServiceProtocol");
        return service;
    }else {
        NSAssert(NO, @"servicesKindsOfServiceFaDDMory中无法找不到相匹配identifier");
    }
    
    return nil;
}
@end
