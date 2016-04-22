//
//  HSHTMLImageRenderingOperation.m
//  HSHTMLImageRenderer
//
//  Open-sourced with permission from qLearning Applications GmbH
//  Created by Stephen O'Connor on 15/04/16.
//  MIT License.  Hack away!
//

#import "_HSHTMLImageRenderingOperation.h"
#import "_HSRenderingWebView.h"



@interface HSHTMLImageRenderer(Private)
{
    
}

@property (nonatomic, strong) NSOperationQueue *jobQueue;
@property (nonatomic, strong) _HSRenderingWebView *webView;

@property (nonatomic, strong) dispatch_queue_t webLoadCompletionQueue;

+ (NSCache*)imageCache;

@end



@interface _HSAsyncOperation(Private)
@property (nonatomic, strong) id userInfo;
- (void)endOperation:(id)sender;
@end




NSString * const HSHTMLImageRendererUserInfoKeyImage = @"image";
NSString * const HSHTMLImageRendererUserInfoKeyWasCached = @"wasCached";
NSString * const HSHTMLImageRendererUserInfoKeyIdentifier = @"identifier";




@implementation _HSHTMLImageRenderingOperation

- (instancetype)initWithHTML:(NSString*)htmlToLoad
                  identifier:(NSString*)identifier
                      intent:(HSHTMLImageRenderingIntent)intent
                  attributes:(NSDictionary*)attributes
                    renderer:(HSHTMLImageRenderer*)renderer
          ignoreCachedResult:(BOOL)ignoreCache
           shouldCacheResult:(BOOL)cacheResult
                  completion:(HSOperationCompletionBlock)completion
{
    self = [super initWithCompletion:completion];
    if (self) {
        
        // start with some defaults
        NSMutableDictionary *defaultAttributes = [NSString HS_defaultTemplateAttributes].mutableCopy;
        // then override for any you've changed yourself
        [defaultAttributes setValuesForKeysWithDictionary:attributes];
        
        _identifier = identifier;
        self.name = identifier;
        _renderer = renderer;
        _attributes = defaultAttributes.copy;
        _htmlToLoad = htmlToLoad;
        _intent = intent;
        _ignoreCache = ignoreCache;
        _shouldCache = cacheResult;
        
        _userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
        _userInfo[HSHTMLImageRendererUserInfoKeyIdentifier] = identifier;
    }
    return self;
}

- (void)work
{
    _startTime = [NSDate date];
    
    // check for image in cache...
    if (!_ignoreCache && _identifier) {
        UIImage *image = [[HSHTMLImageRenderer imageCache] objectForKey:_identifier];
        if (image) {
            _userInfo[HSHTMLImageRendererUserInfoKeyImage] = image;
            _userInfo[HSHTMLImageRendererUserInfoKeyWasCached] = @YES;
            self.userInfo = _userInfo;
            [self finish];
            return;
        }
    }
    
    // OK, so we have to render it!
    
    NSURL *baseURL = nil;
    NSString *modifiedString = nil;
    HSHTMLTemplate templateToUse;
    
    switch (_intent) {
        
            // AGAIN, this is where you can customize templates and so on...
            
        default:
            templateToUse = HSHTMLTemplateDefault;
            break;
    }
    
    //NSLog(@"\n\nORIGINAL HTML:\n%@", _htmlToLoad);
    
    modifiedString = [NSString HS_presentationHTMLWithServerSnippetHTML:_htmlToLoad
                                                          usingTemplate:templateToUse
                                                             attributes:_attributes];
    
    //NSLog(@"\n\nMODIFIED HTML:\n%@", modifiedString);
    
    if (HSHTMLImageRendererWriteHTMLToDisk) {
        NSError *error = nil;
        [self saveHTML:modifiedString
            toFilename:[NSString stringWithFormat:@"%03d.html", (int)_operationIndex]
                 error:&error];
        
        if(error)
        {
            NSLog(@"Saving error: %@", error.localizedDescription);
        }
    }
    
    
    CGFloat targetWidth = [(NSNumber*)_attributes[HSHTMLAttributeTargetWidth] floatValue];
    
    
    __weak _HSHTMLImageRenderingOperation *weakself = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // never access the webView from any other thread but the main thread!  It might need to lazy load and thus crash the app!
        weakself.renderer.webView.operation = weakself;
        
        CGRect frame = CGRectMake(0, 0, targetWidth, 1);
        weakself.renderer.webView.frame = frame;
        
        [weakself.renderer.webView loadHTMLString:modifiedString baseURL:baseURL];
    });
}

