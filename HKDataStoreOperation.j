//  Copyright (c) 2011 HoboCode
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//



//
//	Constants
//

kHKDataStoreOperationGET = 0;
kHKDataStoreOperationPOST = 1;
kHKDataStoreOperationPUT = 2;
kHKDataStoreOperationDELETE = 3;

//
//	Class implementation
//
@implementation HKDataStoreOperation : CPObject
{
	var type @accessors;
	var object @accessors;
}

+ (HKDataStoreOperation)operationWithType:(int)aType object:(id)anObject
{
	return [[HKDataStoreOperation alloc] initWithType:aType object:anObject];
}

- (id)initWithType:(int)aType object:(id)anObject
{
	if ( self = [super init] )
	{
		type = aType;
		object = anObject;
	}
	
	return self;
}

@end