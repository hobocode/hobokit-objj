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

HKDataStoreOperationGET = 0;
HKDataStoreOperationPOST = 1;
HKDataStoreOperationPUT = 2;
HKDataStoreOperationDELETE = 3;
HKDataStoreOperationFUNCTION = 4;
HKDataStoreOperationFUNCTIONPOST = 5;

//
//	Class implementation
//
@implementation HKDataStoreOperation : CPObject
{
	var type @accessors;
	var object @accessors;
	var parameters @accessors;
	var functionName @accessors;
}

+ (HKDataStoreOperation)operationWithType:(int)aType object:(id)anObject
{
	return [[HKDataStoreOperation alloc] initWithType:aType object:anObject];
}

+ (HKDataStoreOperation)operationWithType:(int)aType object:(id)anObject functionName:(CPString)aFunctionName parameters:(id)someParameters
{
	return [[HKDataStoreOperation alloc] initWithType:aType object:anObject functionName:aFunctionName parameters:someParameters];
}

- (id)initWithType:(int)aType object:(id)anObject
{
	return [self initWithType:aType object:anObject functionName:nil parameters:nil];
}

- (id)initWithType:(int)aType object:(id)anObject functionName:(CPString)aFunctionName parameters:(id)someParameters
{
	if ( self = [super init] )
	{
		type = aType;
		object = anObject;
		parameters = someParameters;
		functionName = aFunctionName;
	}
	
	return self;
}

@end