- (void)completedLoadingWebView:(UIWebView*)webview
{
    // here you do most of the heavy lifting, THEN call finish!
    UIImage *image = nil;
    
    image = [self imageFromWebView:webview attributes:_attributes];
    
    if (_identifier && _shouldCache && image) {
        [[HSHTMLImageRenderer imageCache] setObject:image forKey:_identifier];
        _userInfo[HSHTMLImageRendererUserInfoKeyWasCached] = @NO;
    }
    else
    {
        NSLog(@"You didn't provide an identifier, so this image can't be cached!");
    }
    
    
    _userInfo[HSHTMLImageRendererUserInfoKeyImage] = image;
    
    self.userInfo = _userInfo;
    
    [self finish];
}

- (void)failedLoadingWebView:(NSError *)error
{
    self.error = error;
    
    [self finish];
}

- (UIImage *)imageFromWebView:(UIWebView *)view attributes:(NSDictionary*)attributes
{
    
    NSValue *targetSize = nil;
    
    targetSize = [NSValue valueWithCGSize:self.contentSize];
    
    NSMutableDictionary *items = @{@"WebView" : view,
                                   @"targetSize" : targetSize}.mutableCopy;
    
    // this has to be performed on the main thread because it involves calls to UIKit.  Will cause crashes otherwise...
    [self performSelectorOnMainThread:@selector(_renderWebviewWithDictionary:) withObject:items waitUntilDone:YES];
    
    // the method above should set the image result
    UIImage *image = items[@"result"];
    
    return image;
}

- (void)_renderWebviewWithDictionary:(NSMutableDictionary*)items
{
    _HSRenderingWebView *view = items[@"WebView"];
    CGSize targetSize = [items[@"targetSize"] CGSizeValue];  // this is set by the webview callback
    
    
    // do image magic
    //http://stackoverflow.com/a/20558319/421797
    
    UIGraphicsBeginImageContextWithOptions(targetSize, YES, [UIScreen mainScreen].scale);
    BOOL result = [view drawViewHierarchyInRect:CGRectMake(0, 0, view.bounds.size.width, view.bounds.size.height)
                             afterScreenUpdates:YES];
    
    if (!result) {
        NSLog(@"Failed rendering!");
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    view.operation = nil;
    [view stopLoading];  // prevents -999 errors in the webview delegate
    
    items[@"result"] = image;
}

- (void)endOperation:(id)sender
{
    BOOL wasCached = [self.userInfo[HSHTMLImageRendererUserInfoKeyWasCached] boolValue];
    NSLog(@"Completed a HTML render in %.4fs.  Was cached: %@ with Error: %@", -[_startTime timeIntervalSinceNow], wasCached ? @"YES" : @"NO", self.error);
    [super endOperation:sender];
    
}

#pragma mark - Files and Persistence

+ (NSString*)fileBasePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (NSString*)filePathForFileName:(NSString*)filename
{
    return [[[self.class fileBasePath] stringByAppendingPathComponent: @"html"] stringByAppendingPathComponent:filename];
    
}

- (void)saveHTML:(NSString*)html toFilename:(NSString*)filename error:(NSError**)error
{
    // create the cache path
    NSString *path = [self filePathForFileName:filename];
    
    BOOL isDir;
    NSString *directory = [path stringByDeletingLastPathComponent];
    BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDir];
    
    if (!dirExists) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil]){
            NSLog(@"Error: Create folder failed at %@", directory);
        }
    }
    
    [html writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:error];
    
}
@end
