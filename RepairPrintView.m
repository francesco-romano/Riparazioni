//
//  RepairPrintView.m
//  Riparazioni
//
//  Created by Francesco Romano on 07/03/09.
//  Copyright 2009 Francesco Romano. All rights reserved.
//

#import "RepairPrintView.h"

#define TITLE_LINES 2
#define FOOTER_LINES 3
#define HEADERS_LINES 1

@implementation RepairPrintView

- (id) initWithArray:(NSArray *) theArray
{
	if (!theArray)
		return nil;
	if (self = [super initWithFrame:NSMakeRect(0, 0, 700, 700)]) {
		repairs = [theArray copy];
		
		attributes = [[NSMutableDictionary alloc] init]; 
		NSFont *font = [NSFont fontWithName:@"Times New Roman" size:10.0]; 
		lineHeight = [font capHeight] * 1.9; 
		[attributes setObject:font 
					   forKey:NSFontAttributeName]; 
		printIndex=0;
		

		
	}
	return self;
		
}

- (void) dealloc
{
	[repairs release];
	[attributes release];
	[super dealloc];
}

+ (NSView *) printViewFromRepairs:(NSArray *) theArray
{
	return [[[RepairPrintView alloc] initWithArray: theArray] autorelease];
}

#pragma mark pagination

- (BOOL)knowsPageRange:(NSRange *)range 
{ 
    NSPrintOperation *po = [NSPrintOperation currentOperation]; 
    NSPrintInfo *printInfo = [po printInfo]; 
    // Where can I draw? 
    pageRect = [printInfo imageablePageBounds]; 
    NSRect newFrame; 
    newFrame.origin = NSZeroPoint; 
    newFrame.size = [printInfo paperSize]; 
    [self setFrame:newFrame]; 
    // How many lines per page? 
    linesPerPage = pageRect.size.height / lineHeight; 
    // Pages are 1-based 
    range->location = 1; 
    // How many pages will it take? 
    /*range->length = [repairs count] / linesPerPage; 
    if ([repairs count] % linesPerPage) { 
        range->length = range->length + 1; 
    } 
	 */
	range->length = [self numberOfPages];
    return YES; 
}

- (NSRect)rectForPage:(NSInteger)i
{ 
    // Note the current page 
    currentPage = i - 1;
    // Return the same page rect everytime 
    return pageRect; 
} 

#pragma mark Drawing 

// The origin of the view is at the upper-left corner 
- (BOOL)isFlipped 
{ 
    return YES; 
} 

