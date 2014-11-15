//
//  PreferenceController.m
//  Riparazioni
//
//  Created by Francesco Romano on 18/03/09.
//  Copyright 2009 Francesco Romano. All rights reserved.
//

#import "PreferenceController.h"


@implementation PreferenceController

- (id) init
{
	self = [super initWithWindowNibName:@"Preferences"];
	if (self != nil) {
		
	}
	return self;
}

- (IBAction) chooseSavingPath:(id)sender
{
	NSOpenPanel * panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles:NO];
	[panel setCanCreateDirectories:YES];
	[panel setCanChooseDirectories:YES];
	[panel setAllowsMultipleSelection:NO];
	if ([panel runModalForDirectory:[savingPath stringValue] file:nil] == NSCancelButton)
		return;
	NSArray * directories = [panel filenames];
	[[NSUserDefaults standardUserDefaults] setValue:[directories objectAtIndex:0] forKey:@"savingPath"];
	
}


- (IBAction) defaultSavingPath:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"savingPath"];
}

- (IBAction) closePanel:(id)sender
{
	[NSApp endSheet:[self window]];
	[[self window] orderOut:sender];
}
@end
