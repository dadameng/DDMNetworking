//
//  DDMAPIBaseManager.h
//  DDMNetworking
//
//  Created by NEUSOFT on 17/6/20.
//  Copyright © 2017年 NEUSOFT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDMURLResponse.h"

@class DDMAPIBaseManager;

// 在调用成功之后的params字典里面，用这个key可以取出requestID
static NSString * const kDDMAPIBaseManagerRequestID = @"kDDMAPIBaseManagerRequestID";




/*
 总述：
 这个base manager是用于给外部访问API的时候做的一个基类。任何继承这个基类的manager都要添加两个getter方法：
 
 - (NSString *)methodName
 {
 return @"community.searchMap";
 }
 
 - (RTServiceType)serviceType
 {
 return RTcasatwyServiceID;
 }
 
 外界在使用manager的时候，如果需要调api，只要调用loadData即可。manager会去找paramSource来获得调用api的参数。调用成功或失败，则会调用delegate的回调函数。
 
 继承的子类manager可以重载basemanager提供的一些方法，来实现一些扩展功能。具体的可以看m文件里面对应方法的注释。
 */







/*************************************************************************************************/
/*                               DDMAPIManagerApiCallBackDelegate                                 */
/*************************************************************************************************/

//api回调
@protocol DDMAPIManagerCallBackDelegate <NSObject>
@required
- (void)managerCallAPIDidSuccess:(DDMAPIBaseManager *)manager;
- (void)managerCallAPIDidFailed:(DDMAPIBaseManager *)manager;
@optional
- (void)managerCallApiUploadProgress:(NSProgress *)uploadProgress manager:(DDMAPIBaseManager *)manager;

@end


@protocol DDMAPIManagerDataReformer <NSObject>
@required

- (id)manager:(DDMAPIBaseManager *)manager reformData:(NSDictionary *)data;
@end





/*************************************************************************************************/
/*                                     DDMAPIManagerValidator                                     */
/*************************************************************************************************/
//验证器，用于验证API的返回或者调用API的参数是否正确
/*
 使用场景：
 当我们确认一个api是否真正调用成功时，要看的不光是status，还有具体的数据内容是否为空。由于每个api中的内容对应的key都不一定一样，甚至于其数据结构也不一定一样，因此对每一个api的返回数据做判断是必要的，但又是难以组织的。
 为了解决这个问题，manager有一个自己的validator来做这些事情，一般情况下，manager的validator可以就是manager自身。
 
 1.有的时候可能多个api返回的数据内容的格式是一样的，那么他们就可以共用一个validator。
 2.有的时候api有修改，并导致了返回数据的改变。在以前要针对这个改变的数据来做验证，是需要在每一个接收api回调的地方都修改一下的。但是现在就可以只要在一个地方修改判断逻辑就可以了。
 3.有一种情况是manager调用api时使用的参数不一定是明文传递的，有可能是从某个变量或者跨越了好多层的对象中来获得参数，那么在调用api的最后一关会有一个参数验证，当参数不对时不访问api，同时自身的errorType将会变为DDMAPIManagerErrorTypeParamsError。这个机制可以优化我们的app。
 
 william补充（2013-12-6）：
 4.特殊场景：租房发房，用户会被要求填很多参数，这些参数都有一定的规则，比如邮箱地址或是手机号码等等，我们可以在validator里判断邮箱或者电话是否符合规则，比如描述是否超过十个字。从而manager在调用API之前可以验证这些参数，通过manager的回调函数告知上层controller。避免无效的API请求。加快响应速度，也可以多个manager共用.
 */
@protocol DDMAPIManagerValidator <NSObject>
@required
/*
 所有的callback数据都应该在这个函数里面进行检查，事实上，到了回调delegate的函数里面是不需要再额外验证返回数据是否为空的。
 因为判断逻辑都在这里做掉了。
 而且本来判断返回数据是否正确的逻辑就应该交给manager去做，不要放到回调到controller的delegate方法里面去做。
 */
- (BOOL)manager:(DDMAPIBaseManager *)manager isCorrectWithCallBackData:(NSDictionary *)data;

