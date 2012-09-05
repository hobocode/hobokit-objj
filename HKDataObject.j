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
//	Class implementation
//
@implementation HKDataObject : CPObject
{
	int oid @accessors;
	BOOL sync @accessors;
}

+ (CPSet)attributesToObserve
{
	return [CPSet setWithObject:@"sync"];
}

+ (CPSet)attributesReadOnly
{
    return [CPSet set];
}

+ (CPString)baseURL
{
	return nil;
}

+ (BOOL)readOnly
{
    return NO;
}

//
//	Init
//
- (id)init
{
	if ( self = [super init] )
	{
		oid = -1;
		sync = YES;
	}

	return self;
}

- (void)setupFromJSON:(JSObject)json
{
	[self setOid:json.id];
}

- (CPString)instanceURL
{
	return nil;
}

- (void)callFunctionWithName:(CPString)functionName parameters:(CPArray)parameters
{
    [[HKDataStore sharedDataStore] queueOperation:[HKDataStoreOperation operationWithType:HKDataStoreOperationFUNCTION object:self functionName:functionName parameters:parameters]];
}

- (void)callPOSTFunctionWithName:(CPString)functionName parameters:(CPDictionary)parameters
{
    [[HKDataStore sharedDataStore] queueOperation:[HKDataStoreOperation operationWithType:HKDataStoreOperationFUNCTIONPOST object:self functionName:functionName parameters:parameters]];
}

- (void)callGETOBJECTSFunctionWithName:(CPString)functionName objectClass:(Class)oclass parameters:(CPArray)parameters
{
    [[HKDataStore sharedDataStore] queueOperation:[HKDataStoreOperation operationWithType:HKDataStoreOperationFUNCTIONGETOBJECTS object:self functionName:functionName parameters:parameters metadata:oclass]];
}


- (unsigned)hash
{
	if ( oid == -1 )
		return [super hash];

	return oid;
}

- (BOOL)isEqual:(id)another
{
	return ( self === another || [self hash] === [another hash] );
}

- (CPString)UID
{
	if ( oid == -1 )
		return [super UID];

	return oid;
}

@end
