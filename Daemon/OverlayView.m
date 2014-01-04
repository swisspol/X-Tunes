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

#import "OverlayView.h"

@implementation OverlayView

+ (NSBezierPath*) createRoundedRectPath:(float)r originX:(float)x originY:(float)y width:(float)w height:(float)h
{
	NSBezierPath*		path;
	
	path = [NSBezierPath bezierPath];
	
	[path moveToPoint:NSMakePoint(x, y + r)];
	
	[path curveToPoint:NSMakePoint(x + r, y) controlPoint1:NSMakePoint(x, y + r) controlPoint2:NSMakePoint(x, y)];
	[path lineToPoint:NSMakePoint(x + w - r, y)];
	[path curveToPoint:NSMakePoint(x + w, y + r) controlPoint1:NSMakePoint(x + w - r, y) controlPoint2:NSMakePoint(x + w, y)];
	[path lineToPoint:NSMakePoint(x + w, y + h - r)];
	[path curveToPoint:NSMakePoint(x + w - r, y + h) controlPoint1:NSMakePoint(x + w, y + h - r) controlPoint2:NSMakePoint(x + w, y + h)];
	[path lineToPoint:NSMakePoint(x + r, y + h)];
	[path curveToPoint:NSMakePoint(x, y + h - r) controlPoint1:NSMakePoint(x + r, y + h) controlPoint2:NSMakePoint(x, y + h)];
	
	[path closePath];
	
	return path;
}

- (id) initWithFrame:(NSRect)rect
{
	if((self = [super initWithFrame:rect])) {
		opacity = 0.35;
		cornerRadius = 25.0;
	}
	
	return self;
}

- (BOOL) isOpaque
{
	return YES;
}

- (void) drawRect:(NSRect)rect
{
	NSRect				frame = [self bounds];
	
	[[NSColor clearColor] set];
	NSRectFill(frame);
	
	[[NSColor colorWithDeviceWhite:0.2 alpha:opacity] set];
	[[OverlayView createRoundedRectPath:cornerRadius originX:frame.origin.x originY:frame.origin.y width:frame.size.width height:frame.size.height] fill];
}

- (void) setOpacity:(float)alpha
{
	opacity = alpha;
	[self setNeedsDisplay:YES];
}

- (float) opacity
{
	return opacity;
}

- (void) setCornerRadius:(float)radius
{
	cornerRadius = radius;
	[self setNeedsDisplay:YES];
}

- (float) cornerRadius
{
	return cornerRadius;
}

@end
