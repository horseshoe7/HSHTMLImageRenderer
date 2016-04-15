//
//  NSString+HS_HTMLTemplates.m
//  HSHTMLImageRenderer
//
//  Created by Stephen O'Connor on 15/04/16.
//  Copyright © 2016 Software Barn. All rights reserved.
//

#import "NSString+HS_HTMLTemplates.h"
#import <UIKit/UIKit.h>
#import "UIColor+HS_HexStrings.h"

static NSString * DefaultTemplate = nil;

// these values have to appear as such in the template!!
NSString * const HSHTMLAttributeLineHeight = @"__LINE_HEIGHT__";  // a float
NSString * const HSHTMLAttributeFontSize = @"__FONT_SIZE__";  // an int

NSString * const HSHTMLAttributeTextColor = @"__TEXT_COLOR__";
NSString * const HSHTMLAttributeBackgroundColor = @"__BACKGROUND_COLOR__";  // a UIColor object
NSString * const HSHTMLAttributeTargetWidth = @"__OUTPUT_WIDTH__";  // an int
static NSString * const HSHTMLTemplateAttributeBodyText = @"__HTML_BODY__";
static NSString * const HSHTMLTemplateAttributeFontFamily = @"__FONT_FAMILY__";

// these are arbitrary key names
NSString * const HSHTMLAttributeFont = @"TemplateFont";  // an int




@implementation NSString (HS_HTMLTemplates)

+ (NSDictionary*)HS_defaultTemplateAttributes
{
    return @{
             HSHTMLAttributeLineHeight : @(1.0f),
             HSHTMLAttributeFont : [UIFont systemFontOfSize:16],
             HSHTMLAttributeTextColor : [UIColor blackColor],
             HSHTMLAttributeBackgroundColor : [UIColor whiteColor],
             HSHTMLAttributeTargetWidth : @(300)
             };
}

+ (NSString*)HS_presentationHTMLWithServerSnippetHTML:(NSString*)snippet
                                        usingTemplate:(HSHTMLTemplate)templateType
                                           attributes:(NSDictionary*)attributes
{
    NSString *templateString;
    
    
    switch (templateType) {

        // set up for future work... add your cases here!
            
        default:
        {
            templateString = [self HS_defaultHtmlTemplate];
            BOOL ok = [self HS_validateTemplate:templateString type:templateType];
            NSAssert(ok, @"You must have changed the template spec since this class was written.  Well, now you get to sort out the mess you've made.  :)");
            
            return [self HS_stylizedHTMLForInputSnippet:snippet usingTemplate:templateString type:templateType attributes:attributes];
        }
    }
    
    return snippet;
}

#pragma mark - Template Loaders

+ (NSString *)HS_defaultHtmlTemplate
{
    if (!DefaultTemplate) {
        DefaultTemplate = [NSString stringWithContentsOfURL:[self HS_defaultHtmlTemplateUrl]
                                                   encoding:NSUTF8StringEncoding error:nil];
    }
    
    return DefaultTemplate.copy;
}


+ (NSURL *)HS_defaultHtmlTemplateUrl
{
    return [NSURL fileURLWithPath:[[NSBundle mainBundle]
                                   pathForResource:@"default_template"
                                   ofType:@"html"
                                   inDirectory:nil]];
}

#pragma mark - Template Validation

+ (BOOL)HS_validateTemplate:(NSString*)templateString type:(HSHTMLTemplate)templateType
{
    switch (templateType) {
            
        default:
            return [self HS_validateDefaultTemplate:templateString];
            break;
    }
    return NO;
}

