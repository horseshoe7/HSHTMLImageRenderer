//
//  UIColor+HS_HexStrings.m
//  HSHTMLImageRenderer
//
//  Created by Stephen O'Connor on 15/04/16.
//  Copyright © 2016 Software Barn. All rights reserved.
//

#import "UIColor+HS_HexStrings.h"


@implementation UIColor (HS_HexStrings)

+ (UIColor *)HS_colorWithHexString:(NSString *)hexString
{
    if ([hexString hasPrefix:@"#"]) {
        hexString = [hexString substringFromIndex:1];
    }
    
    if (([hexString length] == 6 || [hexString length] == 8) == NO ) {
        return nil;
    }
    
    // Brutal and not-very elegant test for non hex-numeric characters
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^a-fA-F|0-9]" options:0 error:NULL];
    NSUInteger match = [regex numberOfMatchesInString:hexString options:NSMatchingReportCompletion range:NSMakeRange(0, [hexString length])];
    
    if (match != 0) {
        return nil;
    }
    
    NSRange rRange = NSMakeRange(0, 2);
    NSString *rComponent = [hexString substringWithRange:rRange];
    unsigned int rVal = 0;
    NSScanner *rScanner = [NSScanner scannerWithString:rComponent];
    [rScanner scanHexInt:&rVal];
    float rRetVal = (float)rVal / 254;
    
    
    NSRange gRange = NSMakeRange(2, 2);
    NSString *gComponent = [hexString substringWithRange:gRange];
    unsigned int gVal = 0;
    NSScanner *gScanner = [NSScanner scannerWithString:gComponent];
    [gScanner scanHexInt:&gVal];
    float gRetVal = (float)gVal / 254;
    
    NSRange bRange = NSMakeRange(4, 2);
    NSString *bComponent = [hexString substringWithRange:bRange];
    unsigned int bVal = 0;
    NSScanner *bScanner = [NSScanner scannerWithString:bComponent];
    [bScanner scanHexInt:&bVal];
    float bRetVal = (float)bVal / 254;
    
    float aRetVal = 1.0f;
    if (hexString.length == 8) {
        NSRange aRange = NSMakeRange(6, 2);
        NSString *aComponent = [hexString substringWithRange:aRange];
        unsigned int aVal = 0;
        NSScanner *bScanner = [NSScanner scannerWithString:aComponent];
        [bScanner scanHexInt:&aVal];
        aRetVal = (float)aVal / 254;
    }
    
    return [UIColor colorWithRed:rRetVal green:gRetVal blue:bRetVal alpha:aRetVal];
    
}

+ (NSString *)HS_hexValuesFromUIColor:(UIColor *)color {
    
    if (!color) {
        return nil;
    }
    
    if ([color HS_isEqualToColor:[UIColor whiteColor]]) {
        // Special case, as white doesn't fall into the RGB color space
        return @"ffffff";
    }
    
    CGFloat red;
    CGFloat blue;
    CGFloat green;
    CGFloat alpha;
    
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    int redDec = (int)(red * 255);
    int greenDec = (int)(green * 255);
    int blueDec = (int)(blue * 255);
    int alphaDec = (int)(alpha * 255);
    
    NSString *returnString = nil;
    
    
    if (alphaDec == 255)
    {
        returnString = [NSString stringWithFormat:@"%02x%02x%02x", (unsigned int)redDec, (unsigned int)greenDec, (unsigned int)blueDec];
    }
    else
    {
        // returns RGBA
        returnString = [NSString stringWithFormat:@"%02x%02x%02x%02x", (unsigned int)redDec, (unsigned int)greenDec, (unsigned int)blueDec, (unsigned int)alphaDec];
    }
    
    return returnString;
    
}

- (NSString*)HS_hexString
{
    return [UIColor HS_hexValuesFromUIColor:self];
}

- (BOOL)HS_isEqualToColor:(UIColor*)otherColor
{
    
    if (self == otherColor)
        return YES;
    
    CGColorSpaceRef colorSpaceRGB = CGColorSpaceCreateDeviceRGB();
    
    UIColor *(^convertColorToRGBSpace)(UIColor*) = ^(UIColor *color)
    {
        if (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) == kCGColorSpaceModelMonochrome)
        {
            const CGFloat *oldComponents = CGColorGetComponents(color.CGColor);
            CGFloat components[4] = {oldComponents[0], oldComponents[0], oldComponents[0], oldComponents[1]};
            CGColorRef colorRef = CGColorCreate(colorSpaceRGB, components);
            UIColor *color = [UIColor colorWithCGColor:colorRef];
            CGColorRelease(colorRef);
            return color;
        }
        else
            return color;
    };
    
    UIColor *selfColor = convertColorToRGBSpace(self);
    otherColor = convertColorToRGBSpace(otherColor);
    CGColorSpaceRelease(colorSpaceRGB);
    
    return [selfColor isEqual:otherColor];
}

@end
