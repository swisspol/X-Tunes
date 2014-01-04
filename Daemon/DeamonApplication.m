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

#import "DeamonApplication.h"
#import "X-Tunes.h"

static OSStatus _HotKeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void* userData)
{
	NSAutoreleasePool*	pool = [NSAutoreleasePool new];
	
	switch(GetEventKind(theEvent)) {
		
		case kEventHotKeyPressed:
		[[(DeamonApplication*)userData delegate] applicationHotKeyPressed:(DeamonApplication*)userData];
		break;
		
		case kEventHotKeyReleased:
		[[(DeamonApplication*)userData delegate] applicationHotKeyReleased:(DeamonApplication*)userData];
		break;
		
	}
	
	[pool release];
	
	return noErr;
}

@implementation DeamonApplication

- (id) init
{
	if((self = [super init]))
	[[NSUserDefaults standardUserDefaults] addSuiteNamed:kXTunesPreferencesDomain];
	
	return self;
}

- (void) run
{
	EventTypeSpec		eventTypes[] = {{kEventClassKeyboard, kEventHotKeyPressed}, {kEventClassKeyboard, kEventHotKeyReleased}};
	EventHotKeyID		hotKeyID = {'xtun', 0};
	EventHotKeyRef		hotKeyRef;
	OSStatus			error;
	NSAutoreleasePool*	pool;
	
	pool = [NSAutoreleasePool new];
	error = RegisterEventHotKey([[NSUserDefaults standardUserDefaults] integerForKey:kXTunesPreferencesKey_KeyCode], [[NSUserDefaults standardUserDefaults] integerForKey:kXTunesPreferencesKey_KeyModifiers], hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef);
	if(error != noErr) {
		NSLog(@"Failed registering Hot Key!");
		[self terminate:nil];
	}
	[pool release];
	
	InstallEventHandler(GetEventDispatcherTarget(), &_HotKeyHandler, 2, eventTypes, self, NULL);
	
	[super run];
}

- (void) sendEvent:(NSEvent*)event
{
	BOOL				shouldSend = YES;
	NSEventType			type = [event type];
	
	if(type == NSKeyDown)
	shouldSend = [[self delegate] application:self keyDown:[event keyCode]];
	else if(type == NSKeyUp)
	shouldSend = [[self delegate] application:self keyUp:[event keyCode]];
	
	if(shouldSend)
	[super sendEvent:event];
}

@end
