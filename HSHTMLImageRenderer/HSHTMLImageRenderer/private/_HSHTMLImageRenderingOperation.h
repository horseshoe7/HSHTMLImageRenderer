//
//  HSHTMLImageRenderingOperation.h
//  HSHTMLImageRenderer
//
//  Open-sourced with permission from qLearning Applications GmbH
//  Created by Stephen O'Connor on 15/04/16.
//  MIT License.  Hack away!
//

/*
 
 ABOUT THIS CLASS.  IT'S A PRIVATE CLASS THAT IS USED BY HSHTMLImageRenderer.
 
 */

#import "_HSAsyncOperation.h"
#import "NSString+HS_HTMLTemplates.h"
#import "HSHTMLImageRenderer.h"

// these are used by private classes.
extern NSString * const HSHTMLImageRendererUserInfoKeyImage;
extern NSString * const HSHTMLImageRendererUserInfoKeyWasCached;
extern NSString * const HSHTMLImageRendererUserInfoKeyIdentifier;



@interface _HSHTMLImageRenderingOperation : _HSAsyncOperation
{
@public
    NSString *_htmlToLoad;
    HSHTMLImageRenderingIntent _intent;
    NSDictionary *_attributes;
    NSString *_identifier;
    BOOL _ignoreCache;
    BOOL _shouldCache;
    NSMutableDictionary *_userInfo;
    
    NSDate *_startTime;
    
    NSUInteger _operationIndex;
}
@property (nonatomic, weak) HSHTMLImageRenderer *renderer;
@property (nonatomic, assign) CGSize contentSize;

- (instancetype)initWithHTML:(NSString*)htmlToLoad
                  identifier:(NSString*)identifier
                      intent:(HSHTMLImageRenderingIntent)intent
                  attributes:(NSDictionary*)attributes
                    renderer:(HSHTMLImageRenderer*)renderer
          ignoreCachedResult:(BOOL)ignoreCache
           shouldCacheResult:(BOOL)cacheResult
                  completion:(HSOperationCompletionBlock)completion;


// you call this from a UIWebViewDelegate
- (void)completedLoadingWebView:(UIWebView*)webview;
- (void)failedLoadingWebView:(NSError*)error;

+ (NSString*)fileBasePath;

@end