+ (BOOL)HS_validateDefaultTemplate:(NSString*)templateString
{
    // check for occurrences of the constants above!
    NSRange testRange;
    
    NSArray *parametersInTemplate = @[
                                      HSHTMLAttributeLineHeight,
                                      HSHTMLAttributeFontSize,
                                      HSHTMLAttributeTargetWidth,
                                      HSHTMLAttributeTextColor,
                                      HSHTMLAttributeBackgroundColor,
                                      HSHTMLTemplateAttributeBodyText,
                                      HSHTMLTemplateAttributeFontFamily
                                      ];
    
    for (NSString *parameter in parametersInTemplate) {
        
        testRange = [templateString rangeOfString:parameter];
        if(testRange.location == NSNotFound)
        {
            NSLog(@"The Template is supposed to have a settable %@", parameter);
            return NO;
        }
    }
    
    return YES;
}

+ (void)HS_finishUsingTemplates
{
    DefaultTemplate = nil;  // no need to keep a reference to a string around if you don't need to!
}

#pragma mark - The Meat

+ (NSString*)HS_stylizedHTMLForInputSnippet:(NSString*)snippet
                              usingTemplate:(NSString*)template
                                       type:(HSHTMLTemplate)templateType
                                 attributes:(NSDictionary*)attributes
{
    
    // required attributes
    NSNumber *lineHeight = attributes[HSHTMLAttributeLineHeight];
    UIColor *textColor = attributes[HSHTMLAttributeTextColor];
    UIColor *backgroundColor = attributes[HSHTMLAttributeBackgroundColor];
    UIFont *font = attributes[HSHTMLAttributeFont];
    NSNumber *targetWidth = attributes[HSHTMLAttributeTargetWidth];
    
    
    
    // you should have based your attributes off of +defaultAttributes.  We just check that  you did.
    NSAssert(lineHeight, @"You are missing some drawing attributes.  Did you make sure your operation class merges your attributes into defaultAttributes?");
    NSAssert(textColor, @"You are missing some drawing attributes.  Did you make sure your operation class merges your attributes into defaultAttributes?");
    NSAssert(backgroundColor, @"You are missing some drawing attributes.  Did you make sure your operation class merges your attributes into defaultAttributes?");
    NSAssert(font, @"You are missing some drawing attributes.  Did you make sure your operation class merges your attributes into defaultAttributes?");
    NSAssert(targetWidth, @"You are missing some drawing attributes.  Did you make sure your operation class merges your attributes into defaultAttributes?");
    
    
    // derived attributes
    NSString *fontFamily = font.familyName;  // @"\"Helvetica\", \"Arial\", \"Sans-Serif\""; // original
    NSString *textColorHexString = textColor.HS_hexString;
    NSString *backgroundColorHexString = backgroundColor.HS_hexString;
    
    
    // NOW PUT THOSE IN and return the result
    
    //text size
    template = [template stringByReplacingOccurrencesOfString:HSHTMLAttributeLineHeight
                                                   withString:[NSString stringWithFormat:@"%.1f", lineHeight.floatValue]];
    // font
    template = [template stringByReplacingOccurrencesOfString:HSHTMLAttributeFontSize
                                                   withString:[NSString stringWithFormat:@"%i", (int)font.pointSize]];
    // font
    template = [template stringByReplacingOccurrencesOfString:HSHTMLTemplateAttributeFontFamily
                                                   withString:fontFamily];
    // output
    template = [template stringByReplacingOccurrencesOfString:HSHTMLAttributeTargetWidth
                                                   withString:[NSString stringWithFormat:@"%i", targetWidth.intValue]];
    // colors
    template = [template stringByReplacingOccurrencesOfString:HSHTMLAttributeTextColor
                                                   withString:[NSString stringWithFormat:@"#%@", textColorHexString]];
    
    template = [template stringByReplacingOccurrencesOfString:HSHTMLAttributeBackgroundColor
                                                   withString:[NSString stringWithFormat:@"#%@", backgroundColorHexString]];
    
    // now the body text
    template = [template stringByReplacingOccurrencesOfString:HSHTMLTemplateAttributeBodyText
                                                   withString:snippet];
    
    return template;
}


@end
