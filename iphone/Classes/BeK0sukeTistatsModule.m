/**
 * TiStats
 *
 * Created by Kosuke Isobe
 * Copyright (c) 2015 Your Company. All rights reserved.
 */

#import "BeK0sukeTistatsModule.h"
#import "TiApp.h"
#import "TiBase.h"
#import "TiDebugger.h"
#import "TiHost.h"
#import "TiUtils.h"
#import <mach/mach.h>

#define kTimerInterval 1.0
#define tval2msec(tval) ((tval.seconds * 1000) + (tval.microseconds / 1000))

@implementation BeK0sukeTistatsModule

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"b4b35657-3a37-4aff-9d77-93a60b4f19f0";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"be.k0suke.tistats";
}

#pragma mark Lifecycle

-(void)startup
{
	// this method is called when the module is first loaded
	// you *must* call the superclass
	[super startup];
    
	NSLog(@"[INFO] %@ loaded",self);
    
    if (self)
    {
        if ([[TiApp app] debugMode]) {
            lastUserTime = 0;
            lastSystemTime = 0;
            
            self.timer = [NSTimer timerWithTimeInterval:kTimerInterval
                                                 target:self
                                               selector:@selector(timerHandler:)
                                               userInfo:nil
                                                repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        }
    }
}

-(void)shutdown:(id)sender
{
	// this method is called when the module is being unloaded
	// typically this is during shutdown. make sure you don't do too
	// much processing here or the app will be quit forceably

    [self.timer invalidate];
    self.timer = nil;
    
	// you *must* call the superclass
	[super shutdown:sender];
}

#pragma mark Cleanup

-(void)dealloc
{
	// release any resources that have been retained by the module
	[super dealloc];
}

#pragma mark Internal Memory Management

-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
	// optionally release any resources that can be dynamically
	// reloaded once memory is available - such as caches
	[super didReceiveMemoryWarning:notification];
}

#pragma mark Listener Notifications

-(void)_listenerAdded:(NSString *)type count:(int)count
{
	if (count == 1 && [type isEqualToString:@"my_event"])
	{
		// the first (of potentially many) listener is being added
		// for event named 'my_event'
	}
}

-(void)_listenerRemoved:(NSString *)type count:(int)count
{
	if (count == 0 && [type isEqualToString:@"my_event"])
	{
		// the last listener called for event named 'my_event' has
		// been removed, we can optionally clean up any resources
		// since no body is listening at this point for that event
	}
}

#pragma Public APIs

-(id)example:(id)args
{
	// example method
	return @"hello world";
}

-(id)exampleProp
{
	// example property getter
	return @"hello world";
}

-(void)setExampleProp:(id)value
{
	// example property setter
}

- (unsigned int)getFreeMemory
{
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
    
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    vm_statistics_data_t vm_stat;
    
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
    {
        return 0;
    }
    
    natural_t mem_free = vm_stat.free_count * pagesize;
    
    return (unsigned int)mem_free;
}

- (vm_size_t)getRSS
{
    struct task_basic_info basic_info;
    mach_msg_type_number_t t_info_count = TASK_BASIC_INFO_COUNT;
    
    if (task_info(current_task(), TASK_BASIC_INFO, (task_info_t)&basic_info, &t_info_count) != KERN_SUCCESS)
    {
        return 0;
    }
    
    return basic_info.resident_size;
}

- (vm_size_t)getVS
{
    struct task_basic_info basic_info;
    mach_msg_type_number_t t_info_count = TASK_BASIC_INFO_COUNT;
    
    if (task_info(current_task(), TASK_BASIC_INFO, (task_info_t)&basic_info, &t_info_count) != KERN_SUCCESS)
    {
        return 0;
    }
    
    return basic_info.virtual_size;
}

- (unsigned long)getUserTime
{
    struct task_thread_times_info thread_info;
    mach_msg_type_number_t t_info_count = TASK_THREAD_TIMES_INFO_COUNT;
    
    if (task_info(current_task(), TASK_THREAD_TIMES_INFO, (task_info_t)&thread_info, &t_info_count) != KERN_SUCCESS)
    {
        return 0;
    }
    
    return tval2msec(thread_info.user_time);
}

- (unsigned long)getSystemTime
{
    struct task_thread_times_info thread_info;
    mach_msg_type_number_t t_info_count = TASK_THREAD_TIMES_INFO_COUNT;
    
    if (task_info(current_task(), TASK_THREAD_TIMES_INFO, (task_info_t)&thread_info, &t_info_count) != KERN_SUCCESS)
    {
        return 0;
    }
    
    return tval2msec(thread_info.system_time);
}

- (int)getSubviewsInView:(UIView *)view
{
    int count = 0;
    
    for (UIView *subview in [view subviews]) {
        
        count++;
        
        if ([[subview subviews] count] > 0) {
            
            count += [self getSubviewsInView:subview];
        }
    }
    
    return count;
}

- (int)getSubviewsInApp
{
    int count = 0;
    NSArray *windows = [[UIApplication sharedApplication] windows];
    
    for (UIWindow *window in windows) {
        for (UIView *view in [window subviews]) {
            
            count++;
            count += [self getSubviewsInView:view];
        }
    }
    
    return count;
}

- (void)timerHandler:(NSTimer *)timer
{
    vm_size_t freeMemory = [self getFreeMemory];
    vm_size_t rss = [self getRSS];
    vm_size_t vs = [self getVS];
    uint64_t userTime = [self getUserTime];
    uint64_t systemTime = [self getSystemTime];
    
    int64_t rssPerSec = 0;
    if ((int64_t)rss > 0)
    {
        rssPerSec = ((int64_t)rss - lastRss) / kTimerInterval;
        lastRss = rss;
    }

    int64_t vsPerSec = 0;
    if ((int64_t)vs > 0)
    {
        vsPerSec = ((int64_t)vs - lastVs) / kTimerInterval;
        lastVs = vs;
    }

    int64_t userTimePerSec = 0;
    if (userTime > 0)
    {
        userTimePerSec = ((int64_t)userTime - lastUserTime) / kTimerInterval;
        lastUserTime = userTime;
    }
    
    int64_t systemTimePerSec = 0;
    if (systemTime > 0)
    {
        systemTimePerSec = ((int64_t)systemTime - lastSystemTime) / kTimerInterval;
        lastSystemTime = systemTime;
    }
    
    TiDebuggerLogMessage(OUT, [NSString stringWithFormat:@"__TISTATS__|%d|%lu|%qi|%lu|%qi|%lu|%qi|%qi",
                               [self getSubviewsInApp],
                               (unsigned long)freeMemory,
                               rssPerSec,
                               (unsigned long)rss,
                               vsPerSec,
                               (unsigned long)vs,
                               userTimePerSec,
                               systemTimePerSec]);
}

@end
