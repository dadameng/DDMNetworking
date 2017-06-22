//
//  DDMLargeFileDownloadProxy.m
//  DDMAdasPhone
//
//  Created by DDMSOFT on 17/6/22.
//  Copyright © 2017年 dadameng. All rights reserved.
//

#import "DDMLargeFileDownloadProxy.h"
#import <AFNetworking/AFNetworking.h>
#import "DDMServiceFactory.h"
#import "DDMRequestGenerator.h"

@interface DDMLargeFileDownloadProxy ()

@property (nonatomic ,copy   ) NSString             * serviceIdentifier;

@property (nonatomic ,strong ) AFHTTPSessionManager * httpDownloadSessionMgr;
@property (nonatomic ,strong ) id                     downloadSessionMgr;

@property (nonatomic ,strong ) NSURLSessionDownloadTask * downloadTask;
@property (nonatomic ,strong ) NSFileManager *fileManager;
@property (nonatomic ,strong ) NSMutableArray  * downloadingTasks;
@property (nonatomic ,strong ) NSMutableArray  * waitForDownloadTasks;
@property (nonatomic, strong ) NSMutableDictionary <NSString *, __kindof DDMDownloadRequestDescriptor *> *downloadModelsDict;
@end


@implementation DDMLargeFileDownloadProxy

@synthesize maxConcurrentDownloadCount = _maxConcurrentDownloadCount;
@synthesize downloadDirectory          = _downloadDirectory;
#pragma -setter and getter

- (AFHTTPSessionManager *)httpDownloadSessionMgr{
    
    if (_httpDownloadSessionMgr == nil) {
        _httpDownloadSessionMgr = [AFHTTPSessionManager manager];
        _httpDownloadSessionMgr.responseSerializer = [AFHTTPResponseSerializer serializer];
        _httpDownloadSessionMgr.securityPolicy.allowInvalidCertificates = YES;
        _httpDownloadSessionMgr.securityPolicy.validatesDomainName = NO;
    }
    return _httpDownloadSessionMgr;
    
    
}
#pragma mark - life cycle

- (instancetype)initWithServiceIdentifier:(NSString *)serviceIdentifier{
    
    self = [super init];
    if (self) {
        
        DDMService * service = [[DDMServiceFactory sharedInstance] serviceWithIdentifier:serviceIdentifier];
        
        self.serviceIdentifier = serviceIdentifier;
        
        if ([service.child respondsToSelector:@selector(sessionManager)]) {
            if ([[service.child sessionManager] respondsToSelector:@selector(downloadTaskWithRequest:progress:destination:completionHandler:)]) {
                self.downloadSessionMgr = [service.child sessionManager];
            }else{
                NSAssert(NO, @"Your session manager must have 'downloadTaskWithRequest:progress:destination:completionHandler:' method");
            }
        }
        
        self.downloadSessionMgr = self.downloadSessionMgr ? : self.httpDownloadSessionMgr;
        
        NSString * path;
        if ([service.child respondsToSelector:@selector(downloadManagerPlistPath)]) {
            path = [service.child downloadManagerPlistPath];
        }
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        
        path =  path ? : [paths lastObject];
        
        _downloadDirectory          = path;
        
        NSInteger maxConcurrentDownloadCount ;
        if ([service.child respondsToSelector:@selector(maxConcurrentDownloadCount)]) {
            maxConcurrentDownloadCount = [service.child maxConcurrentDownloadCount];
        }
        
        
        _maxConcurrentDownloadCount = maxConcurrentDownloadCount ? : 10;
        
        _fileManager                = [NSFileManager defaultManager];
        _waitForDownloadTasks       = [NSMutableArray array];
        _downloadingTasks           = [NSMutableArray array];
        _downloadModelsDict         = [[NSMutableDictionary alloc] initWithCapacity:1];
        
        [self createFolderAtPath:_downloadDirectory];
        
        NSDictionary <NSString *, NSString *> *plistDict = [[NSDictionary alloc] init];
        NSString *managerPlistFilePath = [_downloadDirectory stringByAppendingPathComponent:@"DDMLargeFileDownloadManager.plist"];
        [plistDict writeToFile:managerPlistFilePath atomically:YES];
        
    }
    return self;
}
#pragma mark - public methods
-(void)startDownloadWithDownloadModel:(DDMDownloadRequestDescriptor *)downloadModel
                             progress:(void (^)(DDMDownloadRequestDescriptor * _Nonnull downloadingTask))progress
                    completionHandler:(void (^)(DDMDownloadRequestDescriptor * _Nonnull downloadedTask, NSError * _Nullable error))completionHandler{
    
    if (![self canBeStartDownloadTaskWithDownloadModel:downloadModel]){
        
        if (![self.waitForDownloadTasks containsObject:downloadModel]) {
            downloadModel.downloadState = DDMDownLoadRequestTaskWillDownload;
            [self.waitForDownloadTasks addObject:downloadModel];
        }
        return;
    }
    [self createFolderAtPath:[downloadModel.fileDestinationURL stringByDeletingLastPathComponent]];
    
    downloadModel.resumeData = [NSData dataWithContentsOfFile:downloadModel.plistFilePath];
    downloadModel.downloadState = DDMDownLoadRequestTaskDownloading;

    
    if (downloadModel.resumeData.length == 0) {
        
        if (!downloadModel.resourceURLString && !( downloadModel.methodName && downloadModel.parmDic)) {
            NSAssert(NO, @"DownloadModel must have either resourceURLString or methodName & parmDic ");
            return;
        }
        NSURLRequest * downloadRequest;
        if (downloadModel.resourceURLString) {
            downloadRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:downloadModel.resourceURLString]];
        }else{
            downloadRequest = [[DDMRequestGenerator sharedInstance] generateGETRequestWithServiceIdentifier:self.serviceIdentifier requestParams:downloadModel.parmDic methodName:downloadModel.methodName];
        }
        
        downloadModel.downloadTask =     [self.httpDownloadSessionMgr downloadTaskWithRequest:downloadRequest progress:^(NSProgress * _Nonnull downloadProgress) {
            [self setValuesForDownloadModel:downloadModel withProgress:downloadProgress.fractionCompleted];
            progress ? progress(downloadModel) : nil;
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [NSURL URLWithString:downloadModel.fileDestinationURL];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            if (error) {
                [self cancelDownloadTaskWithDownloadModel:downloadModel];
                completionHandler(downloadModel, error);
                
            }else{
                [self.downloadingTasks removeObject:downloadModel];
                [self.downloadModelsDict removeObjectForKey:downloadModel.resourceURLString];
                downloadModel.downloadState = DDMDownLoadRequestTaskFinishedDownload;
                
                completionHandler(downloadModel, nil);
                [self deletePlistFileWithDownloadModel:downloadModel];
            }
        }];
        
        
    }else{
        
        downloadModel.progressModel.totalBytesWritten = [self getResumeByteWithDownloadModel:downloadModel];
        
        downloadModel.downloadTask = [self.downloadSessionMgr downloadTaskWithResumeData:downloadModel.resumeData progress:^(NSProgress * _Nonnull downloadProgress) {
            [self setValuesForDownloadModel:downloadModel withProgress:[self.downloadSessionMgr downloadProgressForTask:downloadModel.downloadTask].fractionCompleted];
            progress ? progress(downloadModel) : nil;
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [NSURL URLWithString:downloadModel.fileDestinationURL];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            if (error) {
                [self cancelDownloadTaskWithDownloadModel:downloadModel];
                completionHandler(downloadModel, error);
            }else{
                [self.downloadingTasks removeObject:downloadModel];
                [self.downloadModelsDict removeObjectForKey:downloadModel.resourceURLString];
                downloadModel.downloadState = DDMDownLoadRequestTaskFinishedDownload;
                
                completionHandler(downloadModel, nil);
                [self deletePlistFileWithDownloadModel:downloadModel];
            }

        }];

    }
    
    [self resumeDownloadWithDownloadModel:downloadModel];
}


