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

#import "Todo+Fetcher.h"

@import CloudKit;


NSString *const TodoRecordType = @"Todo";


@interface Todo ()

@property (nonatomic, copy, readwrite) CKRecord *record;

@end


@implementation Todo

@dynamic done, title, creationDate, modificationDate;

+ (instancetype)todoWithTitle:(NSString *)title {
	Todo *todo = [self new];
	todo.record[@"title"] = title;
	return todo;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_record = [[CKRecord alloc] initWithRecordType:TodoRecordType];
	}
	return self;
}



#pragma mark - nscopying

- (id)copyWithZone:(NSZone *)zone {
	if ([self isMemberOfClass:[Todo class]]) {
		// we are already immutable!
		return self;
	}
	
	Todo *copy = [[Todo allocWithZone:zone] init];
	copy.record = [self.record copy];
	return copy;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
	MutableTodo *copy = [[MutableTodo allocWithZone:zone] init];
	copy.record = [self.record copy];
	return copy;
}



#pragma mark - equality

- (BOOL)isEqual:(id)object {
	if ([object isKindOfClass:[Todo class]] == NO) {
		return NO;
	}
	return [self.record isEqual:[object record]];
}

- (NSUInteger)hash {
	return self.record.hash;
}



#pragma mark - accessors

- (BOOL)isDone {
	return [self.record[@"done"] boolValue];
}

- (NSString *)title {
	return self.record[@"title"];
}

- (NSDate *)creationDate {
	return self.record.creationDate;
}

- (NSDate *)modificationDate {
	return self.record.modificationDate;
}

@end


@implementation MutableTodo

- (void)setDone:(BOOL)done {
	self.record[@"done"] = @(done);
}

- (void)setTitle:(NSString *)title {
	self.record[@"title"] = title;
}

@end


@implementation Todo (Fetcher)

+ (instancetype)todoWithRecord:(CKRecord *)record {
	return [[self alloc] initWithRecord:record];
}

- (instancetype)initWithRecord:(CKRecord *)record {
	self = [super init];
	if (self) {
		_record = record;
	}
	return self;
}

@end
