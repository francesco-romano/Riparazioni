// 
//  Position.m
//  Riparazioni
//
//  Created by Francesco Romano on 19/03/09.
//  Copyright 2009 Francesco Romano. All rights reserved.
//

#import "Position.h"

#import "Repair.h"

@implementation Position 

- (void)awakeFromInsert
{
	[super awakeFromInsert];
	[self setValue:NSLocalizedString(@"Empty Position",@"Position") forKey:@"positionDescription"];
}

- (NSNumber *) countRepairs
{
	return [NSNumber numberWithInt:[[self mutableSetValueForKey:@"repairs"] count]];
}
@end
