/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2015年 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#import "TiRootViewController.h"
#import "TiApp.h"

@interface TiRootViewController (Stats)

@property (nonatomic, assign) uint64_t lastUserTime;
@property (nonatomic, assign) uint64_t lastSystemTime;
@property (nonatomic, assign) vm_size_t lastRss;
@property (nonatomic, assign) vm_size_t lastVs;

@end
