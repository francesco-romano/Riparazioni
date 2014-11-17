//
//  Riparazioni_AppDelegate.m
//  Riparazioni
//
//  Created by Francesco Romano on 19/12/08.
//  Copyright Università di Genova 2008 . All rights reserved.
//

#import "Riparazioni_AppDelegate.h"
#import "RepairPrintView.h"
#import "PreferenceController.h"

@implementation Riparazioni_AppDelegate

+ (void) initialize {
	
	/*
	 Per ora per non usare un metodo statico..
	 
	 */
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    NSString * savingPath =  [basePath stringByAppendingPathComponent:@"Riparazioni"];
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	NSObject * obj[3] =  {[NSNumber numberWithBool:NO],savingPath,[NSNumber numberWithInt:1]};
	NSString * keys[3] = {@"printHeaders",@"savingPath",@"currentPrintSelection"};
	NSDictionary * dictionary = [NSDictionary dictionaryWithObjects:obj forKeys:keys count:3];
	[defaults registerDefaults:dictionary];
	
	
	
}
/**
    Returns the support folder for the application, used to store the Core Data
    store file.  This code uses a folder named "Riparazioni" for
    the content, either in the NSApplicationSupportDirectory location or (if the
    former cannot be found), the system's temporary directory.
 */

/*- (NSString *)applicationSupportFolder {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"Riparazioni"];
}
*/

/**
    Creates, retains, and returns the managed object model for the application 
    by merging all of the models found in the application bundle.
 */
 
- (NSManagedObjectModel *)managedObjectModel {

    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
	
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];    
    return managedObjectModel;
}


/**
    Returns the persistent store coordinator for the application.  This 
    implementation will create and return a coordinator, having added the 
    store for the application to it.  (The folder for the store is created, 
    if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }

    NSFileManager *fileManager;
    NSURL *url;
    NSError *error;
    /*
	 Gestire directory scelta..
	 */
	NSString * filePath = [[NSUserDefaults standardUserDefaults] valueForKey:@"savingPath"];
	
	
    fileManager = [NSFileManager defaultManager];
    if ( ![fileManager fileExistsAtPath:filePath isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    url = [NSURL fileURLWithPath: [filePath stringByAppendingPathComponent: @"Riparazioni.sql"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]){
        [[NSApplication sharedApplication] presentError:error];
    }    

    return persistentStoreCoordinator;
}


/**
    Returns the managed object context for the application (which is already
    bound to the persistent store coordinator for the application.) 
 */
 
- (NSManagedObjectContext *) managedObjectContext {

    if (managedObjectContext != nil) {
        return managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return managedObjectContext;
}


/**
    Returns the NSUndoManager for the application.  In this case, the manager
    returned is that of the managed object context for the application.
 */
 
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}


/**
    Performs the save action for the application, which is to send the save:
    message to the application's managed object context.  Any encountered errors
    are presented to the user.
 */
 
- (IBAction) saveAction:(id)sender {

    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}


/**
    Implementation of the applicationShouldTerminate: method, used here to
    handle the saving of changes in the application managed object context
    before the application terminates.
 */
 
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

    NSError *error;
    int reply = NSTerminateNow;
    
    if (managedObjectContext != nil) {
        if ([managedObjectContext commitEditing]) {
            if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
				
                // This error handling simply presents error information in a panel with an 
                // "Ok" button, which does not include any attempt at error recovery (meaning, 
                // attempting to fix the error.)  As a result, this implementation will 
                // present the information to the user and then follow up with a panel asking 
                // if the user wishes to "Quit Anyway", without saving the changes.

                // Typically, this process should be altered to include application-specific 
                // recovery steps.  

                BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
				
                if (errorResult == YES) {
                    reply = NSTerminateCancel;
					
                } 

                else {

                    int alertReturn = NSRunAlertPanel(nil, NSLocalizedString(@"Could not save changes while quitting. Quit anyway?",@"Saving error") ,
													  NSLocalizedString(@"Quit anyway",nil), NSLocalizedString(@"Cancel",nil), nil);
                    if (alertReturn == NSAlertAlternateReturn) {
                        reply = NSTerminateCancel;
						[window orderFront:self]; // show the window again
                    }
                }
            }
        } 
        
        else {
            reply = NSTerminateCancel;
        }
    }
    
    return reply;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

/**
    Implementation of dealloc, to release the retained variables.
 */
 
- (void) dealloc {

    managedObjectContext = nil;
    persistentStoreCoordinator = nil;
    managedObjectModel = nil;
}

 - (IBAction)print:(id)sender {
	 NSArray * printContent;
	 
	 int selection = [[[NSUserDefaults standardUserDefaults] valueForKey:@"currentPrintSelection"] intValue];
	 if (selection == 1)
		 printContent = [repairsController arrangedObjects];
	 else {
		 NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
		 [fetch setEntity:[NSEntityDescription entityForName:@"Repair" inManagedObjectContext:[self managedObjectContext]]];
		 
		 NSSortDescriptor * customer = [[NSSortDescriptor alloc] initWithKey:@"customer" ascending:YES selector:@selector(caseInsensitiveCompare:)];
		 NSSortDescriptor * date = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
		 NSArray * sorts = [NSArray arrayWithObjects: customer, date, nil];
		 [fetch setSortDescriptors:sorts];
		 NSError *error;
		 if (!(printContent = [[self managedObjectContext] executeFetchRequest:fetch error:&error])) 
			 [NSApp presentError:error];
		 
		 
		 fetch = nil;
	 }
	 NSPrintOperation *op = [NSPrintOperation printOperationWithView:[RepairPrintView printViewFromRepairs:printContent]];
	 [op runOperation];
 }

- (IBAction) openPreferencesPanel:(id) sender
{
	if (!preferenceController)
		preferenceController = [[PreferenceController alloc] init];
	[NSApp beginSheet:[preferenceController window] modalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	
}
@end
