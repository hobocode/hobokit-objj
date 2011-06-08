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


@import <Foundation/CPURLConnection.j>

@implementation HKURLConnection : CPURLConnection
{
    Function receiveDataHandler;
    Function errorHandler;

    var _statusCode;
}

- (id)initWithRequest:(CPURLRequest)aRequest receiveDataHandler:(Function)aReceiveDataHandler errorHandler:(Function)anErrorHandler
{
    var conn = [HKURLConnection connectionWithRequest:aRequest delegate:self];
    receiveDataHandler = aReceiveDataHandler;
    errorHandler = anErrorHandler;
    return conn;
}

- (void)connection:(CPURLConnection)connection didReceiveData:(CPString)data
{
    if ( (_statusCode < 200 || _statusCode >= 300) )
    {
        if (errorHandler) {
            if ( errorHandler.length == 2 ) errorHandler( _statusCode, data )
            else errorHandler( data );
        }
    }
    else if ( receiveDataHandler )
    {
        if ( receiveDataHandler.length == 2 ) receiveDataHandler( _statusCode, data )
        else receiveDataHandler( data );
    }
/*    
    console.log("- (void)connection:(CPURLConnection)connection didReceiveData:(CPString)data");
    console.log("connection", connection);
*/
}

- (void)connection:(CPURLConnection)connection didFailWithError:(CPString)error
{
    if (errorHandler)
    {
        errorHandler(error);
    }
}

-(void)connection:(CPURLConnection)connection didReceiveResponse:(CPHTTPURLResponse)response
{
    //console.log("-(void)connection:(CPURLConnection)connection didReceiveResponse:(CPHTTPURLResponse)response");
    //console.log("response", response);
    _statusCode = [response statusCode];
}


@end