/*
 
 “
 william补充（2013-12-6）：
 4.特殊场景：租房发房，用户会被要求填很多参数，这些参数都有一定的规则，比如邮箱地址或是手机号码等等，我们可以在validator里判断邮箱或者电话是否符合规则，比如描述是否超过十个字。从而manager在调用API之前可以验证这些参数，通过manager的回调函数告知上层controller。避免无效的API请求。加快响应速度，也可以多个manager共用.
 ”
 
 所以不要以为这个params验证不重要。当调用API的参数是来自用户输入的时候，验证是很必要的。
 当调用API的参数不是来自用户输入的时候，这个方法可以写成直接返回true。反正哪天要真是参数错误，QA那一关肯定过不掉。
 不过我还是建议认真写完这个参数验证，这样能够省去将来代码维护者很多的时间。
 
 */
- (BOOL)manager:(DDMAPIBaseManager *)manager isCorrectWithParamsData:(NSDictionary *)data;
@end





/*************************************************************************************************/
/*                                DDMAPIManagerParamSourceDelegate                                */
/*************************************************************************************************/
//让manager能够获取调用API所需要的数据
@protocol DDMAPIManagerParamSource <NSObject>
@required
- (NSDictionary *)paramsForApi:(DDMAPIBaseManager *)manager;

@optional
- (NSDictionary *)uploadParamsForApi:(DDMAPIBaseManager *)manager;


@end

/*
 当产品要求返回数据不正确或者为空的时候显示一套UI，请求超时和网络不通的时候显示另一套UI时，使用这个enum来决定使用哪种UI。（安居客PAD就有这样的需求，sigh～）
 你不应该在回调数据验证函数里面设置这些值，事实上，在任何派生的子类里面你都不应该自己设置manager的这个状态，baseManager已经帮你搞定了。
 强行修改manager的这个状态有可能会造成程序流程的改变，容易造成混乱。
 */
typedef NS_ENUM (NSUInteger, DDMAPIManagerErrorType){
    DDMAPIManagerErrorTypeDefault,       //没有产生过API请求，这个是manager的默认状态。
    DDMAPIManagerErrorTypeSuccess,       //API请求成功且返回数据正确，此时manager的数据是可以直接拿来使用的。
    DDMAPIManagerErrorTypeNoContent,     //API请求成功但返回数据不正确。如果回调数据验证函数返回值为NO，manager的状态就会是这个。
    DDMAPIManagerErrorTypeParamsError,   //参数错误，此时manager不会调用API，因为参数验证是在调用API之前做的。
    DDMAPIManagerErrorTypeTimeout,       //请求超时。DDMAPIProxy设置的是20秒超时，具体超时时间的设置请自己去看DDMAPIProxy的相关代码。
    DDMAPIManagerErrorTypeNoNetWork      //网络不通。在调用API之前会判断一下当前网络是否通畅，这个也是在调用API之前验证的，和上面超时的状态是有区别的。
};

typedef NS_ENUM (NSUInteger, DDMAPIManagerRequestType){
    DDMAPIManagerRequestTypeGet,
    DDMAPIManagerRequestTypePost,
    DDMAPIManagerRequestTypePut,
    DDMAPIManagerRequestTypeDelete,
    DDMAPIManagerRequestTypeUpload
};






/*************************************************************************************************/
/*                                         DDMAPIManager                                          */
/*************************************************************************************************/
/*
 DDMAPIBaseManager的派生类必须符合这些protocal
 */
@protocol DDMAPIManager <NSObject>

@required
- (NSString *)methodName;
- (NSString *)serviceType;
- (DDMAPIManagerRequestType)requestType;
- (BOOL)shouldCache;

// used for pagable API Managers mainly
@optional
- (void)cleanData;
- (NSDictionary *)reformParams:(NSDictionary *)params;
- (NSInteger)loadDataWithParams:(NSDictionary *)params;
- (BOOL)shouldLoadFromNative;


@end






/*************************************************************************************************/
/*                                    DDMAPIManagerInterceptor                                    */
/*************************************************************************************************/
/*
 DDMAPIBaseManager的派生类必须符合这些protocal
 */
@protocol DDMAPIManagerInterceptor <NSObject>

@optional
- (BOOL)manager:(DDMAPIBaseManager *)manager beforePerformSuccessWithResponse:(DDMURLResponse *)response;
- (void)manager:(DDMAPIBaseManager *)manager afterPerformSuccessWithResponse:(DDMURLResponse *)response;

