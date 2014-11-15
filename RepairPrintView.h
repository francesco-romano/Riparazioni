//
//  RepairPrintView.h
//  Riparazioni
//
//  Created by Francesco Romano on 07/03/09.
//  Copyright 2009 Francesco Romano. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RepairPrintView : NSView {
	
	NSArray * repairs;
	NSMutableDictionary *attributes;
	int lineHeight;
	NSRect pageRect;
	int linesPerPage;
	int currentPage;
	int printIndex;
}
- (id) initWithArray:(NSArray *) theArray;
- (int) numberOfPages;
+ (NSView *) printViewFromRepairs:(NSArray *) theArray;
@end