-(void)cancelDownloadTaskWithDownloadModel:(DDMDownloadRequestDescriptor *)downloadModel{
    if (!downloadModel) return;
    NSURLSessionTaskState state = downloadModel.downloadTask.state;
    if (state == NSURLSessionTaskStateRunning) {
        [downloadModel.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            downloadModel.resumeData = resumeData;
            downloadModel.downloadState = DDMDownLoadRequestTaskSuspened;
            @synchronized (self) {
                BOOL isSuc = [downloadModel.resumeData writeToFile:downloadModel.plistFilePath atomically:YES];
                [self saveTotalBytesExpectedToWriteWithDownloadModel:downloadModel];
                if (isSuc) {
                    downloadModel.resumeData = nil;
                    [self.downloadModelsDict removeObjectForKey:downloadModel.resourceURLString];
                    [self.downloadingTasks removeObject:downloadModel];
                    [self.waitForDownloadTasks removeObject:downloadModel];
                }
            }
        }];
    }else if (state ==NSURLSessionTaskStateCompleted){
        
    }
}

-(void)deleteDownloadedFileWithDownloadModel:(DDMDownloadRequestDescriptor *)downloadModel{
    if ([self.fileManager fileExistsAtPath:downloadModel.fileDestinationURL]) {
        [self.fileManager removeItemAtPath:downloadModel.fileDestinationURL error:nil];
    }
}

-(DDMDownloadRequestDescriptor *)getDownloadingModelWithURLString:(NSString *)URLString{
    return self.downloadModelsDict[URLString];
}

-(DDMDownloadRequestProgressDescriptor *)getDownloadProgressModelWithDownloadModel:(DDMDownloadRequestDescriptor *)downloadModel{
    DDMDownloadRequestProgressDescriptor *progressModel = downloadModel.progressModel;
    progressModel.downloadProgress = [self.downloadSessionMgr downloadProgressForTask:downloadModel.downloadTask].fractionCompleted;
    return progressModel;
}

#pragma mark - private methods

-(void)deleteAllDownloadedFiles{
    if ([self.fileManager fileExistsAtPath:self.downloadDirectory]) {
        [self.fileManager removeItemAtPath:self.downloadDirectory error:nil];
    }
}

