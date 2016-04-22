//
//  HSHTMLImageRenderer.m
//  HSHTMLImageRenderer
//
//  Open-sourced with permission from qLearning Applications GmbH
//  Created by Stephen O'Connor on 12/04/16.
//  MIT License.  Hack away!
//


#import "HSHTMLImageRenderer.h"
#import <UIKit/UIKit.h>

#import "_HSRenderingWebView.h"
#import "_HSHTMLImageRenderingOperation.h"




static NSCache *ImageCache = nil;


@interface HSHTMLImageRenderer()<UIWebViewDelegate>
{
    UIWindow *_renderingWindow;  // the UIWebView doesn't render properly if it's not in the window's view hierarchy!
    _HSRenderingWebView *_webView;
    NSUInteger _operationsRequested;
}

@property (nonatomic, strong) NSOperationQueue *jobQueue;
@property (nonatomic, strong, readonly) _HSRenderingWebView *webView;
@property (nonatomic, strong) dispatch_queue_t webLoadCompletionQueue;

+ (NSCache*)imageCache;

@end



@implementation HSHTMLImageRenderer

+ (NSCache*)imageCache
{
    if (!ImageCache) {
        ImageCache = [[NSCache alloc] init];
    }
    return ImageCache;
}

static HSHTMLImageRenderer *sharedInstance = nil;

+ (instancetype)rendererInWindow:(UIWindow *)window
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] initWithWindow:window];
    });
    return sharedInstance;
}

+ (instancetype)renderer
{
    NSAssert(sharedInstance, @"Before you call this method you need to first initalize the object with rendererInWindow: !!");
    return sharedInstance;
}

- (instancetype)initWithWindow:(UIWindow*)window
{
    self = [super init];
    if (self) {
        
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;  // guarantees a serial queue!
        queue.name = @"HSHTMLImageRendererQueue";
        queue.qualityOfService = NSQualityOfServiceBackground;
        _jobQueue = queue;
        
        self.webLoadCompletionQueue = dispatch_queue_create("com.skive.html.renderer", DISPATCH_QUEUE_SERIAL);
        
        if (HSHTMLImageRendererWriteHTMLToDisk)
        {
            NSLog(@"Test HTML save path: %@", [_HSHTMLImageRenderingOperation fileBasePath]);
        }
        
        _renderingWindow = window;
        
        NSLog(@"Creating Rendering Webview on Main Thread: %@", self.webView);
        
    }
    return self;
}

- (void)dealloc
{
    [self finishRendering];
    
}

- (BOOL)isSuspended
{
    return self.jobQueue.isSuspended;
}

- (void)setSuspended:(BOOL)suspended
{
    //NSLog(@"setSuspended: %@", NSStringFromBOOL(suspended));
    self.jobQueue.suspended = suspended;
}

