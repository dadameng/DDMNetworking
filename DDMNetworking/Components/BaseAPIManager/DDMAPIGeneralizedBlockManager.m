//
//  DDMAPIGeneralizedBlockManager.m
//  DrivingAssistance
//
//  Created by NEUSOFT on 2017/8/15.
//  Copyright © 2017年 dadameng. All rights reserved.
//

#import "DDMAPIGeneralizedBlockManager.h"

#import "DDMHTTPConst.h"

@interface DDMAPIGeneralizedBlockManager ()<DDMAPIManagerValidator,DDMAPIManagerCallBackDelegate,DDMAPIManagerParamSource>

@property (nonatomic , copy  ) NSString               * blockServiceType;
@property (nonatomic , assign) DDMAPIManagerRequestType blockRequestType;
@property (nonatomic , copy  ) NSString               * blockMethodName;
@property (nonatomic , copy  ) NSDictionary           * blockParmDict;
@property (nonatomic , copy  ) GeneralizedSuccessBlock  success;
@property (nonatomic , copy  ) GeneralizedFailedBlock   failure;
@property (nonatomic , copy  ) id<DDMAPIManagerDataReformer> reformer;
@end

@implementation DDMAPIGeneralizedBlockManager
-(instancetype)init{
    self = [super init];
    if (self) {
        self.validator      = self;
        self.paramSource    = self;
        self.delegate       = self;
    }
    return self;
}
- (void)requestServiceType:(NSString *)serviceType
               requestType:(DDMAPIManagerRequestType)requestType
                methodName:(NSString *)methodName
                      parm:(NSDictionary *)parmDict
          responseReformer:(id<DDMAPIManagerDataReformer>)reformer
                   success:(GeneralizedSuccessBlock)success
                   failure:(GeneralizedFailedBlock)failure{
    
    self.blockServiceType = serviceType;
    self.blockRequestType = requestType;
    self.blockMethodName  = methodName;
    self.blockParmDict    = parmDict;
    self.reformer         = reformer;
    self.success          = success;
    self.failure          = failure;
    
}
#pragma mark - DDMAPIManager
-(NSString *)methodName
{
    return self.blockMethodName;
}
-(NSString *)serviceType
{
    return self.blockServiceType;
}
-(DDMAPIManagerRequestType)requestType{
    return self.blockRequestType;
}

-(BOOL)shouldCache
{
    return NO;
}

-(NSDictionary*)reformParams:(NSDictionary *)params{
    
    return params;
}
#pragma mark - DDMAPIManagerParamSource


- (NSDictionary *)paramsForApi:(DDMAPIBaseManager *)manager{
    return self.blockParmDict;
}

#pragma mark - DDMAPIManagerValidator
- (BOOL)manager:(DDMAPIBaseManager *)manager isCorrectWithParamsData:(NSDictionary *)data
{
    return YES;
}

- (BOOL)manager:(DDMAPIBaseManager *)manager isCorrectWithCallBackData:(NSDictionary *)data
{
    if (data[@"status"][@"code"] == 0) {
        return YES;
    }
    
    return YES;
}

#pragma mark -DDMAPIManagerCallBackDelegate
- (void)managerCallAPIDidSuccess:(DDMAPIBaseManager *)manager{

    if (self.success) {
        self.success([manager fetchDataWithReformer:self.reformer]);
    }
    
    
    
}
- (void)managerCallAPIDidFailed:(DDMAPIBaseManager *)manager{
    
    NSError * errorMsg = [NSError errorWithDomain:manager.errorMessage ? :@"failed" code:manager.errorType userInfo:nil];
    if (self.failure) {
        self.failure(errorMsg);
    }
    
}
@end
