//
//  NSString+HS_HTMLTemplates.h
//  HSHTMLImageRenderer
//
//  Open-sourced with permission from qLearning Applications GmbH
//  Created by Stephen O'Connor on 15/04/16.
//  MIT License.  Hack away!
//

#import <Foundation/Foundation.h>

/* Add to these as you create more templates */
typedef NS_ENUM(NSInteger, HSHTMLTemplate) {
    HSHTMLTemplateDefault = 0
};

// you can use these named attributes, but their actual value is IN the template
// and must remain that to function correctly!!

extern NSString * const HSHTMLAttributeLineHeight;  // an NSNumber
extern NSString * const HSHTMLAttributeTargetWidth; // an NSNumber
extern NSString * const HSHTMLAttributeTextColor; // a UIColor object
extern NSString * const HSHTMLAttributeBackgroundColor; // a UIColor object
extern NSString * const HSHTMLAttributeFont; // a UIFont Object


@interface NSString (HS_HTMLTemplates)

+ (NSDictionary*)HS_defaultTemplateAttributes;

+ (NSString*)HS_presentationHTMLWithServerSnippetHTML:(NSString*)string
                                        usingTemplate:(HSHTMLTemplate)templateType
                                           attributes:(NSDictionary*)attributes;
+ (NSURL *)HS_defaultHtmlTemplateUrl;

+ (void)HS_finishUsingTemplates; // deletes some cached info

@end
