//
//  Repair+Additions.m
//  Riparazioni
//
//  Created by Francesco Romano on 17/11/14.
//
//

#import "Repair+Additions.h"

@implementation Repair (Additions)
- (void)awakeFromInsert
{
    [super awakeFromInsert];
    [self setValue:[NSDate date] forKey:@"date"];
    [self setValue:NSLocalizedString(@"New Customer",@"Repair") forKey:@"customer"];
}

@end
