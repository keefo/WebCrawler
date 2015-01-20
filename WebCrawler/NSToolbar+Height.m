//
//  NSToolbar+Height.m
//  Cutup
//
//  Created by James Shepherdson on 6/5/12.
//  Copyright (c) 2012 James Shepherdson. All rights reserved.
//

#import "NSToolbar+Height.h"

@implementation NSToolbar (Height)

- (CGFloat)heightForWindow:(NSWindow *)window {
	CGFloat height = 0.0;
	if (![self isVisible])
		return height;
	
	NSRect standardWindowFrame = [NSWindow contentRectForFrameRect:[window frame] styleMask:[window styleMask]];
	height = standardWindowFrame.size.height - [[window contentView] frame].size.height;
	return height;
}

@end
