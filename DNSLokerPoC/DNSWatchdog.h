//
//  DNSWatchdog.h
//  DNSLokerPoC
//
//  Created by Dmitry Rodionov on 2/28/16.
//  Copyright © 2016 Internals Exposed. All rights reserved.
//

@import Foundation;
@import SystemConfiguration;

@interface DNSWatchdog : NSObject
@property (readonly, copy) NSArray *initialResolvers;

+ (instancetype)defaultWatchdog;

- (void)startWatching;
- (void)stopWatching;
@end