- (BOOL)manager:(DDMAPIBaseManager *)manager beforePerformFailWithResponse:(DDMURLResponse *)response;
- (void)manager:(DDMAPIBaseManager *)manager afterPerformFailWithResponse:(DDMURLResponse *)response;

- (BOOL)manager:(DDMAPIBaseManager *)manager shouldCallAPIWithParams:(NSDictionary *)params;
- (void)manager:(DDMAPIBaseManager *)manager afterCallingAPIWithParams:(NSDictionary *)params;

@end




/*************************************************************************************************/
/*                                       DDMAPIBaseManager                                        */
/*************************************************************************************************/
@interface DDMAPIBaseManager : NSObject

@property (nonatomic, weak) id<DDMAPIManagerCallBackDelegate> delegate;
@property (nonatomic, weak) id<DDMAPIManagerParamSource> paramSource;
@property (nonatomic, weak) id<DDMAPIManagerValidator> validator;
@property (nonatomic, weak) NSObject<DDMAPIManager> *child; //里面会调用到NSObject的方法，所以这里不用id
@property (nonatomic, weak) id<DDMAPIManagerInterceptor> interceptor;

/*
 baseManager是不会去设置errorMessage的，派生的子类manager可能需要给controller提供错误信息。所以为了统一外部调用的入口，设置了这个变量。
 派生的子类需要通过extension来在保证errorMessage在对外只读的情况下使派生的manager子类对errorMessage具有写权限。
 */
@property (nonatomic, copy, readonly) NSString *errorMessage;
@property (nonatomic, readonly) DDMAPIManagerErrorType errorType;
@property (nonatomic, strong) DDMURLResponse *response;

@property (nonatomic, assign, readonly) BOOL isReachable;
@property (nonatomic, assign, readonly) BOOL isLoading;

- (id)fetchDataWithReformer:(id<DDMAPIManagerDataReformer>)reformer;

//尽量使用loadData这个方法,这个方法会通过param source来获得参数，这使得参数的生成逻辑位于controller中的固定位置
- (NSInteger)loadData;

- (void)cancelAllRequests;
- (void)cancelRequestWithRequestId:(NSInteger)requestID;

// 拦截器方法，继承之后需要调用一下super
- (BOOL)beforePerformSuccessWithResponse:(DDMURLResponse *)response;
- (void)afterPerformSuccessWithResponse:(DDMURLResponse *)response;

- (BOOL)beforePerformFailWithResponse:(DDMURLResponse *)response;
- (void)afterPerformFailWithResponse:(DDMURLResponse *)response;

- (BOOL)shouldCallAPIWithParams:(NSDictionary *)params;
- (void)afterCallingAPIWithParams:(NSDictionary *)params;

/*
 用于给继承的类做重载，在调用API之前额外添加一些参数,但不应该在这个函数里面修改已有的参数。
 子类中覆盖这个函数的时候就不需要调用[super reformParams:params]了
 DDMAPIBaseManager会先调用这个函数，然后才会调用到 id<DDMAPIManagerValidator> 中的 manager:isCorrectWithParamsData:
 所以这里返回的参数字典还是会被后面的验证函数去验证的。
 
 假设同一个翻页Manager，ManagerA的paramSource提供page_size=15参数，ManagerB的paramSource提供page_size=2参数
 如果在这个函数里面将page_size改成10，那么最终调用API的时候，page_size就变成10了。然而外面却觉察不到这一点，因此这个函数要慎用。
 
 这个函数的适用场景：
 当两类数据走的是同一个API时，为了避免不必要的判断，我们将这一个API当作两个API来处理。
 那么在传递参数要求不同的返回时，可以在这里给返回参数指定类型。
 
 具体请参考AJKHDXFLoupanCategoryRecommendSamePriceAPIManager和AJKHDXFLoupanCategoryRecommendSameAreaAPIManager
 
 */
- (NSDictionary *)reformParams:(NSDictionary *)params;
- (void)cleanData;
- (BOOL)shouldCache;

- (void)successedOnCallingAPI:(DDMURLResponse *)response;
- (void)failedOnCallingAPI:(DDMURLResponse *)response withErrorType:(DDMAPIManagerErrorType)errorType;

@end
