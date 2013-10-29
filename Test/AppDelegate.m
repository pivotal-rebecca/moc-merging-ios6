//
//  AppDelegate.m
//  Test
//
//  Created by DX074-XL on 2013-10-29.
//  Copyright (c) 2013 Pivotal Labs. All rights reserved.
//

#import "AppDelegate.h"
#import "Thing.h"
#import "ContextManager.h"

@interface Awesome : UITableViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) NSFetchedResultsController *r;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UIViewController *hello = [Awesome new];
    self.window.rootViewController = hello;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {}

- (void)applicationDidEnterBackground:(UIApplication *)application {}

- (void)applicationWillEnterForeground:(UIApplication *)application {}

- (void)applicationDidBecomeActive:(UIApplication *)application {}

- (void)applicationWillTerminate:(UIApplication *)application {}

@end

@implementation Awesome
static NSString *const idCell = @"thingCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:idCell];
    
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"Thing"];
    fetch.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    _r = [[NSFetchedResultsController alloc] initWithFetchRequest:fetch managedObjectContext:[ContextManager sharedInstance].mainContext sectionNameKeyPath:nil cacheName:nil];
    _r.delegate = self;
    [_r performFetch:nil];
    
    [self insertNew];
}

- (void)insertNew {
    [[ContextManager sharedInstance].backgroundContext performBlock:^{
        Thing *new = [NSEntityDescription insertNewObjectForEntityForName:@"Thing" inManagedObjectContext:[ContextManager sharedInstance].backgroundContext];
        new.name = @"awesome";
        [[ContextManager sharedInstance] saveWithContext:[ContextManager sharedInstance].backgroundContext];
    }];
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self insertNew];
    });
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_r.fetchedObjects count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:idCell];
    cell.textLabel.text = [_r.fetchedObjects[indexPath.row] name];
    return cell;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView reloadData];
}

@end
