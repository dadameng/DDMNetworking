//
//  NSMutableString+DDMNetworkingMethods.m
//  DDMNetworking
//
//  Created by NEUSOFT on 17/6/20.
//  Copyright © 2017年 NEUSOFT. All rights reserved.
//

#import "NSMutableString+DDMNetworkingMethods.h"
#import "NSObject+DDMNetworkingMethods.h"

@implementation NSMutableString (DDMNetworkingMethods)
- (void)DDM_appendURLRequest:(NSURLRequest *)request{
    [self appendFormat:@"\n\nHTTP URL:\n\t%@", request.URL];
    [self appendFormat:@"\n\nHTTP Header:\n%@", request.allHTTPHeaderFields ? request.allHTTPHeaderFields : @"\t\t\t\t\tN/A"];
    [self appendFormat:@"\n\nHTTP Body:\n\t%@", [[[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding] DDM_defaultValue:@"\t\t\t\tN/A"]];
}
@end
