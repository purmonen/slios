//
//  SLRViewController.m
//  SLRealtid
//
//  Created by Paul on 24/03/14.
//  Copyright (c) 2014 Paul. All rights reserved.
//

#import "SLRViewController.h"

@interface SLRViewController ()
@property NSMutableArray *stations;
@property NSMutableArray *searchResults;
@property NSString *lastSearhString;
@property NSString *SL_REALTID_API_KEY;

@end

@implementation SLRViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.stations = [[NSMutableArray alloc] init];
    self.searchResults = [[NSMutableArray alloc] init];
	self.SL_REALTID_API_KEY = @"ac2159434219a6b27bd1e0c0f49e1bd3";
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (self.tableView == tableView) {
        return [self.searchResults count];
    }
    return [self.stations count];
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
    if (tableView == self.tableView) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"DisplayCell"];
        NSMutableDictionary *departure = [self.searchResults objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", [departure objectForKey:@"LineNumber"], [departure objectForKey:@"DisplayTime"]];
    } else {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"SearchCell"];
        NSMutableDictionary *station = [self.stations objectAtIndex:indexPath.row];
        cell.textLabel.text = [station objectForKey:@"Name"];
	}
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView != self.tableView) {
    	NSLog(@"%@", [tableView cellForRowAtIndexPath:indexPath].textLabel.text);
        NSLog(@"%@", [self.stations objectAtIndex:indexPath.row]);

        [self.searchDisplayController setActive:NO animated:YES];
        [self getDeparturesById:[[self.stations objectAtIndex:indexPath.row] objectForKey:@"Number"]];
    }
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self getStationsByString:searchString];
    return  NO;
}

- (void)getDeparturesById:(NSString *)stationId {
    NSString *urlString = [NSString stringWithFormat:@"https://api.trafiklab.se/sl/realtid/GetDpsDepartures.json?siteId=%@&key=%@", stationId, self.SL_REALTID_API_KEY];
    [self getAsyncJSON:urlString completionHandler:^(id result) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            @try {
                [self.searchResults removeAllObjects];
                if (result == nil) return;
                NSMutableDictionary *dict=(NSMutableDictionary*)result;
                id stations = [[[dict objectForKey:@"DPS"] objectForKey:@"Buses"] objectForKey:@"DpsBus"];
                if ([stations isKindOfClass:[NSArray class]]) {
                    for (id station in stations) {
                        [self.searchResults addObject:station];
                    }
                } else {
                    [self.searchResults addObject:stations];
                }
            } @catch (NSException *exception) {
            } @finally {
                [self.tableView reloadData];
            }
        }];

    }];
}

- (void)getStationsByString:(NSString *)searchText {
    searchText = [searchText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *urlString=[NSString stringWithFormat:@"https://api.trafiklab.se/sl/realtid/GetSite.json?stationSearch=%@&key=%@", searchText, self.SL_REALTID_API_KEY];
    self.lastSearhString = searchText;
    //id result = [self getJSON:urlString error:error];
    [self getAsyncJSON:urlString completionHandler:^(id result) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (self.lastSearhString != searchText) return;
            @try {
                [self.stations removeAllObjects];
                if (result == nil) return;
                NSMutableDictionary *dict=(NSMutableDictionary*)result;
                
                id stations = [[[dict objectForKey:@"Hafas"] objectForKey:@"Sites"] objectForKey:@"Site"];
                
                if ([stations isKindOfClass:[NSArray class]]) {
                    for (id station in stations) {
                        [self.stations addObject:station];
                    }
                } else {
                    [self.stations addObject:stations];
                }
            } @catch (NSException *exception) {
            } @finally {
                [self.searchDisplayController.searchResultsTableView reloadData];
            }
        }];
    }];
}

- (void)getAsyncJSON:( NSString *)urlString completionHandler:(void (^)(id))completionHandler {
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest * request =[NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];
    
    
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	[NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (data == nil) {
            completionHandler(nil);
        } else {
        	id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&connectionError];
        	completionHandler(json);
        }
    }];
}




@end
