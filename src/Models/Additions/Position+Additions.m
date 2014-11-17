//
//  Position+Additions.m
//  Riparazioni
//
//  Created by Francesco Romano on 17/11/14.
//
//

#import "Position+Additions.h"

@implementation Position (Additions)
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
