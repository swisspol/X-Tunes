/*
	This file is part of the PolKit library.
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

#import "AppleScript.h"

@implementation AppleScript

+ (ComponentInstance) sharedOSAComponent
{
	static ComponentInstance	component = NULL;
	
	if(component == NULL)
	component = OpenDefaultComponent(kOSAComponentType, typeAppleScript);
	
	return component;
}

/* WARNING: This acquires ownership of the AEDesc */
+ (id) objectWithAEDesc:(const AEDesc*)aDesc
{
	id							object = nil;
	NSAppleEventDescriptor*		descriptor;
	DescType					type;
	
	descriptor = [[NSAppleEventDescriptor alloc] initWithAEDescNoCopy:aDesc];
	type = [descriptor descriptorType];
	switch(type) {
		
		case typeChar:
		case typeUnicodeText:
		object = [descriptor stringValue];
		break;
		
		case typeTrue:
		case typeFalse:
		case typeBoolean:
		object = [NSNumber numberWithBool:[descriptor booleanValue]];
		break;
		
		case typeSInt16:
		case typeSInt32:
		case typeIEEE32BitFloatingPoint:
		case typeIEEE64BitFloatingPoint:
		object = [NSNumber numberWithInt:[descriptor int32Value]];
		break;
		
		case typeUInt32:
		case typeType:
		object = [NSNumber numberWithUnsignedInt:[descriptor typeCodeValue]];
		break;
		
		default:
#if __LITTLE_ENDIAN__
		type = NSSwapInt(type);
#endif
		NSLog(@"Unsupported Apple Event Descriptor of type '%4s'", &type);
		break;
		
	}
	[descriptor release];
	
	return object;
}

+ (NSString*) scriptWithApplicationAndCommands:(NSString*)application commands:(NSString*)commands
{
	return [NSString stringWithFormat:@"tell application \"%@\"\r%@\rend tell", application, commands];
}

+ (id) executeString:(NSString*)string
{
	NSAppleEventDescriptor*		descriptor = [NSAppleEventDescriptor descriptorWithString:string];
	AEDesc						resultDesc = {typeNull, NULL};
	id							resultObject = nil;
	OSAID						resultID = kOSANullScript;
	
	if(descriptor && (OSACompileExecute([AppleScript sharedOSAComponent], [descriptor aeDesc], kOSANullScript, kOSAModeNull, &resultID) == noErr)) {
		if(OSACoerceToDesc([AppleScript sharedOSAComponent], resultID, typeWildCard, kOSAModeNull, &resultDesc) == noErr)
		resultObject = [AppleScript objectWithAEDesc:&resultDesc];
		if(resultID != kOSANullScript)
		OSADispose([AppleScript sharedOSAComponent], resultID);
	}
	
	return resultObject;
}

+ (id) executeApplicationCommands:(NSString*)application commands:(NSString*)commands
{
	return [AppleScript executeString:[AppleScript scriptWithApplicationAndCommands:application commands:commands]];
}

- (void) dealloc
{
	if(scriptID != kOSANullScript)
	OSADispose([AppleScript sharedOSAComponent], scriptID);
	
	[super dealloc];
}

- (id) initWithString:(NSString*)string
{
	NSAppleEventDescriptor*		descriptor = [NSAppleEventDescriptor descriptorWithString:string];
	
	if((self = [super init])) {
		scriptID = kOSANullScript;
		
		if((descriptor == nil) || (OSACompile([AppleScript sharedOSAComponent], [descriptor aeDesc], kOSAModePreventGetSource | kOSAModeNeverInteract | kOSAModeDontReconnect | kOSAModeCantSwitchLayer, &scriptID) != noErr)) {
			[self release];
			return nil;
		}
	}
	
	return self;
}

- (id) initWithApplicationCommands:(NSString*)application commands:(NSString*)commands
{
	return [self initWithString:[AppleScript scriptWithApplicationAndCommands:application commands:commands]];
}

- (id) execute
{
	OSAID						theResultID;
	AEDesc						theResultDesc = {typeNull, NULL};
	id							theResultObject = nil;
	ComponentInstance			component = [AppleScript sharedOSAComponent];
	
	if(scriptID == kOSANullScript)
	return nil;
	
	if(OSAExecute(component, scriptID, kOSANullScript, kOSAModeNull, &theResultID) == noErr) {
		if(theResultID != kOSANullScript) {
			if(OSACoerceToDesc(component, theResultID, typeWildCard, kOSAModeNull, &theResultDesc) == noErr)
			theResultObject = [AppleScript objectWithAEDesc:&theResultDesc];
			OSADispose(component, theResultID);
		}
	}
	
	return theResultObject;
}

@end
