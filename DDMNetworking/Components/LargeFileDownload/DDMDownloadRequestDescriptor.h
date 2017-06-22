//
//  DDMDownloadRequestDescriptor.h
//  NeuAdasPhone
//
//  Created by NEUSOFT on 17/6/22.
//  Copyright © 2017年 dadameng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DDMDownloadRequestProgressDescriptor : NSObject

/*
 * data length of the bytes written.
 */
@property (nonatomic, assign) int64_t totalBytesWritten;
/*
 * the total bytes of the resource data.
 */
@property (nonatomic, assign) int64_t totalBytesExpectedToWrite;
/*
 * download speed.
 */
@property (nonatomic, assign) int64_t downloadSpeed;
/*
 * download progress.
 */
@property (nonatomic, assign) float downloadProgress;
/*
 * download remaining time
 */
@property (nonatomic, assign) int32_t downloadRemainingTime;

@end

typedef NS_ENUM(NSInteger,DDMDownLoadRequestTaskState) {
    DDMDownLoadRequestTaskNone,
    DDMDownLoadRequestTaskDownloading,
    DDMDownLoadRequestTaskWillDownload,
    DDMDownLoadRequestTaskSuspened,
    DDMDownLoadRequestTaskFinishedDownload
    
};


@interface DDMDownloadRequestDescriptor : NSObject
/** 下载的资源URL 如果指定URL 则 下面的 methodName 和 parmDic无效  */
@property (nonatomic, copy   ) NSString                    * resourceURLString;

@property (nonatomic, copy   ) NSString                    * methodName;
@property (nonatomic, copy   ) NSDictionary                * parmDic;

/** 文件名 */
@property (nonatomic, copy   ) NSString                    * fileName;
/** 文件的总长度 */
@property (nonatomic, copy   ) NSString                    * fileSize;
/** 文件的类型(文件后缀,比如:mp4)*/
@property (nonatomic, copy   ) NSString                    * fileType;
/** 是否是第一次接受数据，如果是则不累加第一次返回的数据长度，之后变累加 */
@property (nonatomic, assign ) BOOL                        isFirstReceived;
/** 接受的数据 */
@property (nonatomic, strong ) NSData                      * resumeData;
/** 下载文件的URL */
@property (nonatomic, copy   ) NSString                    * fileDestinationURL;
/** 临时文件路径 */
@property (nonatomic, copy   ) NSString                    * temporaryFileDownloadPath;

@property (nonatomic, strong ) NSDate                      * downloadDate;
/** md5 */
@property (nonatomic, copy   ) NSString                    *MD5;
/** 文件的附属图片 */
@property (nonatomic, strong ) UIImage                     * thumbImage;


@property (nonatomic , assign) NSInteger                   tag;

/** 这个路径是用来存放上次取消下载时候的data 以便下次从这个路径里面取出用以断点续传的数据 */
@property (nonatomic , copy  ) NSString                    * plistFilePath;


@property (nonatomic , assign ) BOOL                        isFinished;
@property (nonatomic , assign ) BOOL                        isExecuting;

@property (nonatomic , strong ) NSURLSessionDownloadTask     * downloadTask;

@property (nonatomic , assign ) DDMDownLoadRequestTaskState downloadState;
@property (nonatomic , strong ) DDMDownloadRequestProgressDescriptor *progressModel;

@property (nonatomic, strong ,readonly ) NSError                     * error;
@end
