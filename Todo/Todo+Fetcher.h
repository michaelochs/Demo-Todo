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

#import "Todo.h"

@class CKRecord;


FOUNDATION_EXTERN NSString *const TodoRecordType;


@interface Todo (Fetcher)

@property (nonatomic, copy, readonly) CKRecord *record;

+ (instancetype)todoWithRecord:(CKRecord *)record;
- (instancetype)initWithRecord:(CKRecord *)record;

@end
