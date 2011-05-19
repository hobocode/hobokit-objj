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


@implementation HKGradientView : CPView
{
    CGGradient  gradient;
    CPArray     colors;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if ( self = [super initWithFrame:aFrame] )
    {
        colors = [[CPArray alloc] init];
    }
    return self;
}

- (void)addColor:(CPColor)aColor
{
    gradient = nil;
    [colors addObject:aColor];
}

- (void)drawRect:(CGRect)rect 
{
    if ( gradient == nil )
    {
        var comps = [],
            pos = [],
            count = [colors count],
            spl = 1/(count-1);

        if ( count < 2 )
        {
            [CPException raise:"HKGradientViewException" reason:"You must specify at least two colors."];
        }

        for ( var i = 0; i < count; i++ )
        {
            var c = colors[i];
            comps.push([c redComponent]);
            comps.push([c greenComponent]);
            comps.push([c blueComponent]);
            comps.push([c alphaComponent]);
            pos.push(i*spl);
        }

        gradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), comps, [0,1], count);
    }

    var targetPoint = CGPointMake(0, CGRectGetHeight(rect)),
        context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextAddRect(context, rect);
    CGContextDrawLinearGradient(context, gradient, CGPointMake(0,0), targetPoint);
}

@end