- (_HSRenderingWebView*)webView
{
    if (!_webView) {
        
        CGSize screenSize = [_renderingWindow bounds].size;
        _HSRenderingWebView *webview = [[_HSRenderingWebView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
        webview.delegate = self;
        webview.opaque = NO;
        webview.backgroundColor = [UIColor clearColor];
        _webView = webview;
        
        [_renderingWindow insertSubview:webview atIndex:0];
    }
    return _webView;
}

+ (void)finishRendering
{
    if (sharedInstance != nil) {
        [sharedInstance finishRendering];
    }
}

- (BOOL)finishRendering
{
    if (self.jobQueue.operationCount > 0) {
        NSLog(@"Fail!  You should only call this after all your rendering jobs are finished!");
        return NO;
    }
    
    [_webView removeFromSuperview];
    [NSString HS_finishUsingTemplates];
    
    return YES;
}

#pragma mark - Public Methods

- (void)renderHTML:(NSString*)html
        identifier:(NSString*)identifier /* similar to a URL.  Ultimately a cache key */
        completion:(void(^)(NSString *identifier, UIImage *image, BOOL cachedImage, NSError *error))completion;
{
    [self renderHTML:html
          identifier:identifier
              intent:HSHTMLImageRenderingIntentDefault
          attributes:[NSString HS_defaultTemplateAttributes]
          completion:completion];
}

- (void)renderHTML:(NSString*)html
        identifier:(NSString*)identifier /* similar to a URL.  Ultimately a cache key */
            intent:(HSHTMLImageRenderingIntent)intent
        attributes:(NSDictionary*)attributes
        completion:(void(^)(NSString *identifier, UIImage *image, BOOL cachedImage, NSError *error))completion
{
    // convenience method with sensible defaults
    
    [self renderHTML:html
          identifier:identifier
              intent:intent
          attributes:attributes
  ignoreCachedResult:NO
   shouldCacheResult:YES
          completion:completion];
    
}

- (void)renderHTML:(NSString*)html
        identifier:(NSString*)identifier /* similar to a URL.  Ultimately a cache key */
            intent:(HSHTMLImageRenderingIntent)intent
        attributes:(NSDictionary*)attributes
ignoreCachedResult:(BOOL)ignoreCache
 shouldCacheResult:(BOOL)shouldCache
        completion:(void(^)(NSString *identifier, UIImage *image, BOOL cachedImage, NSError *error))completion
{
    // check for image in cache...
    if (!ignoreCache && identifier) {
        UIImage *image = [[HSHTMLImageRenderer imageCache] objectForKey:identifier];
        if (image) {
            NSLog(@"Started a HSHTMLImageRenderer Render request.  Identifier: '%@'", identifier);
            NSLog(@"Completed a HTML render in 0.0s.  Was cached.");
            if (completion) {
                completion(identifier, image, YES, nil);
            }
            return;
        }
    }
    
    
    _HSHTMLImageRenderingOperation *renderOp;
    renderOp = [[_HSHTMLImageRenderingOperation alloc] initWithHTML:html
                                                        identifier:identifier
                                                            intent:intent
                                                        attributes:attributes
                                                          renderer:self
                                                ignoreCachedResult:ignoreCache
                                                 shouldCacheResult:shouldCache
                                                        completion:^(BOOL success, NSDictionary *results, NSError *error)
    {
        UIImage *image = results[HSHTMLImageRendererUserInfoKeyImage];
        NSString *identifier = results[HSHTMLImageRendererUserInfoKeyIdentifier];
        BOOL wasInCache = [results[HSHTMLImageRendererUserInfoKeyWasCached] boolValue];
        
        if (completion) {
            completion(identifier, image, wasInCache, error);
        }
    }];
    
    _operationsRequested++;
    renderOp->_operationIndex = _operationsRequested;
    
    [self.jobQueue addOperation:renderOp];
    
}

#pragma mark - WebViewDelegate

- (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (webView == self.webView && self.webView.operation) {
        
        // see here: http://stackoverflow.com/a/11770883/421797
        
        CGFloat height = [[webView stringByEvaluatingJavaScriptFromString:@"document.height"] floatValue];
        CGFloat width = [[webView stringByEvaluatingJavaScriptFromString:@"document.width"] floatValue];
        
        self.webView.operation.contentSize = CGSizeMake(width, height);
        
        CGRect frame = webView.frame;
        
        // I'm guessing your snippet shouldn't be larger than this... This is actually required or weird things start happening...
        // I mean, try with just height and see what happens.
        frame.size.height = MAX(1000, height);
        frame.size.width = width;
        webView.frame = frame;

        
        if (self.webView.operation) {
            
            [self notifyOperationOfCompletedLoadingOfWebview:(_HSRenderingWebView *)webView];
        }
    }
    else
    {
        NSLog(@"Tried resetting the webview!");
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (webView == self.webView) {
        
        if (self.webView.operation) {
            
            NSLog(@"Failure Context: %@", self.webView.operation.name);
            
            __weak HSHTMLImageRenderer *weakself = self;
            
            dispatch_async(self.webLoadCompletionQueue, ^{
                
                [weakself.webView.operation failedLoadingWebView:error];
                weakself.webView.operation = nil;
                
            });
        }
    }
}

- (void)notifyOperationOfCompletedLoadingOfWebview:(_HSRenderingWebView*)webView
{
    __weak HSHTMLImageRenderer *weakself = self;
    
    dispatch_async(self.webLoadCompletionQueue, ^{
        
        [weakself.webView.operation completedLoadingWebView:weakself.webView];
        weakself.webView.operation = nil;
        
    });
}


@end
