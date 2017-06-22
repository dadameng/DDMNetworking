//
//  DDMServiceFactory.h
//  DDMNetworking
//
//  Created by NEUSOFT on 17/6/20.
//  Copyright © 2017年 NEUSOFT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDMService.h"


@protocol DDMServiceFactoryDataSource <NSObject>

/*
 * key为service的Identifier
 * value为service的Class的字符串
 */
- (NSDictionary<NSString *,NSString *> *)servicesKindsOfServiceFactory;

@end

@interface DDMServiceFactory : NSObject

@property (nonatomic, weak) id<DDMServiceFactoryDataSource> dataSource;

+ (instancetype)sharedInstance;
- (DDMService<DDMServiceProtocol> *)serviceWithIdentifier:(NSString *)identifier;


@end
