//
//  UIDevice+DDMNetworkingMethods.h
//  DDMNetworking
//
//  Created by NEUSOFT on 17/6/20.
//  Copyright © 2017年 NEUSOFT. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (DDMNetworkingMethods)


- (NSString *) DDM_macaddress;
- (NSString *) DDM_macaddressMD5;
- (NSString *) DDM_machineType;
- (NSString *) DDM_ostype;//显示“ios6，ios5”，只显示大版本号

@end
