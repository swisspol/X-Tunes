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

#import <PreferencePanes/PreferencePanes.h>

#import "HotKeyButton.h"

@interface X_Tunes_PreferencePane : NSPreferencePane 
{
	IBOutlet NSSlider*		fadingSlider;
	IBOutlet NSSlider*		opacitySlider;
	IBOutlet HotKeyButton*	hotKeyButton;
	IBOutlet NSButtonCell*	onRadio;
	IBOutlet NSButtonCell*	offRadio;
	IBOutlet NSTextField*	versionField;
	
	IBOutlet NSWindow*		helpWindow;
	IBOutlet NSTextView*	helpView;
	IBOutlet NSTextView*	licenseView;
}

- (IBAction) openWebSite:(id)sender;

@end
