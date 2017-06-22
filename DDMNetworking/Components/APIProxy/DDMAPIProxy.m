//
//  DDMAPIProxy.m
//  DDMNetworking
//
//  Created by NEUSOFT on 17/6/20.
//  Copyright © 2017年 NEUSOFT. All rights reserved.
//

#import "DDMAPIProxy.h"
#import "DDMServiceFactory.h"
#import "DDMRequestGenerator.h"
#import "DDMLogger.h"
#import "NSURLRequest+DDMNetworkingMethods.h"
#import "AFNetworking.h"

static NSString * const kDDMApiProxyDispatchItemKeyCallbackSuccess = @"kDDMApiProxyDispatchItemCallbackSuccess";
static NSString * const kDDMApiProxyDispatchItemKeyCallbackFail = @"kDDMApiProxyDispatchItemCallbackFail";

@interface DDMAPIProxy ()

@property (nonatomic, strong) NSMutableDictionary *dispatchTable;
@property (nonatomic, strong) NSNumber *recordedRequestId;

//AFNetworking stuff
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@end


@implementation DDMAPIProxy
#pragma mark - getters and setters
- (NSMutableDictionary *)dispatchTable
{
    if (_dispatchTable == nil) {
        _dispatchTable = [[NSMutableDictionary alloc] init];
    }
    return _dispatchTable;
}

- (AFHTTPSessionManager *)sessionManager
{
    if (_sessionManager == nil) {
        _sessionManager = [AFHTTPSessionManager manager];
        _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _sessionManager.securityPolicy.allowInvalidCertificates = YES;
        _sessionManager.securityPolicy.validatesDomainName = NO;
    }
    return _sessionManager;
}
- (id)httpSessionManagerWithServiceIdentifier:(NSString *)servieIdentifier
{
    id sessionManager;
    
    DDMService * service = [[DDMServiceFactory sharedInstance] serviceWithIdentifier:servieIdentifier];
    if ([service respondsToSelector:@selector(sessionManager)]) {
        if ([[service.child sessionManager] respondsToSelector:@selector(dataTaskWithRequest:completionHandler:)]) {
            sessionManager = [service.child sessionManager];
        }else{
            sessionManager = self.sessionManager;
        }
    }else{
        sessionManager = self.sessionManager;
    }
    return sessionManager;
}

#pragma mark - life cycle
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static DDMAPIProxy *sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DDMAPIProxy alloc] init];
    });
    return sharedInstance;
}

#pragma mark - public methods
- (NSInteger)callGETWithParams:(NSDictionary *)params serviceIdentifier:(NSString *)servieIdentifier methodName:(NSString *)methodName success:(DDMCallBack)success fail:(DDMCallBack)fail
{
    NSURLRequest *request = [[DDMRequestGenerator sharedInstance] generateGETRequestWithServiceIdentifier:servieIdentifier requestParams:params methodName:methodName];
    NSNumber *requestId = [self callApiWithRequest:request serviceIdentifier:servieIdentifier success:success fail:fail];
    return [requestId integerValue];
}

- (NSInteger)callPOSTWithParams:(NSDictionary *)params serviceIdentifier:(NSString *)servieIdentifier methodName:(NSString *)methodName success:(DDMCallBack)success fail:(DDMCallBack)fail
{
    NSURLRequest *request = [[DDMRequestGenerator sharedInstance] generatePOSTRequestWithServiceIdentifier:servieIdentifier requestParams:params methodName:methodName];
    NSNumber *requestId = [self callApiWithRequest:request serviceIdentifier:servieIdentifier success:success fail:fail];
    return [requestId integerValue];
}

- (NSInteger)callPUTWithParams:(NSDictionary *)params serviceIdentifier:(NSString *)servieIdentifier methodName:(NSString *)methodName success:(DDMCallBack)success fail:(DDMCallBack)fail
{
    NSURLRequest *request = [[DDMRequestGenerator sharedInstance] generatePutRequestWithServiceIdentifier:servieIdentifier requestParams:params methodName:methodName];
    NSNumber *requestId = [self callApiWithRequest:request serviceIdentifier:servieIdentifier success:success fail:fail];
    return [requestId integerValue];
}

- (NSInteger)callDELETEWithParams:(NSDictionary *)params serviceIdentifier:(NSString *)servieIdentifier methodName:(NSString *)methodName success:(DDMCallBack)success fail:(DDMCallBack)fail
{
    NSURLRequest *request = [[DDMRequestGenerator sharedInstance] generateDeleteRequestWithServiceIdentifier:servieIdentifier requestParams:params methodName:methodName];
    NSNumber *requestId = [self callApiWithRequest:request serviceIdentifier:servieIdentifier success:success fail:fail];
    return [requestId integerValue];
}






