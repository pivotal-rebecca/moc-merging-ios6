//
//  ContextManager.m
//
//  Created by Rebecca Putinski on 2013-10-18.
//  Copyright (c) 2013 Rebecca Putinski All rights reserved.
//

#import "ContextManager.h"

static ContextManager *instance;

@interface ContextManager ()

@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSManagedObjectContext *mainContext;
@property (nonatomic, strong) NSManagedObjectContext *backgroundContext;

@end

@implementation ContextManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ContextManager alloc] init];
    });
    return instance;
}

#pragma mark - Contexts

- (NSManagedObjectContext *const)newDerivedContext {
    NSManagedObjectContext *derived = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [derived performBlockAndWait:^{
        derived.parentContext = [self mainContext];
    }];
    
    return derived;
}

- (NSManagedObjectContext *const)mainContext {
    if (_mainContext) {
        return _mainContext;
    }
    
    _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _mainContext.persistentStoreCoordinator = [self persistentStoreCoordinator];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeChangesIntoMainContext:) name:NSManagedObjectContextDidSaveNotification object:self.backgroundContext];
    
    return _mainContext;
}

- (void)mergeChangesIntoMainContext:(NSNotification *)notification {
    [self.mainContext performBlock:^{
        NSLog(@"Merging main");
        [self.mainContext mergeChangesFromContextDidSaveNotification:notification];
        NSError *error;
        if (![self.mainContext save:&error]) {
            NSLog(@"Unresolved core data error saving main context after merge: %@", error);
#if DEBUG
            abort();
#endif
        }
    }];
}

- (NSManagedObjectContext *)backgroundContext {
    if (_backgroundContext) {
        return _backgroundContext;
    }
    _backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    _backgroundContext.persistentStoreCoordinator = [self persistentStoreCoordinator];
    return _backgroundContext;
}

- (NSFetchRequest *)fetchRequestTemplateForName:(NSString *)templateName {
    return [self.managedObjectModel fetchRequestTemplateForName:templateName];
}

#pragma mark - Context Saving

- (void)saveWithContext:(NSManagedObjectContext *)context {
    NSLog(@"Saving a context: %@", context);
    [context obtainPermanentIDsForObjects:context.insertedObjects.allObjects error:nil];
    [context performBlock:^{
        NSError *error;
        if (![context save:&error]) {
            NSLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
#if DEBUG
            abort();
#endif
        }
    }];
}

#pragma mark - Setup

- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"Model" ofType:@"momd"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSURL *storeURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:@"WordPress.sqlite"]];
	
	// This is important for automatic version migration. Leave it here!
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, nil];
	
	NSError *error = nil;
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error];
    
    return _persistentStoreCoordinator;
}

@end
