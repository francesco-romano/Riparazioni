//
//  Position.h
//  Riparazioni
//
//  Created by Francesco Romano on 17/11/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Repair;

@interface Position : NSManagedObject

@property (nonatomic, retain) NSString * positionDescription;
@property (nonatomic, retain) NSSet *repairs;
@end

@interface Position (CoreDataGeneratedAccessors)

- (void)addRepairsObject:(Repair *)value;
- (void)removeRepairsObject:(Repair *)value;
- (void)addRepairs:(NSSet *)values;
- (void)removeRepairs:(NSSet *)values;

@end
