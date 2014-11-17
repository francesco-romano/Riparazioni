//
//  PreferenceController.h
//  Riparazioni
//
//  Created by Francesco Romano on 18/03/09.
//  Copyright 2009 Francesco Romano. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PreferenceController : NSWindowController {
	IBOutlet NSTextField * savingPath;
}

- (IBAction) chooseSavingPath:(id)sender;
- (IBAction) defaultSavingPath:(id)sender;
- (IBAction) closePanel:(id)sender;
@end