-(BOOL)hasDownloadedFileWithDownloadModel:(DDMDownloadRequestDescriptor *)downloadModel{
    if ([self.fileManager fileExistsAtPath:[downloadModel.fileDestinationURL stringByAppendingPathComponent:downloadModel.fileName]]) {
        NSLog(@"已下载的文件...");
        return YES;
    }
    return NO;
}
-(void)resumeDownloadWithDownloadModel:(DDMDownloadRequestDescriptor *)downloadModel{
    if (downloadModel.downloadTask) {
        downloadModel.downloadDate = [NSDate date];
        [downloadModel.downloadTask resume];
        self.downloadModelsDict[downloadModel.resourceURLString] = downloadModel;
        [self.downloadingTasks addObject:downloadModel];
    }
}

-(BOOL)canBeStartDownloadTaskWithDownloadModel:(DDMDownloadRequestDescriptor *)downloadModel{
    if (!downloadModel){
        return NO;
    }
    if (downloadModel.downloadTask && downloadModel.downloadTask.state == NSURLSessionTaskStateRunning){
        return NO;
    }
    if ([self hasDownloadedFileWithDownloadModel:downloadModel]){
        return NO;
    }
    if (_downloadingTasks.count >= self.maxConcurrentDownloadCount) {
        return NO;
    }
    
    return YES;
}

-(void)setValuesForDownloadModel:(DDMDownloadRequestDescriptor *)downloadModel withProgress:(double)progress{
    NSTimeInterval interval = -1 * [downloadModel.downloadDate timeIntervalSinceNow];
    downloadModel.progressModel.totalBytesWritten = downloadModel.downloadTask.countOfBytesReceived;
    downloadModel.progressModel.totalBytesExpectedToWrite = downloadModel.downloadTask.countOfBytesExpectedToReceive;
    downloadModel.progressModel.downloadProgress = progress;
    downloadModel.progressModel.downloadSpeed = (int64_t)((downloadModel.progressModel.totalBytesWritten - [self getResumeByteWithDownloadModel:downloadModel]) / interval);
    if (downloadModel.progressModel.downloadSpeed != 0) {
        int64_t remainingContentLength = downloadModel.progressModel.totalBytesExpectedToWrite  - downloadModel.progressModel.totalBytesWritten;
        int currentLeftTime = (int)(remainingContentLength / downloadModel.progressModel.downloadSpeed);
        downloadModel.progressModel.downloadRemainingTime = currentLeftTime;
    }
}

-(int64_t)getResumeByteWithDownloadModel:(DDMDownloadRequestDescriptor *)downloadModel{
    int64_t resumeBytes = 0;
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:downloadModel.plistFilePath];
    if (dict) {
        resumeBytes = [dict[@"NSURLSessionResumeBytesReceived"] longLongValue];
    }
    return resumeBytes;
}

-(NSString *)getTmpFileNameWithDownloadModel:(DDMDownloadRequestDescriptor *)downloadModel{
    NSString *fileName = nil;
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:downloadModel.plistFilePath];
    if (dict) {
        fileName = dict[@"NSURLSessionResumeInfoTempFileName"];
    }
    return fileName;
}

-(void)createFolderAtPath:(NSString *)path{
    if ([self.fileManager fileExistsAtPath:path]) return;
    [self.fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
}

-(void)deletePlistFileWithDownloadModel:(DDMDownloadRequestDescriptor *)downloadModel{
    if (downloadModel.downloadTask.countOfBytesReceived == downloadModel.downloadTask.countOfBytesExpectedToReceive) {
        NSError *error;
        
        [self.fileManager removeItemAtPath:downloadModel.plistFilePath error:&error];
        [self removeTotalBytesExpectedToWriteWhenDownloadFinishedWithDownloadModel:downloadModel];
    }
}

-(NSString *)managerPlistFilePath{
    return [_downloadDirectory stringByAppendingPathComponent:@"DDMLargeFileDownloadManager.plist"];
}

-(nullable NSMutableDictionary <NSString *, NSString *> *)managerPlistDict{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:[self managerPlistFilePath]];
    return dict;
}

-(void)saveTotalBytesExpectedToWriteWithDownloadModel:(DDMDownloadRequestDescriptor *)downloadModel{
    NSMutableDictionary <NSString *, NSString *> *dict = [self managerPlistDict];
    [dict setValue:[NSString stringWithFormat:@"%lld", downloadModel.downloadTask.countOfBytesExpectedToReceive] forKey:downloadModel.resourceURLString];
    [dict writeToFile:[self managerPlistFilePath] atomically:YES];
}

-(void)removeTotalBytesExpectedToWriteWhenDownloadFinishedWithDownloadModel:(DDMDownloadRequestDescriptor *)downloadModel{
    NSMutableDictionary <NSString *, NSString *> *dict = [self managerPlistDict];
    [dict removeObjectForKey:downloadModel.resourceURLString];
    [dict writeToFile:[self managerPlistFilePath] atomically:YES];
}




@end
