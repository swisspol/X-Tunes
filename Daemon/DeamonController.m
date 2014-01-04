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

#import "CPSPrivate.h"

#import "X-Tunes.h"
#import "DeamonController.h"
#import "DeamonApplication.h"

#define kUpdateInterval 500.0 //ms
#define kiTunesName @"iTunes"

#define keyArrowLeft 0x7b
#define keyArrowRight 0x7c
#define keyArrowUp 0x7e
#define keyArrowDown 0x7d
#define keyReturn 0x24

typedef enum {
	kScript_NULL = 0,
	kScript_Update,
	kScript_UpdateWithVolume,
	kScript_Play,
	kScript_Stop,
	kScript_Previous,
	kScript_Next,
	kScript_FastForward,
	kScript_Rewind,
	kScript_VolumeUp,
	kScript_VolumeDown
} ScriptID;

#if __USE_SCRIPT_THREAD__

enum {
	WAIT = 1,
	RUN
};

#endif

static NSString* _StringFromDuration(NSNumber* duration)
{
	int					value = [duration intValue];
	
	if(value % 60 < 10)
	return [NSString stringWithFormat:@"%i:0%i",value / 60,value % 60];
	else
	return [NSString stringWithFormat:@"%i:%i",value / 60,value % 60];
}

@implementation DeamonController

- (void) applicationDidFinishLaunching:(NSNotification*)notification
{
	//Compile scripts
	scriptPlay = [[AppleScript alloc] initWithApplicationCommands:kiTunesName commands:@"if (player state is stopped) or (player state is paused) then\rplay\relse if (player state is fast forwarding) or (player state is rewinding) then\rpause\rplay\relse\rpause\rend if"];
	scriptStop = [[AppleScript alloc] initWithApplicationCommands:kiTunesName commands:@"stop"];
	scriptFastForward = [[AppleScript alloc] initWithApplicationCommands:kiTunesName commands:@"fast forward"];
	scriptRewind = [[AppleScript alloc] initWithApplicationCommands:kiTunesName commands:@"rewind"];
	scriptNextTrack = [[AppleScript alloc] initWithApplicationCommands:kiTunesName commands:@"next track"];
	scriptPreviousTrack = [[AppleScript alloc] initWithApplicationCommands:kiTunesName commands:@"back track"];
	scriptTrackName = [[AppleScript alloc] initWithApplicationCommands:kiTunesName commands:@"name of current track"];
	scriptTrackArtist = [[AppleScript alloc] initWithApplicationCommands:kiTunesName commands:@"artist of current track"];
	scriptTrackAlbum = [[AppleScript alloc] initWithApplicationCommands:kiTunesName commands:@"album of current track"];
	scriptTrackDuration = [[AppleScript alloc] initWithApplicationCommands:kiTunesName commands:@"duration of current track"];
	scriptTrackID = [[AppleScript alloc] initWithApplicationCommands:kiTunesName commands:@"database ID of current track"];
	scriptPlayerPosition = [[AppleScript alloc] initWithApplicationCommands:kiTunesName commands:@"player position"];
	scriptPlayerVolume = [[AppleScript alloc] initWithApplicationCommands:kiTunesName commands:@"sound volume"];
	scriptPlayerVolumeUp = [[AppleScript alloc] initWithApplicationCommands:kiTunesName commands:@"set sound volume to (sound volume + 10)\rsound volume"];
	scriptPlayerVolumeDown = [[AppleScript alloc] initWithApplicationCommands:kiTunesName commands:@"set sound volume to (sound volume - 10)\rsound volume"];
	
	//Set window parameters
	[view setOpacity:[[NSUserDefaults standardUserDefaults] floatForKey:kXTunesPreferencesKey_Opacity]];
	[window setDraggable:NO];
	
	//Set variables
	pauseKeyDown = NO;
	updateTimer = nil;
	lastTrackID = -1;
#if __USE_SCRIPT_THREAD__
	threadLock = [[NSConditionLock alloc] initWithCondition:WAIT];
	threadScriptID = kScript_NULL;
#endif
	
#if __USE_SCRIPT_THREAD__
	//Launch script thread
	[NSThread detachNewThreadSelector:@selector(_scriptThread:) toTarget:self withObject:nil];
#endif
	
	//We're ready!
	NSLog(@"Started...");
}

