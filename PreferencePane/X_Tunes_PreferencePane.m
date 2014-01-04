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

#import "X_Tunes_PreferencePane.h"
#import "X-Tunes.h"

static void _launchctl(NSString* command, ...)
{
	NSMutableArray*					arguments = [NSMutableArray arrayWithObject:command];
	NSTask*							task;
	va_list							list;
	
	//Parse arguments
	va_start(list, command);
	while(command) {
		if((command = va_arg(list, id)))
		[arguments addObject:command];
	}
	va_end(list);
	
	//Run launchctl task
	task = [NSTask new];
	[task setLaunchPath:@"/bin/launchctl"];
	[task setArguments:arguments];
	[task launch];
	[task waitUntilExit];
	if([task terminationStatus] != 0)
	NSLog(@"ERROR: launchctl exited with status %i", [task terminationStatus]);
	[task release];
}

@implementation X_Tunes_PreferencePane

- (void) willSelect
{
	NSMutableDictionary*			preferences = [NSMutableDictionary dictionary];
	NSFileManager*					manager = [NSFileManager defaultManager];
	NSString*						path;
	
	//Stop deamon if necessary
	path = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"LaunchAgents"];
	path = [path stringByAppendingPathComponent:kXTunesLaunchdConfigurationFile];
	if([manager fileExistsAtPath:path])
	_launchctl(@"unload", path, nil);
	
	//Read preferences
	[preferences setObject:[NSNumber numberWithBool:YES] forKey:kXTunesPreferencesKey_Enabled];
	[preferences setObject:[NSNumber numberWithInt:0x31] forKey:kXTunesPreferencesKey_KeyCode]; //space bar
	[preferences setObject:[NSNumber numberWithInt:4096] forKey:kXTunesPreferencesKey_KeyModifiers]; //ctrl key
	[preferences setObject:@" " forKey:kXTunesPreferencesKey_KeyCharacter];
	[preferences setObject:[NSNumber numberWithFloat:0.7] forKey:kXTunesPreferencesKey_Opacity];
	[preferences setObject:[NSNumber numberWithFloat:0.8] forKey:kXTunesPreferencesKey_FadeDelay];
	[preferences addEntriesFromDictionary:[[NSUserDefaults standardUserDefaults] persistentDomainForName:kXTunesPreferencesDomain]];
	
	//Setup user interface
	if([[preferences objectForKey:kXTunesPreferencesKey_Enabled] boolValue]) {
		[onRadio setState:NSOnState];
		[offRadio setState:NSOffState];
	}
	else {
		[onRadio setState:NSOffState];
		[offRadio setState:NSOnState];
	}
	[opacitySlider setFloatValue:[[preferences objectForKey:kXTunesPreferencesKey_Opacity] floatValue]];
	[fadingSlider setFloatValue:[[preferences objectForKey:kXTunesPreferencesKey_FadeDelay] floatValue]];
	[hotKeyButton setHotKeyWithKeyCode:[[preferences objectForKey:kXTunesPreferencesKey_KeyCode] intValue] modifiers:[[preferences objectForKey:kXTunesPreferencesKey_KeyModifiers] intValue] character:[preferences objectForKey:kXTunesPreferencesKey_KeyCharacter]];
	
	//Set version info
	[versionField setStringValue:[[self bundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
}

- (IBAction) openWebSite:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kXTunesWebSiteURL]];
}

- (void) didUnselect
{
	NSMutableDictionary*			preferences = [NSMutableDictionary dictionary];
	NSFileManager*					manager = [NSFileManager defaultManager];
	BOOL							installDaemon = [onRadio state];
	NSString*						path;
	NSMutableDictionary*			configuration;
	
	//Save preferences
	[preferences setObject:[NSNumber numberWithBool:[onRadio state]] forKey:kXTunesPreferencesKey_Enabled];
	[preferences setObject:[NSNumber numberWithInt:[hotKeyButton keyCode]] forKey:kXTunesPreferencesKey_KeyCode];
	[preferences setObject:[NSNumber numberWithInt:[hotKeyButton modifiers]] forKey:kXTunesPreferencesKey_KeyModifiers];
	[preferences setObject:[hotKeyButton character] forKey:kXTunesPreferencesKey_KeyCharacter];
	[preferences setObject:[NSNumber numberWithFloat:[opacitySlider floatValue]] forKey:kXTunesPreferencesKey_Opacity];
	[preferences setObject:[NSNumber numberWithFloat:[fadingSlider floatValue]] forKey:kXTunesPreferencesKey_FadeDelay];
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:preferences forName:kXTunesPreferencesDomain];
	
	//Update launchd configuration file
	path = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"LaunchAgents"];
	if(installDaemon && ![manager fileExistsAtPath:path]) {
		if(![manager createDirectoryAtPath:path attributes:nil])
		NSLog(@"Failed creating directory at \"%@\"", path);
	}
	path = [path stringByAppendingPathComponent:kXTunesLaunchdConfigurationFile];
	if(installDaemon) {
		configuration = [NSMutableDictionary new];
		[configuration setObject:kXTunesLaunchdLabel forKey:@"Label"];
		[configuration setObject:[[[self bundle] pathForResource:kXTunesDaemonName ofType:@"app"] stringByAppendingPathComponent:[NSString stringWithFormat:@"Contents/MacOS/%@", kXTunesDaemonName]] forKey:@"Program"];
		[configuration setObject:[NSNumber numberWithBool:YES] forKey:@"RunAtLoad"];
		[configuration setObject:[NSNumber numberWithBool:NO] forKey:@"OnDemand"];
		if(![[NSPropertyListSerialization dataFromPropertyList:configuration format:NSPropertyListXMLFormat_v1_0 errorDescription:NULL] writeToFile:path atomically:YES])
		NSLog(@"Failed writing launchd configuration file at \"%@\"", path);
		[configuration release];
	}
	else {
		if([manager fileExistsAtPath:path] && ![manager removeFileAtPath:path handler:nil])
		NSLog(@"Failed deleting launchd configuration file at \"%@\"", path);
	}
	
	//Start deamon if necessary
	if([manager fileExistsAtPath:path])
	_launchctl(@"load", path, nil);
}

- (void) doneHelp:(id)sender
{
	[NSApp endSheet:helpWindow];
	[helpWindow close];
}

- (void) showHelp:(id)sender
{
	static BOOL						helpReady = NO;
	NSAttributedString*				string;
	NSString*						path;
	
	if(helpReady == NO) {
		path = [[self bundle] pathForResource:@"Help" ofType:@"rtf"];
		string = [[[NSAttributedString alloc] initWithPath:path documentAttributes:nil] autorelease];
		[helpView replaceCharactersInRange:NSMakeRange(0, 0) withRTF:[string RTFFromRange:NSMakeRange(0, [string length]) documentAttributes:nil]];
		
		path = [[self bundle] pathForResource:@"License" ofType:@"rtf"];
		string = [[[NSAttributedString alloc] initWithPath:path documentAttributes:nil] autorelease];
		[licenseView replaceCharactersInRange:NSMakeRange(0, 0) withRTF:[string RTFFromRange:NSMakeRange(0, [string length]) documentAttributes:nil]];
		
		helpReady = YES;
	}
	
	[NSApp beginSheet:helpWindow modalForWindow:[hotKeyButton window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

@end
