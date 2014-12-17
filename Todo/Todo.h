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

#import <Foundation/Foundation.h>


@interface Todo : NSObject <NSCopying, NSMutableCopying>

@property (nonatomic, assign, readonly, getter=isDone) BOOL done;
@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) NSDate *creationDate;
@property (nonatomic, strong, readonly) NSDate *modificationDate;

+ (instancetype)todoWithTitle:(NSString *)title;

@end


@interface MutableTodo : Todo

@property (nonatomic, assign, readwrite, getter=isDone) BOOL done;
@property (nonatomic, strong, readwrite) NSString *title;

@end
