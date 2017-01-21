//
//  DNSWatchdog.m
//  DNSLokerPoC
//
//  Created by Dmitry Rodionov on 2/28/16.
//  Copyright © 2016 Internals Exposed. All rights reserved.
//

#import "DNSWatchdog.h"
#import "DNSPreferences.h"

@interface DNSWatchdog()
{
    SCDynamicStoreRef _store;
    dispatch_queue_t _dispatchQueue;
}
@property (readwrite, copy) NSArray *initialResolvers;

- (void)rollbackToInitialResolversFrom: (NSArray *)newResolvers;
@end

#pragma mark - System Configuration Store Callback

void SCDynamicStoreDNSChangesCallback(SCDynamicStoreRef ds, __unused CFArrayRef keys, void *info)
{
    NSArray *newResolvers = [DNSPreferences fetchResolversFromStore: ds];
    DNSWatchdog *watchdog = (__bridge DNSWatchdog *)info;
    [watchdog rollbackToInitialResolversFrom: newResolvers];
}

const void *retainObjectiveCContext(const void *info)
{
    return (void *)CFBridgingRetain((__bridge id)(info));
}

void releaseObjectiveCContext(const void *info)
{
    CFBridgingRelease(info);
}

#pragma mark -

@implementation DNSWatchdog

+ (instancetype)defaultWatchdog
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if ((self = [super init])) {
        // Create a dynamic store
        SCDynamicStoreContext context = {
            .info    = (__bridge void *)self,
            .release = releaseObjectiveCContext,
            .retain  = retainObjectiveCContext
        };
        _store = SCDynamicStoreCreate(NULL, CFSTR("DNSWatchdog"), SCDynamicStoreDNSChangesCallback, &context);
        // Fetch current DNS resolvers -- they will be our "initial" ones
        _initialResolvers = [DNSPreferences fetchResolversFromStore: _store];
        // Make sure updates will be delivered on our custom queue
        _dispatchQueue = dispatch_queue_create("DNSWatchdog-notification-queue", DISPATCH_QUEUE_SERIAL);
        SCDynamicStoreSetDispatchQueue(_store, _dispatchQueue);
    }
    return self;
}

#pragma mark - Public interface

- (void)startWatching
{
    // Subscribe to system-wise DNS update events
    BOOL ready = SCDynamicStoreSetNotificationKeys(_store, (CFArrayRef)@[@"State:/Network/Global/DNS"], NULL);
    NSAssert(ready, @"Could not subscribe to DNS updates");
}

- (void)stopWatching
{
    // Unsubscribe from system-wise DNS update events
    BOOL stopped = SCDynamicStoreSetNotificationKeys(_store, NULL, NULL);
    NSAssert(stopped, @"Could not unsubscribe from DNS updates");
}

#pragma mark - Implementation details

- (void)rollbackToInitialResolversFrom: (NSArray *)newResolvers
{
    if ([self.initialResolvers isEqualToArray: newResolvers]) {
        return;
    }
    [DNSPreferences setResolvers: self.initialResolvers];
}

@end
