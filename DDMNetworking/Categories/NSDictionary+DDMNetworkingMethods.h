//
//  NSDictionary+DDMNetworkingMethods.h
//  DDMNetworking
//
//  Created by NEUSOFT on 17/6/20.
//  Copyright © 2017年 NEUSOFT. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (DDMNetworkingMethods)

- (NSString *)DDM_urlParamsStringSignature:(BOOL)isForSignature;
- (NSString *)DDM_jsonString;
- (NSArray  *)DDM_transformedUrlParamsArraySignature:(BOOL)isForSignature;

@end
