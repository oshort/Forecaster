//
//  MasterViewController.m
//  Weather
//
//  Created by Tom Williamson on 5/5/16.
//  Copyright © 2016 Tom Williamson. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "CityViewController.h"
#import "City.h"
#import "MasterCell.h"
#import "DictionaryViewController.h"

@interface MasterViewController ()

@end

@implementation MasterViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.title = @"Forecaster";
    //
    //   sets background image and makes transparent navigation bar based on time of day
    //
    NSDate *now = [[NSDate alloc]init];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"HH"];
    NSString *aDate = [formatter stringFromDate:now];
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterNoStyle;
    NSNumber *hour = [numberFormatter numberFromString:aDate];
    NSNumber *limit = @18;
    if (hour < limit){
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background-day"]];
    }else{
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background-night"]];
    }
    

    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barStyle = UIStatusBarStyleLightContent;
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    //
    //  setup action for table pulldown
    //
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    if (hour < limit){
        self.refreshControl.backgroundColor = [UIColor colorWithRed:31/255.0 green:105/255.0 blue:130/255.0 alpha:1.0];
    }else{
        self.refreshControl.backgroundColor = [UIColor colorWithRed:143/255.0 green:76/255.0 blue:160/255.0 alpha:1.0];
    }
    
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(getAllForecast)
                  forControlEvents:UIControlEventValueChanged];
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
    
}

-(void)getAllForecast{

    for (City *city in [self.fetchedResultsController fetchedObjects]) {
        [city updateForecast:nil];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    dateFormatter.doesRelativeDateFormatting = YES;
    NSString *title = [NSString stringWithFormat:@"Last update: %@", [dateFormatter stringFromDate:[NSDate date]]];
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                                forKey:NSForegroundColorAttributeName];
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
    self.refreshControl.attributedTitle = attributedTitle;
    
    [self.refreshControl endRefreshing];

    
}


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    //
    //  go to city detail view controller
    //
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        [controller setDetailItem:object];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
        
    }
    
    //
    //  go to the new city view controller
    //
    else if ([[segue identifier] isEqualToString:@"showCity"]) {
        CityViewController *controller = (CityViewController *)[[segue destinationViewController] topViewController];
        controller.managedObjectContext = self.managedObjectContext;
        
    }
    
    //
    //  go to the dictionary controller
    //
    else if ([[segue identifier] isEqualToString:@"showDict"]) {
        DictionaryViewController *controller = (DictionaryViewController *)[[segue destinationViewController] topViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        City *city = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        controller.mTitle = city.name;
        NSArray *keys = [[[city entity] attributesByName] allKeys];
        NSDictionary *dict = [city dictionaryWithValuesForKeys:keys];
        controller.dictionary = dict;
        
    }

    
}

//
//  see if we got a new city from the new city view controller
//
-(IBAction)unwindNewCity:(UIStoryboardSegue *)segue {
    
    CityViewController *cvc = (CityViewController *)[segue sourceViewController];
    
    if (cvc.city.name.length > 0){
        
        [self.managedObjectContext insertObject:cvc.city];
        City *lastCity = [self.fetchedResultsController.fetchedObjects lastObject];
        short lastOrder = [lastCity.displayOrder integerValue];
        cvc.city.displayOrder = [NSNumber numberWithInt:lastOrder + 1];
        [cvc.city save];
        cvc.city.doSave = YES;
        [cvc.city updateForecast:nil];
        
    }
    
    
}

#pragma mark - Table View

//
//  one section for each section in managed object
//
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return [[self.fetchedResultsController sections] count];
    
}

//
//  one row in table for each row in managed set
//
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
    
}

//
//  build cell for table
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    
    //
    // Remove the bottom cell dividing lines NICK
    //
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    //self.tableView.separatorColor = [UIColor colorWithWhite:.5 alpha:.8];
    
    [self configureCell:cell withObject:object];
    
    return cell;
    
}

//
//  allow edit
//
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return YES;
    
}


//
//  see if we are removing a row and we need to delete the managed object
//
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
            
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
            
        }
    }
}

//
//  build cell for table
//
- (void)configureCell:(UITableViewCell *)cell withObject:(NSManagedObject *)object {
    
    City *city = (City*)object;
    MasterCell *mcell = (MasterCell*)cell;
    
    mcell.showsReorderControl = YES;
    mcell.cityLabel.text = city.city;
    mcell.forecastLabel.text = city.summary;
    mcell.tempLabel.text = [NSString stringWithFormat:@"%ld\u00B0", [city.temperature integerValue]];
    mcell.backgroundColor = [UIColor colorWithWhite:.3 alpha:.3];
    [mcell.contentView.layer setBorderColor:[UIColor colorWithWhite:.4 alpha:.3].CGColor];
    [mcell.contentView.layer setBorderWidth:0.5f];
    
    //
    //  updated time
    //
    NSDate* now = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    dateFormatter.doesRelativeDateFormatting = YES;
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:city.timezone];
    NSLog(@"%@", city.timezone);
    NSString *time = [dateFormatter stringFromDate:now];
    mcell.timeLabel.text = [NSString stringWithFormat:@"%@", time];
    mcell.iconImage.image = [UIImage imageNamed:city.icon];
    
}


//
//  rows in table are going to be moved
//
//  adjust the display order 
//
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath
      toIndexPath:(NSIndexPath *)destinationIndexPath {
    
    self.fetchedResultsController.delegate = nil;
    
    NSMutableArray *sortedList = [[self.fetchedResultsController fetchedObjects] mutableCopy];
    
    // Object we are moving
    City *cityWeAreMoving = [sortedList objectAtIndex:sourceIndexPath.row];
    
    // remove object from its current position
    [sortedList removeObject:cityWeAreMoving];
    
    // Insert it at it's new position
    [sortedList insertObject:cityWeAreMoving atIndex:destinationIndexPath.row];
    
    // Update the order of them all according to their index in the mutable array
    int i = 0;
    for (City *c in sortedList) {
        NSLog(@"%i - %@", i, c.name);
        c.displayOrder = [NSNumber numberWithInt: i++];
    }
    
    // Save the managed object context and redo the query
    [self.managedObjectContext save:nil];
    self.fetchedResultsController = nil;
    NSFetchedResultsController *x = self.fetchedResultsController;
    
    self.fetchedResultsController.delegate = self;
    
}

#pragma mark - Fetched results controller

//
//  init the fetched results container
//
- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"City" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];

    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}    


//
//  start table updates
//
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {

    [self.tableView beginUpdates];
    
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            return;
    }
}


//
//  the object changed so update the right table cell
//
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {

    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] withObject:anObject];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller{

    [self.tableView endUpdates];
    
}



@end
