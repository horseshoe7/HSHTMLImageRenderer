//
//  UIColor+HS_HexStrings.h
//  HSHTMLImageRenderer
//
//  Created by Stephen O'Connor on 15/04/16.
//  Copyright © 2016 Software Barn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (HS_HexStrings)

+ (UIColor *)HS_colorWithHexString:(NSString *)hexString;
+ (NSString *)HS_hexValuesFromUIColor:(UIColor *)color;
- (NSString*)HS_hexString;

@end