- (int) numberOfPages
{
	int numberOfPages;
	int lines = linesPerPage - TITLE_LINES - FOOTER_LINES;
	
	BOOL headers = [[[NSUserDefaults standardUserDefaults] valueForKey:@"printHeaders"] boolValue];
	if (headers) {
		lines -= HEADERS_LINES;
	}
	numberOfPages = [repairs count] / lines;
	if ([repairs count] % lines)
		numberOfPages +=1;
	
	return numberOfPages;
	
}
- (void)drawRect:(NSRect)rect
{ 
	
	NSRect customerRect;
	NSRect contactRect;
	NSRect priceRect;
	NSRect dateRect;
	NSRect notesRect;
	NSRect positionRect;
	NSRect descriptionRect;
	
	//setting Hight
	customerRect.size.height = lineHeight;
	contactRect.size.height = lineHeight;
	priceRect.size.height = lineHeight;
	dateRect.size.height = lineHeight;
	notesRect.size.height = lineHeight;
	positionRect.size.height = lineHeight;
	descriptionRect.size.height = lineHeight;
	
	//setting width
	customerRect.size.width = 90;
	contactRect.size.width = 80;
	priceRect.size.width = 40;
	dateRect.size.width = 55;
	notesRect.size.width = 100;
	positionRect.size.width = 70;
	descriptionRect.size.width = 115;
	
	//setting x-origin
	customerRect.origin.x = pageRect.origin.x;
	dateRect.origin.x = customerRect.origin.x + customerRect.size.width + 2;
	descriptionRect.origin.x = dateRect.origin.x + dateRect.size.width + 2;
	priceRect.origin.x = descriptionRect.origin.x + descriptionRect.size.width + 2;
	positionRect.origin.x = priceRect.origin.x + priceRect.size.width + 2;
	contactRect.origin.x = positionRect.origin.x + positionRect.size.width + 2;
	notesRect.origin.x = contactRect.origin.x + contactRect.size.width + 2;
	
	NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	
	[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	[numberFormatter setCurrencySymbol:@""];
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	
	NSMutableDictionary * numberDictionary = [NSMutableDictionary dictionaryWithDictionary:attributes];
	NSMutableParagraphStyle * paragraph = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[paragraph setAlignment:NSRightTextAlignment];
	[numberDictionary setObject:paragraph forKey:NSParagraphStyleAttributeName];
	
	int lines = linesPerPage - FOOTER_LINES;
	int headerSize = 0;
	BOOL header = [[[NSUserDefaults standardUserDefaults] valueForKey:@"printHeaders"] boolValue];
	
	//header

	if (currentPage  == 0) {
		// adding size of the Title
		headerSize += TITLE_LINES;
		lines -= TITLE_LINES;
		NSFont * titleFont = [NSFont fontWithName:@"Arial Bold" size:12.0]; 
		NSRect headerRect = NSMakeRect(pageRect.size.width/2 -20, pageRect.origin.y , 200, [titleFont capHeight] * 2);
		NSMutableDictionary * headerAttributes = [NSMutableDictionary dictionary];
		[headerAttributes setObject:titleFont
					   forKey:NSFontAttributeName]; 
		
		[@"Riparazioni" drawInRect:headerRect withAttributes:headerAttributes];
	}
	
	if (header) {
		// if user want to print column headers
		// print :)
		
		NSFont * headersFont = [NSFont fontWithName:@"Times New Roman Bold" size:10.0]; 
		NSDictionary * headerAttr = [NSDictionary dictionaryWithObject:headersFont forKey:NSFontAttributeName];
		customerRect.origin.y = pageRect.origin.y + (headerSize * lineHeight);
		contactRect.origin.y = customerRect.origin.y;
		priceRect.origin.y = customerRect.origin.y;
		dateRect.origin.y = customerRect.origin.y;
		notesRect.origin.y = customerRect.origin.y;
		positionRect.origin.y = customerRect.origin.y;
		descriptionRect.origin.y = customerRect.origin.y;
		
		[NSLocalizedString(@"Customer",@"Header") drawInRect:customerRect withAttributes:headerAttr];
		[NSLocalizedString(@"Date",nil) drawInRect:dateRect withAttributes:headerAttr];
		[NSLocalizedString(@"Description",nil) drawInRect:descriptionRect withAttributes:headerAttr];
		[NSLocalizedString(@"Price",nil) drawInRect:priceRect withAttributes:headerAttr];
		[NSLocalizedString(@"Position",nil) drawInRect:positionRect withAttributes:headerAttr];
		[NSLocalizedString(@"Contact",nil) drawInRect:contactRect withAttributes:headerAttr];
		[NSLocalizedString(@"Notes",nil) drawInRect:notesRect withAttributes:headerAttr];
		
		// managing lines of page
		headerSize += HEADERS_LINES;
		lines -= HEADERS_LINES;
	}
	// end header
	
	
	NSPoint start = NSMakePoint(pageRect.origin.x, pageRect.origin.y + (headerSize * lineHeight));
	NSPoint end = NSMakePoint(pageRect.size.width,pageRect.origin.y + (headerSize * lineHeight));
	[NSBezierPath strokeLineFromPoint:start toPoint:end];
	
    for (int i=0; i < lines; i++) { 
		if (printIndex >= [repairs count])
			break;
		
        NSManagedObject *obj = [repairs objectAtIndex:printIndex]; 

		customerRect.origin.y = pageRect.origin.y + ((i + headerSize) * lineHeight);
		contactRect.origin.y = customerRect.origin.y;
		priceRect.origin.y = customerRect.origin.y;
		dateRect.origin.y = customerRect.origin.y;
		notesRect.origin.y = customerRect.origin.y;
		positionRect.origin.y = customerRect.origin.y;
		descriptionRect.origin.y = customerRect.origin.y;
		
		
		NSString *customer = [obj valueForKey:@"customer"]; 
        [customer drawInRect:customerRect withAttributes:attributes];
		NSString *date = [dateFormatter stringFromDate:[obj valueForKey:@"date"]]; 
        [date drawInRect:dateRect withAttributes:attributes];
		NSString *description = [obj valueForKey:@"repairDescription"]; 
        [description drawInRect:descriptionRect withAttributes:attributes];
		NSString *price = [numberFormatter stringFromNumber:[obj valueForKey:@"price"]]; 
        [price drawInRect:priceRect withAttributes:numberDictionary];
		NSString * position= [obj valueForKeyPath:@"position.positionDescription"]; 
        [position drawInRect:positionRect withAttributes:attributes];
		NSString *contact = [obj valueForKey:@"contact"]; 
        [contact drawInRect:contactRect withAttributes:attributes];
		NSString *notes = [obj valueForKey:@"notes"]; 
        [notes drawInRect:notesRect withAttributes:attributes];
		
		printIndex ++;
     
	} 
	
	start.y = end.y = pageRect.size.height +8;
	
	[NSBezierPath strokeLineFromPoint:start toPoint:end];
	// footer
	
	NSRect printDateRect = NSMakeRect(pageRect.origin.x, pageRect.size.height + 10, 60, lineHeight);
	NSRect pageNumberRect = NSMakeRect(pageRect.size.width - 60, pageRect.size.height + 10, 60, lineHeight);
	NSRect recordNumberRect = NSMakeRect(pageRect.size.width /2 -40, pageRect.size.height + 10, 80, lineHeight);
	
	[[dateFormatter stringFromDate:[NSDate date]] drawInRect:printDateRect withAttributes:attributes];
	
	[[NSString stringWithFormat:NSLocalizedString(@"page %d of %d",@"Page Footer"), currentPage + 1, [self numberOfPages]] drawInRect:pageNumberRect withAttributes:attributes];
	[[NSString stringWithFormat:NSLocalizedString(@"%d of %d records",nil), printIndex, [repairs count]] drawInRect:recordNumberRect withAttributes:attributes];
	// end footer
	
	[numberFormatter release];
	[dateFormatter release];
} 


@end
