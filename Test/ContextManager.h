//
//  ContextManager.h
//
//  Created by Rebecca Putinski on 2013-10-18.
//  Copyright (c) 2013 Rebecca Putinski All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface ContextManager : NSObject

@property (nonatomic, readonly, strong) NSManagedObjectContext *backgroundContext;

+ (instancetype)sharedInstance;

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectContext *const)newDerivedContext;
- (NSManagedObjectContext *const)mainContext;

- (void)saveWithContext:(NSManagedObjectContext *)context;

- (NSFetchRequest *)fetchRequestTemplateForName:(NSString *)templateName;

@end