- (NSInteger)callUPLOADWithParams:(NSDictionary *)params serviceIdentifier:(NSString *)servieIdentifier methodName:(NSString *)methodName uploadFileParms:(NSDictionary *)uploadFileParms progress:(DDMProgressBack)progress success:(DDMCallBack)success fail:(DDMCallBack)fail{
    
    NSParameterAssert(uploadFileParms[kDDMApiUploadName]);
    
    NSURLRequest *request;
    if (uploadFileParms[kDDMApiUploadFileURL]) {
        
        request = [[DDMRequestGenerator sharedInstance] generateUploadRequestWithServiceIdentifier:servieIdentifier requestParams:params methodName:methodName constructingBodyWithFileURL:uploadFileParms[kDDMApiUploadFileURL] name:uploadFileParms[kDDMApiUploadName] fileName:uploadFileParms[kDDMApiUploadFileName] mimeType:uploadFileParms[kDDMApiUploadMIMEType]];

    }else{
        NSParameterAssert(uploadFileParms[kDDMApiUploadData]);
        request = [[DDMRequestGenerator sharedInstance] generateUploadRequestWithServiceIdentifier:servieIdentifier requestParams:params methodName:methodName constructingBodyWithFileData:uploadFileParms[kDDMApiUploadData] name:uploadFileParms[kDDMApiUploadName] fileName:uploadFileParms[kDDMApiUploadFileName] mimeType:uploadFileParms[kDDMApiUploadMIMEType]];

    }
    
    
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [[self httpSessionManagerWithServiceIdentifier:servieIdentifier] uploadTaskWithStreamedRequest:request progress:^(NSProgress * uploadProgress) {
        progress ? progress(uploadProgress) : nil;
        
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        NSNumber *requestID = @([dataTask taskIdentifier]);
        [self.dispatchTable removeObjectForKey:requestID];
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSData *responseData = responseObject;
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        
        if (error) {
            [DDMLogger logDebugInfoWithResponse:httpResponse
                                 responseString:responseString
                                        request:request
                                          error:error];
            DDMURLResponse *DDMResponse = [[DDMURLResponse alloc] initWithResponseString:responseString requestId:requestID request:request responseData:responseData error:error];
            fail?fail(DDMResponse):nil;
        } else {
            // 检查http response是否成立。
            [DDMLogger logDebugInfoWithResponse:httpResponse
                                 responseString:responseString
                                        request:request
                                          error:NULL];
            DDMURLResponse *DDMResponse = [[DDMURLResponse alloc] initWithResponseString:responseString requestId:requestID request:request responseData:responseData status:DDMURLResponseStatusSuccess];
            success?success(DDMResponse):nil;
        }

        
    }];
    NSNumber *requestId = @([dataTask taskIdentifier]);
    return [requestId integerValue];
}

- (void)cancelRequestWithRequestID:(NSNumber *)requestID
{
    NSURLSessionDataTask *requestOperation = self.dispatchTable[requestID];
    [requestOperation cancel];
    [self.dispatchTable removeObjectForKey:requestID];
}

- (void)cancelRequestWithRequestIDList:(NSArray *)requestIDList
{
    for (NSNumber *requestId in requestIDList) {
        [self cancelRequestWithRequestID:requestId];
    }
}

/** 这个函数存在的意义在于，如果将来要把AFNetworking换掉，只要修改这个函数的实现即可。 */
- (NSNumber *)callApiWithRequest:(NSURLRequest *)request serviceIdentifier:(NSString *)servieIdentifier success:(DDMCallBack)success fail:(DDMCallBack)fail
{
    
    NSLog(@"\n==================================\n\nRequest Start: \n\n %@\n\n==================================", request.URL);

    
    
    // 跑到这里的block的时候，就已经是主线程了。
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [[self httpSessionManagerWithServiceIdentifier:servieIdentifier] dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        NSNumber *requestID = @([dataTask taskIdentifier]);
        [self.dispatchTable removeObjectForKey:requestID];
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSData *responseData = responseObject;
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        
        if (error) {
            [DDMLogger logDebugInfoWithResponse:httpResponse
                                responseString:responseString
                                       request:request
                                         error:error];
            DDMURLResponse *DDMResponse = [[DDMURLResponse alloc] initWithResponseString:responseString requestId:requestID request:request responseData:responseData error:error];
            fail?fail(DDMResponse):nil;
        } else {
            // 检查http response是否成立。
            [DDMLogger logDebugInfoWithResponse:httpResponse
                                responseString:responseString
                                       request:request
                                         error:NULL];
            DDMURLResponse *DDMResponse = [[DDMURLResponse alloc] initWithResponseString:responseString requestId:requestID request:request responseData:responseData status:DDMURLResponseStatusSuccess];
            success?success(DDMResponse):nil;
        }
    }];
    
    NSNumber *requestId = @([dataTask taskIdentifier]);
    
    self.dispatchTable[requestId] = dataTask;
    [dataTask resume];
    
    return requestId;
}
@end
