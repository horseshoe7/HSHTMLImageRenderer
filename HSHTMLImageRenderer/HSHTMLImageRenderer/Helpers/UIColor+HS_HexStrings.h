//
//  UIColor+HS_HexStrings.h
//  HSHTMLImageRenderer
//
//  Open-sourced with permission from qLearning Applications GmbH
//  Created by Stephen O'Connor on 15/04/16.
//  MIT License.  Hack away!
//

#import <UIKit/UIKit.h>

@interface UIColor (HS_HexStrings)

+ (UIColor *)HS_colorWithHexString:(NSString *)hexString;
+ (NSString *)HS_hexValuesFromUIColor:(UIColor *)color;
- (NSString*)HS_hexString;

@end
