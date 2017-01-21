//
//  main.m
//  DNSLoсkerPoC
//
//  Created by Dmitry Rodionov on 2/1/16.
//  Copyright © 2016 Internals Exposed. All rights reserved.
//

@import Foundation;
@import SystemConfiguration;
#import "DNSWatchdog.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [[DNSWatchdog defaultWatchdog] startWatching];
        // XXX: we only need this in a command-line tool
        dispatch_main();
    }
    return 0;
}