- (void) _executeScript:(ScriptID)scriptID
{
	id					object;
	
	switch(scriptID) {
		
		case kScript_Update:
		case kScript_UpdateWithVolume:
		if((object = [scriptPlayerPosition execute]));
		[elapsedField setStringValue:_StringFromDuration(object)];
		
		if((scriptID == kScript_UpdateWithVolume) && (object = [scriptPlayerVolume execute]))
		[volumeField setStringValue:[NSString stringWithFormat:@"%i%%", [object intValue]]];
		
		if((object = [scriptTrackID execute]) && ([object intValue] != lastTrackID)) {
			if((object = [scriptTrackName execute]))
			[nameField setStringValue:object];
			if((object = [scriptTrackArtist execute]))
			[artistField setStringValue:object];
			if((object = [scriptTrackAlbum execute]))
			[albumField setStringValue:object];
			if((object = [scriptTrackDuration execute]))
			[totalField setStringValue:_StringFromDuration(object)];
			
			lastTrackID = [object intValue];
		}
		break;
		
		case kScript_Play:
		[scriptPlay execute];
		break;
		
		case kScript_Stop:
		[scriptStop execute];
		break;
		
		case kScript_Previous:
		[scriptPreviousTrack execute];
		break;
		
		case kScript_Next:
		[scriptNextTrack execute];
		break;
		
		case kScript_FastForward:
		[scriptFastForward execute];
		break;
		
		case kScript_Rewind:
		[scriptRewind execute];
		break;
		
		case kScript_VolumeUp:
		if((object = [scriptPlayerVolumeUp execute]))
		[volumeField setStringValue:[NSString stringWithFormat:@"%i%%", [object intValue]]];
		break;
		
		case kScript_VolumeDown:
		if((object = [scriptPlayerVolumeDown execute]))
		[volumeField setStringValue:[NSString stringWithFormat:@"%i%%", [object intValue]]];
		break;
		
		default:
		break;
		
	}
}

#if __USE_SCRIPT_THREAD__

- (void) _scriptThread:(id)argument
{
	NSAutoreleasePool*	pool;
	ScriptID			scriptID;
	
	while(1) {
		[threadLock lockWhenCondition:RUN];
		scriptID = threadScriptID;
		[threadLock unlockWithCondition:WAIT];
		
		pool = [NSAutoreleasePool new];
		[self _executeScript:scriptID];
		[pool release];
	}
}

#endif

- (void) _runScript:(ScriptID)scriptID
{
#if __USE_SCRIPT_THREAD__
	if([threadLock tryLockWhenCondition:WAIT]) {
		threadScriptID = scriptID;
		[threadLock unlockWithCondition:RUN];
	}
	else {
		NSLog(@"Unable to acquire lock: user command #%i not executed!", scriptID);
		if((scriptID != kScript_Update) && (scriptID != kScript_UpdateWithVolume))
		NSBeep();
	}
#else
	[self _executeScript:scriptID];
#endif
}

- (void) _updateInfoTimer:(NSTimer*)timer
{
	//Update window info
	[self _runScript:kScript_Update];
}

