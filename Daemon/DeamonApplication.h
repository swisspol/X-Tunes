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

#import <AppKit/AppKit.h>

@interface DeamonApplication : NSApplication
@end

@interface NSObject(DeamonApplicationDelegate)
- (BOOL) application:(DeamonApplication*)sender keyDown:(unsigned short)keyCode;
- (BOOL) application:(DeamonApplication*)sender keyUp:(unsigned short)keyCode;
- (void) applicationHotKeyPressed:(DeamonApplication*)sender;
- (void) applicationHotKeyReleased:(DeamonApplication*)sender;
@end
