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


@implementation HKURLRequest : CPURLRequest
{
    CPDictionary	parameters @accessors;
	id				target @accessors;
	SEL				selector @accessors;
	id				context @accessors;
}

+ (id)requestWithURL:(CPURL)anUrl target:(id)aTarget selector:(SEL)aSelector context:(id)aContext
{
    return [[HKURLRequest alloc] initWithURL:anUrl target:aTarget selector:aSelector context:aContext];
}

- (id)initWithURL:(CPURL)anUrl target:(id)aTarget selector:(SEL)aSelector context:(id)aContext
{
    if ( self = [super initWithURL:anUrl] )
    {
        parameters = [[CPDictionary alloc] init];
		target = aTarget;
		selector = aSelector;
		context = aContext;
    }

    return self;
}

- (void)setParameter:(CPString)val forKey:(CPString)aKey
{
    [parameters setObject:val forKey:aKey];
}

- (void)setHTTPMethod:(CPString)aMethod
{
    [super setHTTPMethod:aMethod];

    if ( aMethod == @"POST" || aMethod == @"PUT" )
    {
        [self setValue:"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    }
    else
    {
        [self setValue:nil forHTTPHeaderField:@"Content-Type"];
    }
}

- (CPString)HTTPBody
{
    var content = @"";
    var method = [self HTTPMethod];

    if ( method == @"POST" || method == @"PUT" )
    {
        var key = nil;
        var value = nil;
        var enumerator = nil;

       	enumerator = [parameters keyEnumerator];

        while ( key = [enumerator nextObject] )
        {
            value = [parameters objectForKey:key];

            content = [content stringByAppendingString:[CPString stringWithFormat:@"%s=%s&", [key underscoreString], encodeURIComponent(value)]];
        }

        content = [content substringToIndex:[content length] - 1];
    }
    else
    {
        content = [super HTTPBody];
    }

    return content;
}

- (CPURL)URL
{
    var url = [[super URL] copy];

    return url;
}

@end