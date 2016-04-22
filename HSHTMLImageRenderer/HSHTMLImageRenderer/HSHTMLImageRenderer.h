//
//  HSHTMLImageRenderer.h
//  HSHTMLImageRenderer
//
//  Open-sourced with permission from qLearning Applications GmbH
//  Created by Stephen O'Connor on 12/04/16.
//  MIT License.  Hack away!
//

/*
 
 ABOUT THIS CLASS:
 
 So this class is a little dirty in its approach, but at least it's self-contained.  That's all we as programmers can ask of anything smelly...
 
 I had a situation where I was being delivered snippets of arbitary HTML that had to be rendered.  Content that goes beyond just rich text.  
 Content that even goes beyond rich text and images.  Sometimes rendering SVG's and Math Equations.
 
 The iPhone is not a web browser.  And UIWebViews are expensive to create.   And the HTML content might be complicated in that the server delivers the body, and the client is supposed to style it.  So it just seemed easier to render this content asynchronously and pre-cache it, rather than try to render HTML when needed.
 
 This class aims to do that.  It wraps an NSOperationQueue and has NSOperations that take care of all the work.  Unfortunately it can't all be done in the background because UIKit classes need to have their methods called from the main thread.  So the actual method call of generating an image of the UIWebView is done on the main thread.  You may need to find a good strategy for generating this cached content.  You can't avoid the performance hit, but you CAN minimize it.
 
 If you use Core Data, it would also make sense to add a transient property on the data model that provided the html content that you want to render.  You'll have to play with that.  Ultimately the images are in a NSCache against the 'identifier' property.
 
 You create ONE instance of this class, then call the one method.  Provide an identifier so to give your render call some context.  This identifier is passed back in the completion block, so you know where it came from.
 
 */


#import <Foundation/Foundation.h>
#import "NSString+HS_HTMLTemplates.h"
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, HSHTMLImageRenderingIntent) {
    HSHTMLImageRenderingIntentDefault = 0
    
    // extend this as your needs change
};



// DEBUG / DEVELOPMENT
static BOOL const HSHTMLImageRendererWriteHTMLToDisk = NO;  // will write the template-converted files to disk, so that you can inspect and debug them in a browser, just to be sure.  Intended for the iOS Simulator.




@interface HSHTMLImageRenderer : NSObject


+ (instancetype)rendererInWindow:(UIWindow*)window;  // call this the first time
+ (instancetype)renderer;  // convenience

@property (nonatomic, assign, getter=isSuspended) BOOL suspended;  // this wraps the same property of a NSOperationQueue.  You typically set this to yes when you are using a scrollView.

// uses all the defaults
- (void)renderHTML:(NSString*)html
        identifier:(NSString*)identifier /* similar to a URL.  Ultimately a cache key */
        completion:(void(^)(NSString *identifier, UIImage *image, BOOL cachedImage, NSError *error))completion;

- (void)renderHTML:(NSString*)html
        identifier:(NSString*)identifier /* similar to a URL.  Ultimately a cache key */
            intent:(HSHTMLImageRenderingIntent)intent
        attributes:(NSDictionary*)attributes
        completion:(void(^)(NSString *identifier, UIImage *image, BOOL cachedImage, NSError *error))completion;

// completion is called immediately if the image is found in the cache.  
- (void)renderHTML:(NSString*)html
        identifier:(NSString*)identifier /* similar to a URL.  Ultimately a cache key */
            intent:(HSHTMLImageRenderingIntent)intent
        attributes:(NSDictionary*)attributes
ignoreCachedResult:(BOOL)ignoreCache
 shouldCacheResult:(BOOL)cacheResult
        completion:(void(^)(NSString *identifier, UIImage *image, BOOL cachedImage, NSError *error))completion;

+ (BOOL)finishRendering;  // will clean up and release some resources.  IF there was even an instance in the first place!

@end
