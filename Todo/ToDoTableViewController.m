//
//	Licensed under the Apache License, Version 2.0 (the "License");
//	you may not use this file except in compliance with the License.
//	You may obtain a copy of the License at
//
//	http://www.apache.org/licenses/LICENSE-2.0
//
//	Unless required by applicable law or agreed to in writing, software
//	distributed under the License is distributed on an "AS IS" BASIS,
//	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//	See the License for the specific language governing permissions and
//	limitations under the License.
//

#import "ToDoTableViewController.h"

#import <HRSCustomErrorHandling/HRSCustomErrorHandling.h>

#import "Todo.h"
#import "TodoFetcher.h"


@interface ToDoTableViewController () <TodoFetcherDelegate, UIAlertViewDelegate>

@property (nonatomic, strong, readwrite) TodoFetcher *fetcher;

@end


@implementation ToDoTableViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
	self = [super initWithStyle:style];
	if (self) {
		TodoFetcher *fetcher = [TodoFetcher sharedFetcher];
		fetcher.delegate = self;
		[fetcher fetch];
		_fetcher = fetcher;
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		TodoFetcher *fetcher = [TodoFetcher sharedFetcher];
		fetcher.delegate = self;
		[fetcher fetch];
		_fetcher = fetcher;
	}
	return self;
}

- (IBAction)addTodo:(id)sender {
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Add Todo" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
	alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
	[alertView show];
}



#pragma mark - alert view delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == alertView.cancelButtonIndex) {
		return;
	}
	
	NSString *title = [[alertView textFieldAtIndex:0] text];
	Todo *todo = [Todo todoWithTitle:title];
	[self.fetcher add:@[ todo ]];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fetcher.todos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"todo" forIndexPath:indexPath];
	
	Todo *todo = self.fetcher.todos[indexPath.row];
	
	NSDictionary *attributes;
	if (todo.isDone) {
		attributes = @{ NSStrikethroughStyleAttributeName: @(NSUnderlineStyleSingle) };
		cell.textLabel.textColor = [UIColor lightGrayColor];
	} else {
		cell.textLabel.textColor = [UIColor blackColor];
	}
	NSAttributedString *text = [[NSAttributedString alloc] initWithString:(todo.title ?: @"n/a") attributes:attributes];
	cell.textLabel.attributedText = text;
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	MutableTodo *todo = [self.fetcher.todos[indexPath.row] mutableCopy];
	todo.done = !todo.isDone;
	[self.fetcher add:@[ todo ]];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[self.fetcher remove:@[ self.fetcher.todos[indexPath.row] ]];
	}
}



#pragma mark - todo fetcher delegate

- (void)todoFetcherDidUpdateTodos:(TodoFetcher *)fetcher {
	if (self.isViewLoaded) {
		[self.tableView reloadData];
	}
}

- (void)todoFetcher:(TodoFetcher *)fetcher didFailWithError:(NSError *)error {
	HRSErrorRecoveryAttempter *recoveryAttempter = [HRSErrorRecoveryAttempter new];
	[recoveryAttempter addOkayRecoveryOption];
	
	NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
	userInfo[NSLocalizedFailureReasonErrorKey] = @"CloudKit error";
	userInfo[NSLocalizedRecoverySuggestionErrorKey] = error.description;
	userInfo[NSLocalizedRecoveryOptionsErrorKey] = recoveryAttempter.localizedRecoveryOptions;
	userInfo[NSRecoveryAttempterErrorKey] = recoveryAttempter;
	
	NSError *presentableError = [NSError errorWithDomain:error.domain code:error.code userInfo:[userInfo copy]];
	[self presentError:presentableError completionHandler:NULL];
	
	NSLog(@"Error: %@", error);
}

@end
