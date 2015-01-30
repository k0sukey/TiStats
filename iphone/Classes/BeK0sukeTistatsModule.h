/**
 * TiStats
 *
 * Created by Kosuke Isobe
 * Copyright (c) 2015 Your Company. All rights reserved.
 */

#import "TiModule.h"

@interface BeK0sukeTistatsModule : TiModule
{
    uint64_t lastUserTime;
    uint64_t lastSystemTime;
    vm_size_t lastRss;
    vm_size_t lastVs;
}

@property (nonatomic, assign) NSTimer *timer;

@end
