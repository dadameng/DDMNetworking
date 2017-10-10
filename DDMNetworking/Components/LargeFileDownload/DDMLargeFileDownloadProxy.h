//
//  DDMLargeFileDownloadProxy.h
//  NeuAdasPhone
//
//  Created by NEUSOFT on 17/6/22.
//  Copyright © 2017年 dadameng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDMLargeFileDownloadInterface.h"

@interface DDMLargeFileDownloadProxy : NSObject<DDMLargeFileDownloadInterface>
- (instancetype)initWithServiceIdentifier:(NSString *)serviceIdentifier;
@end
