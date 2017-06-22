//
//  DDMAPIBaseManager.m
//  DDMNetworking
//
//  Created by NEUSOFT on 17/6/20.
//  Copyright © 2017年 NEUSOFT. All rights reserved.
//
//#import "DDMNetworking.h"
#import "DDMAPIBaseManager.h"
#import "DDMLogger.h"
#import "DDMServiceFactory.h"
#import "DDMApiProxy.h"
#import "DDMNetworkingConfigurationManager.h"
#import "DDMCache.h"

#define AXCallAPI(REQUEST_METHOD, REQUEST_ID)                                                   \
{                                                                                               \
__weak typeof(self) weakSelf = self;                                                        \
REQUEST_ID = [[DDMAPIProxy sharedInstance] call##REQUEST_METHOD##WithParams:apiParams serviceIdentifier:self.child.serviceType methodName:self.child.methodName success:^(DDMURLResponse *response) {                                         \
__strong typeof(weakSelf) strongSelf = weakSelf;                                        \
[strongSelf successedOnCallingAPI:response];                                            \
} fail:^(DDMURLResponse *response) {                                                         \
__strong typeof(weakSelf) strongSelf = weakSelf;                                        \
[strongSelf failedOnCallingAPI:response withErrorType:DDMAPIManagerErrorTypeDefault];    \
}];                                                                                         \
[self.requestIdList addObject:@(REQUEST_ID)];                                                   \
}



@interface DDMAPIBaseManager ()

@property (nonatomic, strong, readwrite) id fetchedRawData;
@property (nonatomic, assign, readwrite) BOOL isLoading;
@property (nonatomic, assign) BOOL isNativeDataEmpty;

@property (nonatomic, copy, readwrite) NSString *errorMessage;
@property (nonatomic, readwrite) DDMAPIManagerErrorType errorType;
@property (nonatomic, strong) NSMutableArray *requestIdList;
@property (nonatomic, strong) DDMCache *cache;

@end

@implementation DDMAPIBaseManager

#pragma mark - life cycle
- (instancetype)init
{
    self = [super init];
    if (self) {
        _delegate = nil;
        _validator = nil;
        _paramSource = nil;
        
        _fetchedRawData = nil;
        
        _errorMessage = nil;
        _errorType = DDMAPIManagerErrorTypeDefault;
        
        if ([self conformsToProtocol:@protocol(DDMAPIManager)]) {
            self.child = (id <DDMAPIManager>)self;
            
        } else {
            self.child = (id <DDMAPIManager>)self;
            NSException *exception = [[NSException alloc] initWithName:@"CTAPIBaseManager提示" reason:[NSString stringWithFormat:@"%@没有遵循CTAPIManager协议",self.child] userInfo:nil];
            @throw exception;
        }
    }
    return self;
}

- (void)dealloc
{
    [self cancelAllRequests];
    self.requestIdList = nil;
}

#pragma mark - public methods
- (void)cancelAllRequests
{
    [[DDMAPIProxy sharedInstance] cancelRequestWithRequestIDList:self.requestIdList];
    [self.requestIdList removeAllObjects];
}

- (void)cancelRequestWithRequestId:(NSInteger)requestID
{
    [self removeRequestIdWithRequestID:requestID];
    [[DDMAPIProxy sharedInstance] cancelRequestWithRequestID:@(requestID)];
}

- (id)fetchDataWithReformer:(id<DDMAPIManagerDataReformer>)reformer
{
    id resultData = nil;
    if ([reformer respondsToSelector:@selector(manager:reformData:)]) {
        resultData = [reformer manager:self reformData:self.fetchedRawData];
    } else {
        resultData = [self.fetchedRawData mutableCopy];
    }
    return resultData;
}

#pragma mark - calling api
- (NSInteger)loadData
{
    NSDictionary *params = [self.paramSource paramsForApi:self];
    NSInteger requestId = [self loadDataWithParams:params];
    return requestId;
}

