//
//  DDMLargeFileDownloadInterface.h
//  NeuAdasPhone
//
//  Created by NEUSOFT on 17/6/22.
//  Copyright © 2017年 dadameng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDMDownloadRequestDescriptor.h"



@protocol DDMLargeFileDownloadInterface <NSObject>

@optional
@property (nonatomic , assign           ) NSInteger                   maxConcurrentDownloadCount;
@property (nonatomic , copy             ) NSString                    *downloadDirectory;
@required

-(void)startDownloadWithDownloadModel:(DDMDownloadRequestDescriptor *)downloadModel
                             progress:(void (^)(DDMDownloadRequestDescriptor *  downloadingTask))progress
                    completionHandler:(void (^)(DDMDownloadRequestDescriptor *  downloadedTask, NSError *  error))completionHandler;
-(void)cancelDownloadTaskWithDownloadModel:(DDMDownloadRequestDescriptor *)downloadModel;
-(void)deleteDownloadedFileWithDownloadModel:(DDMDownloadRequestDescriptor *)downloadModel;


-(DDMDownloadRequestDescriptor *)getDownloadingModelWithURLString:(NSString *)URLString;
-(DDMDownloadRequestDescriptor *)getDownloadProgressModelWithDownloadModel:(DDMDownloadRequestDescriptor *)downloadModel;




@end
