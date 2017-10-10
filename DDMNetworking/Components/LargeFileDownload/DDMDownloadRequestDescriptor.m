//
//  DDMDownloadRequestDescriptor.m
//  NeuAdasPhone
//
//  Created by NEUSOFT on 17/6/22.
//  Copyright © 2017年 dadameng. All rights reserved.
//

#import "DDMDownloadRequestDescriptor.h"

@implementation DDMDownloadRequestProgressDescriptor



@end

@implementation DDMDownloadRequestDescriptor
- (instancetype)init{
    self = [super init];
    if (self) {
        
        _progressModel = [[DDMDownloadRequestProgressDescriptor alloc] init];
        _downloadState = DDMDownLoadRequestTaskNone;
        
    }
    return self;
}

@end