- (void) applicationHotKeyPressed:(DeamonApplication*)sender
{
	CPSProcessSerNum        psn;
	
	//Update window info
#if __USE_SCRIPT_THREAD__
	if([threadLock condition] == WAIT)
#endif
	[self _runScript:kScript_UpdateWithVolume];
	
	//Position window
	[window setFrameOrigin:NSMakePoint(([[NSScreen mainScreen] frame].size.width - [window frame].size.width) / 2, 150)];
	
	//Show window
	[window showAndCenter:NO makeKey:YES];
	[window setIgnoresMouseEvents:NO];
	
	//Steal keyboard focus - Might fail in some circumstances
	CPSGetCurrentProcess(&psn);
	CPSStealKeyFocus(&psn);
	
	//Start update timer
	if(updateTimer == nil)
	updateTimer = [[NSTimer scheduledTimerWithTimeInterval:(kUpdateInterval / 1000.0) target:self selector:@selector(_updateInfoTimer:) userInfo:nil repeats:YES] retain];
}

- (void) applicationHotKeyReleased:(DeamonApplication*)sender
{
	CPSProcessSerNum        psn;
	
	//Destroy update timer
	if(updateTimer) {
		[updateTimer invalidate];
		[updateTimer release];
		updateTimer = nil;
	}
	
	//Hide window
	[window setIgnoresMouseEvents:YES];
	[window hide:[[NSUserDefaults standardUserDefaults] floatForKey:kXTunesPreferencesKey_FadeDelay]];
	
	//Release keyboard focus - Might fail in some circumstances
	CPSGetCurrentProcess(&psn);
	CPSReleaseKeyFocus(&psn);
}

- (BOOL) application:(DeamonApplication*)sender keyDown:(unsigned short)keyCode
{
	if([window isVisible] == NO)
	return YES;
	
	switch(keyCode) {
		
		case keyArrowUp:
		[upButton highlight:YES];
		[upButton display];
		[self _runScript:kScript_VolumeUp];
		[upButton highlight:NO];
		break;
		
		case keyArrowDown:
		[downButton highlight:YES];
		[downButton display];
		[self _runScript:kScript_VolumeDown];
		[downButton highlight:NO];
		break;
		
		case keyArrowLeft:
		[prevButton highlight:YES];
		[prevButton display];
		[self _runScript:kScript_Previous];
		[prevButton highlight:NO];
		break;
		
		case keyArrowRight:
		[nextButton highlight:YES];
		[nextButton display];
		[self _runScript:kScript_Next];
		[nextButton highlight:NO];
		break;
		
		case keyReturn:
		if(!pauseKeyDown) {
			[playButton highlight:YES];
			[playButton display];
			[self _runScript:kScript_Play];
			[playButton highlight:NO];
			pauseKeyDown = YES;
		}
		break;
		
		default:
		return YES;
		break;
		
	}
	
	return NO;
}

- (BOOL) application:(DeamonApplication*)sender keyUp:(unsigned short)keyCode
{
	if([window isVisible] == NO)
	return YES;
	
	switch(keyCode) {
		
		case keyReturn:
		if(!pauseKeyDown) {
			[playButton highlight:YES];
			[playButton display];
			[self _runScript:kScript_Play];
			[playButton highlight:NO];
		}
		pauseKeyDown = NO;
		break;
		
		default:
		return YES;
		break;
		
	}
	
	return NO;
}

@end

@implementation DeamonController (Actions)

- (IBAction) fastForward:(id)sender
{
	[self _runScript:kScript_FastForward];
}

- (IBAction) rewind:(id)sender
{
	[self _runScript:kScript_Rewind];
}

- (IBAction) next:(id)sender
{
	[self _runScript:kScript_Next];
}

- (IBAction) previous:(id)sender
{
	[self _runScript:kScript_Previous];
}

- (IBAction) play:(id)sender
{
	[self _runScript:kScript_Play];
}

- (IBAction) stop:(id)sender
{
	[self _runScript:kScript_Stop];
}

- (IBAction) volumeUp:(id)sender
{
	[self _runScript:kScript_VolumeUp];
}

- (IBAction) volumeDown:(id)sender
{
	[self _runScript:kScript_VolumeDown];
}

@end
