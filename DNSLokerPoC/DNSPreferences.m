//
//  DNSPreferences.m
//  DNSLokerPoC
//
//  Created by Dmitry Rodionov on 2/28/16.
//  Copyright © 2016 Internals Exposed. All rights reserved.
//

#import "DNSPreferences.h"

@implementation DNSPreferences

+ (NSArray *)fetchResolversFromStore: (SCDynamicStoreRef)store
{
    CFDictionaryRef propertyRef = SCDynamicStoreCopyValue(store, CFSTR("State:/Network/Global/DNS"));
    return CFDictionaryGetValue(propertyRef, CFSTR("ServerAddresses"));
}

+ (void)setResolvers: (NSArray *)resolvers
{
    [self enumerateServicesWithDNSSupportUsingBlock: ^(SCNetworkServiceRef service) {
        [self setResolvers: resolvers forNetworkService: service];
    }];
}

#pragma mark - 

+ (void)setResolvers: (NSArray *)resolvers forNetworkService: (SCNetworkServiceRef)service
{
    SCNetworkProtocolRef protocol = SCNetworkServiceCopyProtocol(service, kSCNetworkProtocolTypeDNS);
    NSDictionary *configuration = (__bridge NSDictionary *) SCNetworkProtocolGetConfiguration(protocol);
    if (configuration.count == 0) {
        configuration = @{(__bridge NSString *)kSCPropNetDNSServerAddresses: resolvers};
    } else {
        /// TODO:
        // An empty DNS servers list or an empty IP/network address means that DHCP will be used in order to retrieve this information. But this doesn't happen automatically as the new settings are applied. Explicitly renewing the DHCP lease is required, by calling SCNetworkInterfaceForceConfigurationRefresh() on each interface
        NSMutableDictionary *newConfiguration = [NSMutableDictionary dictionaryWithDictionary: configuration];
        [newConfiguration setObject: resolvers forKey: (__bridge NSString *)kSCPropNetDNSServerAddresses];
        configuration = [newConfiguration copy];
    }
    SCNetworkProtocolSetConfiguration(protocol, (__bridge CFDictionaryRef)configuration);
}

+ (void)enumerateServicesWithDNSSupportUsingBlock: (void (^)(SCNetworkServiceRef))block
{
    SCPreferencesRef preferences = SCPreferencesCreate(kCFAllocatorDefault, CFSTR("exposed.internals.DNSPreferences.Preferences"), NULL);
    // Since we're modifing system-wise preferences we should acquire a lock so nothing will be messed up
    SCPreferencesLock(preferences, true);

    SCNetworkSetRef networkSet = SCNetworkSetCopyCurrent(preferences);
    NSArray *services = CFBridgingRelease(SCNetworkSetCopyServices(networkSet));
    [services enumerateObjectsUsingBlock: ^(id item, NSUInteger idx, BOOL *stop) {
        SCNetworkServiceRef service = (__bridge SCNetworkServiceRef)(item);
        if ([self serviceSupportsDNS: service]) {
            block(service);
        }
    }];

    SCPreferencesUnlock(preferences);
    SCPreferencesCommitChanges(preferences);
    SCPreferencesApplyChanges(preferences);
    [self dynamicStoreHackToPickupChanges];
}

#pragma mark - Helpers

+ (BOOL)serviceSupportsDNS: (SCNetworkServiceRef)service
{
    if (!SCNetworkServiceGetEnabled(service)) {
        return NO;
    }
    SCNetworkInterfaceRef interface = SCNetworkServiceGetInterface(service);
    if (!interface) {
        return NO;
    }
    NSArray *supportedProtocols = (__bridge NSArray *)SCNetworkInterfaceGetSupportedProtocolTypes(interface);
    if (![supportedProtocols containsObject: (__bridge NSString *)kSCNetworkProtocolTypeDNS]) {
        return NO;
    }
    SCNetworkProtocolRef dnsProtocol = SCNetworkServiceCopyProtocol(service, kSCNetworkProtocolTypeDNS);
    return SCNetworkProtocolGetEnabled(dnsProtocol);
}

 + (void)dynamicStoreHackToPickupChanges
{
    SCDynamicStoreRef store = SCDynamicStoreCreate(NULL, CFSTR("please-pickup-my-changes"), NULL, NULL);
    CFRelease(store);
}

@end
