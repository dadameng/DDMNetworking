//
//  DDMAPIGeneralizedBlockManager.h
//  DrivingAssistance
//
//  Created by NEUSOFT on 2017/8/15.
//  Copyright © 2017年 dadameng. All rights reserved.
//

#import "DDMAPIBaseManager.h"

typedef void (^GeneralizedSuccessBlock)(id result);
typedef void (^GeneralizedFailedBlock)(NSError * error);


@interface DDMAPIGeneralizedBlockManager : DDMAPIBaseManager<DDMAPIManager>



- (void)requestServiceType:(NSString *)serviceType
               requestType:(DDMAPIManagerRequestType)requestType
                methodName:(NSString *)methodName
                      parm:(NSDictionary *)parmDict
          responseReformer:(id<DDMAPIManagerDataReformer>)reformer
                   success:(GeneralizedSuccessBlock)success
                   failure:(GeneralizedFailedBlock)failure;

@end
