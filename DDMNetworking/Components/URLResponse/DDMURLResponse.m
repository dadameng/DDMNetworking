//
//  DDMURLResponse.m
//  DDMNetworking
//
//  Created by NEUSOFT on 17/6/20.
//  Copyright © 2017年 NEUSOFT. All rights reserved.
//

#import "DDMURLResponse.h"
#import "NSObject+DDMNetworkingMethods.h"
#import "NSURLRequest+DDMNetworkingMethods.h"

@interface DDMURLResponse ()

@property (nonatomic, assign, readwrite) DDMURLResponseStatus status;
@property (nonatomic, copy  , readwrite) NSString *contentString;
@property (nonatomic, copy  , readwrite) id content;
@property (nonatomic, copy  , readwrite) NSURLRequest *request;
@property (nonatomic, assign, readwrite) NSInteger requestId;
@property (nonatomic, copy  , readwrite) NSData *responseData;
@property (nonatomic, assign, readwrite) BOOL isCache;
@property (nonatomic, strong, readwrite) NSError *error;

@end


@implementation DDMURLResponse
#pragma mark - life cycle
- (instancetype)initWithResponseString:(NSString *)responseString requestId:(NSNumber *)requestId request:(NSURLRequest *)request responseData:(NSData *)responseData status:(DDMURLResponseStatus)status
{
    self = [super init];
    if (self) {
        self.contentString = responseString;
        self.content = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:NULL];
        self.status = status;
        self.requestId = [requestId integerValue];
        self.request = request;
        self.responseData = responseData;
        self.requestParams = request.requestParams;
        self.isCache = NO;
        self.error = nil;
    }
    return self;
}

- (instancetype)initWithResponseString:(NSString *)responseString requestId:(NSNumber *)requestId request:(NSURLRequest *)request responseData:(NSData *)responseData error:(NSError *)error
{
    self = [super init];
    if (self) {
        self.contentString = [responseString DDM_defaultValue:@""];
        self.status = [self responseStatusWithError:error];
        self.requestId = [requestId integerValue];
        self.request = request;
        self.responseData = responseData;
        self.requestParams = request.requestParams;
        self.isCache = NO;
        self.error = error;
        if (responseData) {
            self.content = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:NULL];
        } else {
            self.content = nil;
        }
    }
    return self;
}

- (instancetype)initWithData:(NSData *)data
{
    self = [super init];
    if (self) {
        self.contentString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        self.status = [self responseStatusWithError:nil];
        self.requestId = 0;
        self.request = nil;
        self.responseData = [data copy];
        self.content = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:NULL];
        self.isCache = YES;
    }
    return self;
}

#pragma mark - private methods
- (DDMURLResponseStatus)responseStatusWithError:(NSError *)error
{
    if (error) {
        DDMURLResponseStatus result = DDMURLResponseStatusErrorNoNetwork;
        
        // 除了超时以外，所有错误都当成是无网络
        if (error.code == NSURLErrorTimedOut) {
            result = DDMURLResponseStatusErrorTimeout;
        }
        return result;
    } else {
        return DDMURLResponseStatusSuccess;
    }
}

@end
