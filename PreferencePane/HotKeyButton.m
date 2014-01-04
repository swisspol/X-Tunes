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

#import <Carbon/Carbon.h>

#import "HotKeyButton.h"

#define kKeyDataBase_FileName @"HotKeyButton"
#define kKeyDataBase_FileExtension @"plist"
#define kKeyDataBase_Modifiers @"modifierKeys"
#define kKeyDataBase_Specials @"specialKeys"

static int _CocoaModifiersToCarbonModifiers(int inModifiers)
{
	int			outModifiers = 0;
	
	/*if(inModifiers & NSAlphaShiftKeyMask)
	outModifiers |= alphaLock;*/
	if(inModifiers & NSShiftKeyMask)
	outModifiers |= shiftKey;
	if(inModifiers & NSControlKeyMask)
	outModifiers |= controlKey;
	if(inModifiers & NSAlternateKeyMask)
	outModifiers |= optionKey;
	if(inModifiers & NSCommandKeyMask)
	outModifiers |= cmdKey;
	
	return outModifiers;
}

@implementation HotKeyButton

- (void) _updateTitle
{
	NSString*			dataBasePath;
	NSDictionary*		keyDataBase;
	NSArray*			modifiersDataBase;
	NSArray*			specialsDataBase;
	int					i;
	NSMutableString*	title = [NSMutableString stringWithCapacity:128];
	NSString*			keyName;
	
	dataBasePath = [[NSBundle bundleForClass:[self class]] pathForResource:kKeyDataBase_FileName ofType:kKeyDataBase_FileExtension];
	keyDataBase = [NSDictionary dictionaryWithContentsOfFile:dataBasePath];
	if(keyDataBase == nil)
	return;
	modifiersDataBase = [keyDataBase objectForKey:kKeyDataBase_Modifiers];
	specialsDataBase = [keyDataBase objectForKey:kKeyDataBase_Specials];
	
	for(i = 8; i < 16; ++i) {
		if(modifiers & (1 << i))
		[title appendString:[modifiersDataBase objectAtIndex:i]];
	}
	keyName = [specialsDataBase objectAtIndex:keyCode];
	if([keyName length])
	[title appendString:keyName];
	else if([character length])
	[title appendString:character];
	else
	title = @"";
	
	[self setTitle:title];
}

- (void) setHotKeyWithKeyCode:(int)newKeyCode modifiers:(int)newModifiers character:(NSString*)keyCharacter
{
	keyCode = newKeyCode;
	modifiers = newModifiers;
	if(keyCharacter != character) {
		[character release];
		character = [keyCharacter copy];
	}
	
	[self _updateTitle];
}

- (int) keyCode
{
	return keyCode;
}

- (int) modifiers
{
	return modifiers;
}

- (NSString*) character
{
	return character;
}

- (void) mouseDown:(NSEvent*)anEvent
{
	[super mouseDown:anEvent];
	
	if([self state] == NSOnState) {
		[[self window] makeFirstResponder:self];
		[self setTitle:[[NSBundle bundleForClass:[self class]] localizedStringForKey:@"Press new key combination" value:@"" table:nil]];
	}
	else {
		[self _updateTitle];
		[[self window] makeFirstResponder:nil];
	}
}

- (BOOL) performKeyEquivalent:(NSEvent*)anEvent
{
	int			carbonModifiers;
	
	if(([self state] == NSOnState) && ([anEvent type] == NSKeyDown)) {
		carbonModifiers = _CocoaModifiersToCarbonModifiers([anEvent modifierFlags]);
		if(carbonModifiers) {
			[self setHotKeyWithKeyCode:[anEvent keyCode] modifiers:carbonModifiers character:[anEvent charactersIgnoringModifiers]];
			[self setState:NSOffState];
			if([[self window] firstResponder] == self)
			[[self window] makeFirstResponder:nil];
			return YES;
		}
	}
	
	return NO;
}

@end
