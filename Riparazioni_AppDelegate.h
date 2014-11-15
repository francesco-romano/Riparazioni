//
//  Riparazioni_AppDelegate.h
//  Riparazioni
//
//  Created by Francesco Romano on 19/12/08.
//  Copyright Università di Genova 2008 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Riparazioni_AppDelegate : NSObject 
{
    IBOutlet NSWindow *window;
	IBOutlet NSArrayController * repairsController;
	
	NSWindowController * preferenceController;
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;

- (IBAction) saveAction:sender;
- (IBAction) print:(id) sender;
- (IBAction) openPreferencesPanel:(id) sender;

@end
