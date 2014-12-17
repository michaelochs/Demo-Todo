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

#import "TodoFetcher.h"

#import "Todo+Fetcher.h"

@import CloudKit;


@interface TodoFetcher ()

@property (nonatomic, strong, readwrite) CKDatabase *database;

@end


@implementation TodoFetcher

@synthesize todos = _todos;

+ (instancetype)sharedFetcher {
	static TodoFetcher *fetcher;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		fetcher = [TodoFetcher new];
	});
	return fetcher;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_database = [[CKContainer defaultContainer] publicCloudDatabase];
	}
	return self;
}

- (void)registerSubscriptions {
	CKSubscription *subscription = [[CKSubscription alloc] initWithRecordType:TodoRecordType predicate:[NSPredicate predicateWithValue:YES] options:(CKSubscriptionOptionsFiresOnRecordUpdate | CKSubscriptionOptionsFiresOnRecordDeletion | CKSubscriptionOptionsFiresOnRecordCreation)];
	CKNotificationInfo *notificationInfo = [CKNotificationInfo new];
	notificationInfo.shouldSendContentAvailable = YES;
	subscription.notificationInfo = notificationInfo;
	[self.database saveSubscription:subscription completionHandler:^(CKSubscription *subscription, NSError *error) {
		if (error) {
			[self reportDidFailWithError:error];
			return;
		}
	}];
}

- (void)fetch {
	[self fetch:NULL];
}

- (void)fetch:(void(^)(NSError *error))completionHandler {
	CKDatabase *database = self.database;
	
	NSPredicate *predicate = [NSPredicate predicateWithValue:YES];
	CKQuery *query = [[CKQuery alloc] initWithRecordType:TodoRecordType predicate:predicate];
	[database performQuery:query inZoneWithID:nil completionHandler:^(NSArray *results, NSError *error) {
		if (error) {
			[self reportDidFailWithError:error];
			dispatch_async(dispatch_get_main_queue(), ^{
				if (completionHandler) {
					completionHandler(error);
				}
			});
			return;
		}
		NSMutableArray *todos = [NSMutableArray arrayWithCapacity:results.count];
		for (CKRecord *record in results) {
			Todo *todo = [Todo todoWithRecord:record];
			[todos addObject:todo];
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			_todos = todos;
			[self reportDidUpdateTodos];
			if (completionHandler) {
				completionHandler(nil);
			}
		});
	}];
}

- (void)add:(NSArray *)todos {
	CKDatabase *database = self.database;
	
	for (Todo *todo in todos) {
		CKRecord *record = [todo record];
		CKModifyRecordsOperation *operation = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[ record ] recordIDsToDelete:nil];
		operation.savePolicy = CKRecordSaveChangedKeys;
		[operation setPerRecordCompletionBlock:^(CKRecord *record, NSError *error) {
			if (error) {
				[self reportDidFailWithError:error];
				return;
			}
			Todo *todo = [Todo todoWithRecord:record];
			[self mergeTodoArrayWithArray:@[ todo ]];
		}];
		[database addOperation:operation];
	}
}

- (void)remove:(NSArray *)todos {
	CKDatabase *database = self.database;
	
	for (Todo *todo in todos) {
		CKRecord *record = [todo record];
		[database deleteRecordWithID:record.recordID completionHandler:^(CKRecordID *recordID, NSError *error) {
			if (error) {
				[self reportDidFailWithError:error];
				return;
			}
			NSMutableArray *todos = [self.todos mutableCopy];
			NSInteger index = [self.todos indexOfObject:todo];
			if (index != NSNotFound) {
				[todos removeObjectAtIndex:index];
			}
			dispatch_async(dispatch_get_main_queue(), ^{
				_todos = [todos copy];
				[self reportDidUpdateTodos];
			});
		}];
	}
}



#pragma mark - delegation

- (void)reportDidFailWithError:(NSError *)error {
	dispatch_async(dispatch_get_main_queue(), ^{
		if ([self.delegate respondsToSelector:@selector(todoFetcher:didFailWithError:)]) {
			[self.delegate todoFetcher:self didFailWithError:error];
		}
	});
}

- (void)reportDidUpdateTodos {
	dispatch_async(dispatch_get_main_queue(), ^{
		if ([self.delegate respondsToSelector:@selector(todoFetcherDidUpdateTodos:)]) {
			[self.delegate todoFetcherDidUpdateTodos:self];
		}
	});
}



#pragma mark - array handling

- (void)mergeTodoArrayWithArray:(NSArray *)array {
	dispatch_async(dispatch_get_main_queue(), ^{
		if (array.count == 0) {
			return;
		}
		NSArray *currentTodos = [NSArray arrayWithArray:_todos];
		NSArray *recordNames = [array valueForKeyPath:@"record.recordID.recordName"];
		NSMutableArray *todos = [[currentTodos filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT record.recordID.recordName IN %@", recordNames]] mutableCopy];
		[todos addObjectsFromArray:array];
		
		NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:YES];
		[todos sortUsingDescriptors:@[ sortDescriptor ]];
		_todos = [todos copy];
		[self reportDidUpdateTodos];
	});
}

@end
