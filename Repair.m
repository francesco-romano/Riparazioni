// 
//  Repair.m
//  Riparazioni
//
//  Created by Francesco Romano on 07/03/09.
//  Copyright 2009 Francesco Romano. All rights reserved.
//

#import "Repair.h"


@implementation Repair 

- (void)awakeFromInsert
{
	[super awakeFromInsert];
	[self setValue:[NSDate date] forKey:@"date"];
	[self setValue:NSLocalizedString(@"New Customer",@"Repair") forKey:@"customer"];
}

@end
