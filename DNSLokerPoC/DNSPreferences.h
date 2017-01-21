//
//  DNSPreferences.h
//  DNSLokerPoC
//
//  Created by Dmitry Rodionov on 2/28/16.
//  Copyright © 2016 Internals Exposed. All rights reserved.
//

@import Foundation;
@import SystemConfiguration;

@interface DNSPreferences : NSObject

/// Fetches ServerAddresses from /Network/Global/DNS
+ (NSArray *)fetchResolversFromStore: (SCDynamicStoreRef)store;
/// Sets DNS resolvers globally
+ (void)setResolvers: (NSArray *)resolvers;
@end