- (NSInteger)loadDataWithParams:(NSDictionary *)params
{
    NSInteger requestId = 0;
    NSDictionary *apiParams = [self reformParams:params];
    if ([self shouldCallAPIWithParams:apiParams]) {
        if ([self.validator manager:self isCorrectWithParamsData:apiParams]) {
            
            if ([self.child shouldLoadFromNative]) {
                [self loadDataFromNative];
            }
            
            // 先检查一下是否有缓存
            if ([self shouldCache] && [self hasCacheWithParams:apiParams]) {
                return 0;
            }
            
            // 实际的网络请求
            if ([self isReachable]) {
                self.isLoading = YES;
                switch (self.child.requestType)
                {
                    case DDMAPIManagerRequestTypeGet:
                        AXCallAPI(GET, requestId);
                        break;
                    case DDMAPIManagerRequestTypePost:
                        AXCallAPI(POST, requestId);
                        break;
                    case DDMAPIManagerRequestTypePut:
                        AXCallAPI(PUT, requestId);
                        break;
                    case DDMAPIManagerRequestTypeDelete:
                        AXCallAPI(DELETE, requestId);
                        break;
                    case DDMAPIManagerRequestTypeUpload:{
                        
                        __weak typeof(self) weakSelf = self;
                        requestId = [[DDMAPIProxy sharedInstance] callUPLOADWithParams:apiParams serviceIdentifier:self.child.serviceType methodName:self.child.methodName uploadFileParms:[self.paramSource uploadParamsForApi:self] progress:^(NSProgress *progress) {
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            [strongSelf uploadProgress:progress];
                        } success:^(DDMURLResponse *response) {
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            [strongSelf successedOnCallingAPI:response];
                        } fail:^(DDMURLResponse *response) {
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            [strongSelf failedOnCallingAPI:response withErrorType:DDMAPIManagerErrorTypeDefault];
                        }];
                        [self.requestIdList addObject:@(requestId)];
                        
                        
                    }
                    default:
                        break;
                }
                
                NSMutableDictionary *params = [apiParams mutableCopy];
                params[kDDMAPIBaseManagerRequestID] = @(requestId);
                [self afterCallingAPIWithParams:params];
                return requestId;
                
            } else {
                [self failedOnCallingAPI:nil withErrorType:DDMAPIManagerErrorTypeNoNetWork];
                return requestId;
            }
        } else {
            [self failedOnCallingAPI:nil withErrorType:DDMAPIManagerErrorTypeParamsError];
            return requestId;
        }
    }
    return requestId;
}

