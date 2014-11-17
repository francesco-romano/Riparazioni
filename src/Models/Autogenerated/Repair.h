//
//  Repair.h
//  Riparazioni
//
//  Created by Francesco Romano on 17/11/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Position;

@interface Repair : NSManagedObject

@property (nonatomic, retain) NSString * repairDescription;
@property (nonatomic, retain) NSString * contact;
@property (nonatomic, retain) NSNumber * price;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * customer;
@property (nonatomic, retain) Position *position;

@end
