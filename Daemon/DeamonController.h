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
#import "OverlayView.h"
#import "AppleScript.h"

#define	__USE_SCRIPT_THREAD__ 0 //Untested in a very long time

@interface DeamonController : NSObject
{
	IBOutlet OverlayWindow*		window;
	IBOutlet OverlayView*		view;
	
	IBOutlet NSTextField*		nameField;
	IBOutlet NSTextField*		artistField;
	IBOutlet NSTextField*		albumField;
	IBOutlet NSTextField*		elapsedField;
	IBOutlet NSTextField*		totalField;
	IBOutlet NSTextField*		volumeField;
	
	IBOutlet NSButton*			playButton;
	IBOutlet NSButton*			prevButton;
	IBOutlet NSButton*			nextButton;
	IBOutlet NSButton*			upButton;
	IBOutlet NSButton*			downButton;
	IBOutlet NSButton*			rewindButton;
	IBOutlet NSButton*			fastButton;
	
	NSTimer*					updateTimer;
	int							lastTrackID;
	BOOL						pauseKeyDown;
	
#if __USE_SCRIPT_THREAD__
	NSConditionLock*			threadLock;
	int							threadScriptID;
#endif
	
	AppleScript*				scriptPlay;
	AppleScript*				scriptStop;
	AppleScript*				scriptFastForward;
	AppleScript*				scriptRewind;
	AppleScript*				scriptNextTrack;
	AppleScript*				scriptPreviousTrack;
	
	AppleScript*				scriptTrackName;
	AppleScript*				scriptTrackArtist;
	AppleScript*				scriptTrackAlbum;
	AppleScript*				scriptTrackDuration;
	AppleScript*				scriptTrackID;
	
	AppleScript*				scriptPlayerPosition;
	AppleScript*				scriptPlayerVolume;
	AppleScript*				scriptPlayerVolumeUp;
	AppleScript*				scriptPlayerVolumeDown;
}
@end

@interface DeamonController (Actions)
- (IBAction) fastForward:(id)sender;
- (IBAction) next:(id)sender;
- (IBAction) play:(id)sender;
- (IBAction) previous:(id)sender;
- (IBAction) rewind:(id)sender;
- (IBAction) stop:(id)sender;
- (IBAction) volumeUp:(id)sender;
- (IBAction) volumeDown:(id)sender;
@end