#pragma mark - api callbacks
- (void)successedOnCallingAPI:(DDMURLResponse *)response
{
    self.isLoading = NO;
    self.response = response;
    
    if ([self.child shouldLoadFromNative]) {
        if (response.isCache == NO) {
            [[NSUserDefaults standardUserDefaults] setObject:response.responseData forKey:[self.child methodName]];
        }
    }
    
    if (response.content) {
        self.fetchedRawData = [response.content copy];
    } else {
        self.fetchedRawData = [response.responseData copy];
    }
    [self removeRequestIdWithRequestID:response.requestId];
    if ([self.validator manager:self isCorrectWithCallBackData:response.content]) {
        
        if ([self shouldCache] && !response.isCache) {
            [self.cache saveCacheWithData:response.responseData serviceIdentifier:self.child.serviceType methodName:self.child.methodName requestParams:response.requestParams];
        }
        
        if ([self beforePerformSuccessWithResponse:response]) {
            if ([self.child shouldLoadFromNative]) {
                if (response.isCache == YES) {
                    [self.delegate managerCallAPIDidSuccess:self];
                }
                if (self.isNativeDataEmpty) {
                    [self.delegate managerCallAPIDidSuccess:self];
                }
            } else {
                [self.delegate managerCallAPIDidSuccess:self];
            }
        }
        [self afterPerformSuccessWithResponse:response];
    } else {
        [self failedOnCallingAPI:response withErrorType:DDMAPIManagerErrorTypeNoContent];
    }
}
- (void)uploadProgress:(NSProgress *)uploadProgress{
    
    [self.delegate managerCallApiUploadProgress:uploadProgress manager:self];
    
}
- (void)failedOnCallingAPI:(DDMURLResponse *)response withErrorType:(DDMAPIManagerErrorType)errorType
{
    NSString *serviceIdentifier = self.child.serviceType;
    DDMService *service = [[DDMServiceFactory sharedInstance] serviceWithIdentifier:serviceIdentifier];
    
    self.isLoading = NO;
    self.response = response;
    BOOL needCallBack = YES;
    
    if ([service.child respondsToSelector:@selector(shouldCallBackByFailedOnCallingAPI:)]) {
        needCallBack = [service.child shouldCallBackByFailedOnCallingAPI:response];
    }
    
    //由service决定是否结束回调
    if (!needCallBack) {
        return;
    }
    
    //继续错误的处理
    self.errorType = errorType;
    [self removeRequestIdWithRequestID:response.requestId];
    
    if (response.content) {
        self.fetchedRawData = [response.content copy];
    } else {
        self.fetchedRawData = [response.responseData copy];
    }
    
    if ([self beforePerformFailWithResponse:response]) {
        [self.delegate managerCallAPIDidFailed:self];
    }
    [self afterPerformFailWithResponse:response];
}






#pragma mark - method for interceptor

/*
 拦截器的功能可以由子类通过继承实现，也可以由其它对象实现,两种做法可以共存
 当两种情况共存的时候，子类重载的方法一定要调用一下super
 然后它们的调用顺序是BaseManager会先调用子类重载的实现，再调用外部interceptor的实现
 
 notes:
 正常情况下，拦截器是通过代理的方式实现的，因此可以不需要以下这些代码
 但是为了将来拓展方便，如果在调用拦截器之前manager又希望自己能够先做一些事情，所以这些方法还是需要能够被继承重载的
 所有重载的方法，都要调用一下super,这样才能保证外部interceptor能够被调到
 这就是decorate pattern
 */
- (BOOL)beforePerformSuccessWithResponse:(DDMURLResponse *)response
{
    BOOL result = YES;
    
    self.errorType = DDMAPIManagerErrorTypeSuccess;
    if (self != self.interceptor && [self.interceptor respondsToSelector:@selector(manager: beforePerformSuccessWithResponse:)]) {
        result = [self.interceptor manager:self beforePerformSuccessWithResponse:response];
    }
    return result;
}

- (void)afterPerformSuccessWithResponse:(DDMURLResponse *)response
{
    if (self != self.interceptor && [self.interceptor respondsToSelector:@selector(manager:afterPerformSuccessWithResponse:)]) {
        [self.interceptor manager:self afterPerformSuccessWithResponse:response];
    }
}

- (BOOL)beforePerformFailWithResponse:(DDMURLResponse *)response
{
    BOOL result = YES;
    if (self != self.interceptor && [self.interceptor respondsToSelector:@selector(manager:beforePerformFailWithResponse:)]) {
        result = [self.interceptor manager:self beforePerformFailWithResponse:response];
    }
    return result;
}

- (void)afterPerformFailWithResponse:(DDMURLResponse *)response
{
    if (self != self.interceptor && [self.interceptor respondsToSelector:@selector(manager:afterPerformFailWithResponse:)]) {
        [self.interceptor manager:self afterPerformFailWithResponse:response];
    }
}

//只有返回YES才会继续调用API
- (BOOL)shouldCallAPIWithParams:(NSDictionary *)params
{
    if (self != self.interceptor && [self.interceptor respondsToSelector:@selector(manager:shouldCallAPIWithParams:)]) {
        return [self.interceptor manager:self shouldCallAPIWithParams:params];
    } else {
        return YES;
    }
}

