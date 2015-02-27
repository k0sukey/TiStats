/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2015年 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiRootViewController+Stats.h"
#import "TiDebugger.h"
#import <mach/mach.h>
#import <objc/runtime.h>

#define kTimerInterval 1.0
#define tval2msec(tval) ((tval.seconds * 1000) + (tval.microseconds / 1000))

@implementation TiRootViewController (Stats)

-(void)setLastUserTime:(uint64_t)lastUserTime
{
    objc_setAssociatedObject(self, @selector(lastUserTime), lastUserTime, OBJC_ASSOCIATION_ASSIGN);
}

-(uint64_t)lastUserTime
{
    return objc_getAssociatedObject(self, @selector(lastUserTime));
}

-(void)setLastSystemTime:(uint64_t)lastSystemTime
{
    objc_setAssociatedObject(self, @selector(lastSystemTime), lastSystemTime, OBJC_ASSOCIATION_ASSIGN);
}

-(uint64_t)lastSystemTime
{
    return objc_getAssociatedObject(self, @selector(lastSystemTime));
}

-(void)setLastRss:(vm_size_t)lastRss
{
    objc_setAssociatedObject(self, @selector(lastRss), lastRss, OBJC_ASSOCIATION_ASSIGN);
}

-(vm_size_t)lastRss
{
    return objc_getAssociatedObject(self, @selector(lastRss));
}

-(void)setLastVs:(vm_size_t)lastVs
{
    objc_setAssociatedObject(self, @selector(lastVs), lastVs, OBJC_ASSOCIATION_ASSIGN);
}

-(vm_size_t)lastVs
{
    return objc_getAssociatedObject(self, @selector(lastVs));
}


-(id)init
{
    self = [super init];
    
    if (self != nil)
    {
        self.lastUserTime = 0;
        self.lastSystemTime = 0;
        self.lastRss = 0;
        self.lastVs = 0;
        
        NSTimer *timer = [NSTimer timerWithTimeInterval:kTimerInterval
                                                 target:self
                                               selector:@selector(timerHandler:)
                                               userInfo:nil
                                                repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    }
    
    return self;
}

-(int)getSubviewsInView:(UIView *)view
{
    int count = 0;
    
    for (UIView *subview in [view subviews])
    {
        count++;
        
        if ([[subview subviews] count] > 0)
        {
            count += [self getSubviewsInView:subview];
        }
    }
    
    return count;
}

-(int)getSubviewsInApp
{
    int count = 0;
    NSArray *windows = [[UIApplication sharedApplication] windows];
    
    for (UIWindow *theWindow in windows)
    {
        for (UIView *view in [theWindow subviews])
        {
            count++;
            count += [self getSubviewsInView:view];
        }
    }
    
    return count;
}

-(void)timerHandler:(NSTimer *)timer
{
    if ([[TiApp app] debugMode] == NO)
    {
        return;
    }
    
    struct task_basic_info t_info;
    mach_msg_type_number_t t_info_count = TASK_BASIC_INFO_COUNT;
    
    if (task_info(current_task(), TASK_BASIC_INFO, (task_info_t)&t_info, &t_info_count) != KERN_SUCCESS)
    {
        TiDebuggerLogMessage(OUT, @"__TISTATS__/0/0/0/0/0/0/0/0");
        return;
    }
    
    vm_size_t rss = t_info.resident_size;
    vm_size_t vs = t_info.virtual_size;
    
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t pagesize;
    host_page_size(host_port, &pagesize);
    vm_statistics_data_t vm_stat;
    
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
    {
        TiDebuggerLogMessage(OUT, @"__TISTATS__/0/0/0/0/0/0/0/0");
        return;
    }
    
    natural_t freeMemory = vm_stat.free_count * pagesize;
    
    struct task_thread_times_info tti;
    t_info_count = TASK_THREAD_TIMES_INFO_COUNT;
    kern_return_t status = task_info(current_task(), TASK_THREAD_TIMES_INFO,
                                     (task_info_t)&tti, &t_info_count);
    
    if (status != KERN_SUCCESS)
    {
        TiDebuggerLogMessage(OUT, @"__TISTATS__/0/0/0/0/0/0/0/0");
        return;
    }
    
    int64_t rssPerSec = ((int64_t)rss - self.lastRss) / kTimerInterval;
    self.lastRss = rss;
    
    int64_t vsPerSec = ((int64_t)vs - self.lastVs) / kTimerInterval;
    self.lastVs = vs;
    
    uint64_t userTime   = tval2msec(tti.user_time);
    int64_t userTimePerSec = ((int64_t)userTime - self.lastUserTime) / kTimerInterval;
    self.lastUserTime = userTime;

    uint64_t systemTime   = tval2msec(tti.system_time);
    int64_t systemTimePerSec = ((int64_t)systemTime - self.lastSystemTime) / kTimerInterval;
    self.lastSystemTime = systemTime;
    
    TiDebuggerLogMessage(OUT, [NSString stringWithFormat:@"__TISTATS__/%d/%u/%qi/%lu/%qi/%lu/%qi/%qi",
                               [self getSubviewsInApp],
                               (unsigned int)freeMemory,
                               rssPerSec,
                               rss,
                               vsPerSec,
                               vs,
                               userTimePerSec,
                               systemTimePerSec]);
}

@end
