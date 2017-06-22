//
//  DDMAPIProxy.h
//  DDMNetworking
//
//  Created by NEUSOFT on 17/6/20.
//  Copyright © 2017年 NEUSOFT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDMURLResponse.h"


typedef void(^DDMCallBack)(DDMURLResponse *response);
typedef void(^DDMProgressBack)(NSProgress * progress);


static NSString * const kDDMApiUploadFileURL = @"kDDMApiUploadFileURL";
static NSString * const kDDMApiUploadData = @"kDDMApiUploadData";

static NSString * const kDDMApiUploadName = @"kDDMApiUploadName";
static NSString * const kDDMApiUploadFileName = @"kDDMApiUploadFileName";
static NSString * const kDDMApiUploadMIMEType = @"kDDMApiUploadMIMEType";


@interface DDMAPIProxy : NSObject

+ (instancetype)sharedInstance;


- (NSInteger)callGETWithParams:(NSDictionary *)params serviceIdentifier:(NSString *)servieIdentifier methodName:(NSString *)methodName success:(DDMCallBack)success fail:(DDMCallBack)fail;
- (NSInteger)callPOSTWithParams:(NSDictionary *)params serviceIdentifier:(NSString *)servieIdentifier methodName:(NSString *)methodName success:(DDMCallBack)success fail:(DDMCallBack)fail;
- (NSInteger)callPUTWithParams:(NSDictionary *)params serviceIdentifier:(NSString *)servieIdentifier methodName:(NSString *)methodName success:(DDMCallBack)success fail:(DDMCallBack)fail;
- (NSInteger)callDELETEWithParams:(NSDictionary *)params serviceIdentifier:(NSString *)servieIdentifier methodName:(NSString *)methodName success:(DDMCallBack)success fail:(DDMCallBack)fail;


- (NSInteger)callUPLOADWithParams:(NSDictionary *)params serviceIdentifier:(NSString *)servieIdentifier methodName:(NSString *)methodName uploadFileParms:(NSDictionary *)uploadFileParms progress:(DDMProgressBack)progress success:(DDMCallBack)success fail:(DDMCallBack)fail;

- (NSNumber *)callApiWithRequest:(NSURLRequest *)request success:(DDMCallBack)success fail:(DDMCallBack)fail;
- (void)cancelRequestWithRequestID:(NSNumber *)requestID;
- (void)cancelRequestWithRequestIDList:(NSArray *)requestIDList; 


@end