- (void)afterCallingAPIWithParams:(NSDictionary *)params
{
    if (self != self.interceptor && [self.interceptor respondsToSelector:@selector(manager:afterCallingAPIWithParams:)]) {
        [self.interceptor manager:self afterCallingAPIWithParams:params];
    }
}

#pragma mark - method for child
- (void)cleanData
{
    [self.cache clean];
    self.fetchedRawData = nil;
    self.errorMessage = nil;
    self.errorType = DDMAPIManagerErrorTypeDefault;
}

//如果需要在调用API之前额外添加一些参数，比如pageNumber和pageSize之类的就在这里添加
//子类中覆盖这个函数的时候就不需要调用[super reformParams:params]了
- (NSDictionary *)reformParams:(NSDictionary *)params
{
    IMP childIMP = [self.child methodForSelector:@selector(reformParams:)];
    IMP selfIMP = [self methodForSelector:@selector(reformParams:)];
    
    if (childIMP == selfIMP) {
        return params;
    } else {
        // 如果child是继承得来的，那么这里就不会跑到，会直接跑子类中的IMP。
        // 如果child是另一个对象，就会跑到这里
        NSDictionary *result = nil;
        result = [self.child reformParams:params];
        if (result) {
            return result;
        } else {
            return params;
        }
    }
}

- (BOOL)shouldCache
{
    return [DDMNetworkingConfigurationManager sharedInstance].shouldCache;
}

#pragma mark - private methods
- (void)removeRequestIdWithRequestID:(NSInteger)requestId
{
    NSNumber *requestIDToRemove = nil;
    for (NSNumber *storedRequestId in self.requestIdList) {
        if ([storedRequestId integerValue] == requestId) {
            requestIDToRemove = storedRequestId;
        }
    }
    if (requestIDToRemove) {
        [self.requestIdList removeObject:requestIDToRemove];
    }
}

- (BOOL)hasCacheWithParams:(NSDictionary *)params
{
    NSString *serviceIdentifier = self.child.serviceType;
    NSString *methodName = self.child.methodName;
    NSData *result = [self.cache fetchCachedDataWithServiceIdentifier:serviceIdentifier methodName:methodName requestParams:params];
    
    if (result == nil) {
        return NO;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof (weakSelf) strongSelf = weakSelf;
        DDMURLResponse *response = [[DDMURLResponse alloc] initWithData:result];
        response.requestParams = params;
        [DDMLogger logDebugInfoWithCachedResponse:response methodName:methodName serviceIdentifier:[[DDMServiceFactory sharedInstance] serviceWithIdentifier:serviceIdentifier]];
        [strongSelf successedOnCallingAPI:response];
    });
    return YES;
}

- (void)loadDataFromNative
{
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:self.child.methodName] options:0 error:NULL];
    
    if (result) {
        self.isNativeDataEmpty = NO;
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            DDMURLResponse *response = [[DDMURLResponse alloc] initWithData:[NSJSONSerialization dataWithJSONObject:result options:0 error:NULL]];
            [strongSelf successedOnCallingAPI:response];
        });
    } else {
        self.isNativeDataEmpty = YES;
    }
}

#pragma mark - getters and setters
- (DDMCache *)cache
{
    if (_cache == nil) {
        _cache = [DDMCache sharedInstance];
    }
    return _cache;
}

- (NSMutableArray *)requestIdList
{
    if (_requestIdList == nil) {
        _requestIdList = [[NSMutableArray alloc] init];
    }
    return _requestIdList;
}

- (BOOL)isReachable
{
    BOOL isReachability = [DDMNetworkingConfigurationManager sharedInstance].isReachable;
    if (!isReachability) {
        self.errorType = DDMAPIManagerErrorTypeNoNetWork;
    }
    return isReachability;
}

- (BOOL)isLoading
{
    if (self.requestIdList.count == 0) {
        _isLoading = NO;
    }
    return _isLoading;
}

- (BOOL)shouldLoadFromNative
{
    return NO;
}
@end
