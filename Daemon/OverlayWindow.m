/*
	This file is part of the playback controller X-Tunes for iTunes on Mac OS X.
	Copyright (C) 2008 Pierre-Olivier Latour <info@pol-online.net>
	
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#import "OverlayWindow.h"

#define kFadeTimerInterval 50.0 //ms

@implementation OverlayWindow

- (id) initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
	if((self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:bufferingType defer:flag])) {
		[self setBackgroundColor:[NSColor clearColor]];
		[self setLevel:NSStatusWindowLevel];
		[self setOpaque:NO];
		[self setHasShadow:NO];
		[self setReleasedWhenClosed:NO];
		
		draggable = YES;
	}
	
    return self;
}

- (void) dealloc
{
	if(fadeTimer) {
		[fadeTimer invalidate];
		[fadeTimer release];
	}
	
	[super dealloc];
}

- (BOOL) canBecomeKeyWindow
{
    return YES;
}

- (BOOL) canBecomeMainWindow
{
    return YES;
}

- (void) showAndCenter:(BOOL)center makeKey:(BOOL)makeKey
{
	if(fadeTimer) {
		[fadeTimer invalidate];
		[fadeTimer release];
		fadeTimer = nil;
	}
	
	if(center)
	[self center];
	if(makeKey)
	[self makeKeyAndOrderFront:nil];
	else
	[self orderFront:nil];
	[self setAlphaValue:1.0];
}

- (void) timerCallback:(NSTimer*)timer
{
	if([self alphaValue] <= fadeStep) {
		[self close];
		[fadeTimer invalidate];
		[fadeTimer release];
		fadeTimer = nil;
	}
	else
	[self setAlphaValue:([self alphaValue] - fadeStep)];
}

- (void) hide:(float)delay
{
	if([self isVisible] == NO)
	return;
	
	if(delay) {
		fadeStep = kFadeTimerInterval / (1000.0 * delay);
		if(fadeTimer == nil)
		fadeTimer = [[NSTimer scheduledTimerWithTimeInterval:(kFadeTimerInterval / 1000.0) target:self selector:@selector(timerCallback:) userInfo:nil repeats:YES] retain];
	}
	else
	[self close];
}

- (void) mouseDragged:(NSEvent*)theEvent
{
	NSRect		screenFrame = [[NSScreen mainScreen] frame];
	NSRect		windowFrame = [self frame];
	NSPoint		currentLocation;
	NSPoint		newOrigin;
	
	if(!draggable) {
		[super mouseDragged:theEvent];
		return;
	}
	
	currentLocation = [self convertBaseToScreen:[self mouseLocationOutsideOfEventStream]];
    newOrigin.x = currentLocation.x - initialLocation.x;
    newOrigin.y = currentLocation.y - initialLocation.y;
    
	if((newOrigin.y + windowFrame.size.height) > (screenFrame.origin.y + screenFrame.size.height))
	newOrigin.y = screenFrame.origin.y + (screenFrame.size.height - windowFrame.size.height);
    
    [self setFrameOrigin:newOrigin];
}

- (void) mouseDown:(NSEvent*)theEvent
{
	NSRect		windowFrame = [self frame];

	initialLocation = [self convertBaseToScreen:[theEvent locationInWindow]];
	initialLocation.x -= windowFrame.origin.x;
	initialLocation.y -= windowFrame.origin.y;
}

- (void) setDraggable:(BOOL)flag
{
	draggable = flag;
}

- (BOOL) isDraggable
{
	return draggable;
}

@end

