//
//  SLRViewController.m
//  SLRealtid
//
//  Created by Paul on 24/03/14.
//  Copyright (c) 2014 Paul. All rights reserved.
//

#import "SLRViewController.h"

@interface SLRViewController ()
@property NSArray *stations;
@property NSMutableArray *searchResults;


@end

@implementation SLRViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.stations = @[@"jakobsberg",@"centralen",@"spanga"];
    self.searchResults=[[NSMutableArray alloc]init];
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
    return [self.searchResults count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ListPrototypeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Display recipe in the table cell
    NSString *station = [self.searchResults objectAtIndex:indexPath.row];
    cell.textLabel.text = station;
    
    return cell;
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString];
    
    return  NO;
}
- (void)filterContentForSearchText:(NSString*)searchText{
    //NSLog(@"AAAA");
    //NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF beginswith %@", searchText];
    //self.searchResults = [self.stations filteredArrayUsingPredicate:resultPredicate];
    
    NSString *key=@"ac2159434219a6b27bd1e0c0f49e1bd3";
    NSString *urlString=[NSString stringWithFormat:@"https://api.trafiklab.se/sl/realtid/GetSite.json?stationSearch=%@&key=%@",[searchText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],key];
    
    //id result = [self getJSON:urlString error:error];
    [self getAsyncJSON:urlString completionHandler:^(id result) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            @try {
                [self.searchResults removeAllObjects];
                if (result == nil) return;
                NSMutableDictionary *dict=(NSMutableDictionary*)result;
                for (id station in [[[dict objectForKey:@"Hafas"] objectForKey:@"Sites"] objectForKey:@"Site"]) {
                    NSLog(@"%@",[station objectForKey:@"Name"]);
                    [self.searchResults addObject:[station objectForKey:@"Name"]];
                }
            }
            @catch (NSException *exception) {
                
            }
            @finally {
                [self.searchDisplayController.searchResultsTableView reloadData];
            }
        }];
    }];
    
    
    
}

- (id)getJSON:( NSString *)urlString error:(NSError *)error {
    NSURL *url=[NSURL URLWithString:urlString];
    NSURLRequest * urlRequest =[NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];
    
    
    NSURLResponse *response;
    NSData *urlData =[NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    if (urlData==nil) return nil;
    
    return [NSJSONSerialization JSONObjectWithData:urlData options:0 error:&error];
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
