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


@implementation HKURLRequestQueue : CPObject
{
    CPArray 		requests;
	var				idle;

	HKURLRequest	currentRequest;
	CPURLConnection	currentConnection;
	CPString		currentData;
	CPString		currentError;
	var				currentStatus;
}

- (id)init
{
	if ( self = [super init] )
	{
		requests = [[CPArray alloc] init];
		idle = true;
	}
	
	return self;
}

- (void)performRequest:(HKURLRequest)request
{
	if ( ![requests containsObject:request] )
	{
		[requests addObject:request];
	}
	
	[self handleNextRequest];
}

- (void)handleNextRequest
{
	console.log( "HKURLRequestQueue::handleNextRequest (idle='" + idle + "', requests='" + [requests count] + "')" );
	
	if ( [requests count] == 0 )
		return;
	
	if ( !idle )
		return;
		
	idle = false;
	
	currentRequest = [requests objectAtIndex:0]; [requests removeObjectAtIndex:0];
	
	console.log( "HKURLRequestQueue::handleNextRequest->Sending request (" + [currentRequest HTTPMethod] + "): " + [currentRequest URL] );
	
	currentConnection = [CPURLConnection connectionWithRequest:currentRequest delegate:self];
}

- (void)handleRequestResult
{
	var result = nil;
	
	console.log( "HKURLRequestQueue::handleRequestResult->Result ( status='" + currentStatus + "' )" );
	
	if ( (currentStatus < 200 || currentStatus >= 300) )
	{
		result = [HKURLResult resultWithSuccess:NO status:currentStatus object:nil error:currentError context:[currentRequest context]];
	}
	else
	{
		var object = nil;
		
		if ( currentData != "" )
		{
			try
			{
				object = [currentData objectFromJSON];
			}
			catch ( exception )
			{
			}
		}
		
		result = [HKURLResult resultWithSuccess:YES status:currentStatus object:object error:nil context:[currentRequest context]];
	}
	
	
	[currentRequest.target performSelector:currentRequest.selector withObject:result];
	
	[self cleanup];
	[self handleNextRequest];
}

- (void)cleanup
{
	currentConnection = nil;
	currentRequest = nil;
	currentData = nil;
	currentError = nil;
	currentStatus = nil;
	
	idle = true;
}

//
//	Delegate methods
//

- (void)connection:(CPURLConnection)connection didReceiveData:(CPString)data
{
//	console.log( "HKURLRequestQueue::connection:" + connection + ", didReceiveData:" + data );
	
	currentData = data;
	
	[self handleRequestResult];
}

- (void)connection:(CPURLConnection)connection didFailWithError:(CPString)error
{
	console.log( "HKURLRequestQueue::connection:" + connection + ", didFailWithError:" + error );
	
	currentError = error;
	
	[self handleRequestResult];
}

-(void)connection:(CPURLConnection)connection didReceiveResponse:(CPURLResponse)response
{
	console.log( "HKURLRequestQueue::connection:" + connection + ", didReceiveResponse:" + response );
	
    if ( [response isKindOfClass:[CPHTTPURLResponse class]] )
	{
		currentStatus = [response statusCode];
	}
}

@end