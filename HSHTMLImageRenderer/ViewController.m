//
//  ViewController.m
//  HSHTMLImageRenderer
//
//  Created by Stephen O'Connor on 15/04/16.
//  Copyright © 2016 Software Barn. All rights reserved.
//

#import "ViewController.h"
#import "HSHTMLImageRenderer.h"

@interface ViewController ()
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // NOT A GOOD IDEA TO CALL THE RENDERER HERE BECAUSE OF LAYOUT CONSIDERATIONS!!
}

static NSString *TestHTML = @"<p>I just want to render some HTML.</p><p>It took quite a lot of trial and error to make the underlying UIWebView render things as I wanted it to!</p>";


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
    NSNumber *targetWidth = @(self.imageView.bounds.size.width);
    
    [[HSHTMLImageRenderer rendererInWindow:self.view.window] renderHTML:TestHTML
                                                             identifier:@"Test"
                                                                 intent:HSHTMLImageRenderingIntentDefault
                                                             attributes:@{HSHTMLAttributeTargetWidth : targetWidth}
                                                             completion:^(NSString *identifier, UIImage *image, BOOL cachedImage, NSError *error)
     {
         NSLog(@"Finished!  Was Cached: %@", cachedImage ? @"YES" : @"NO");
         
     }];
    
    [[HSHTMLImageRenderer renderer] renderHTML:TestHTML
                                    identifier:@"Test"
                                    completion:^(NSString *identifier, UIImage *image, BOOL cachedImage, NSError *error)
     {
         
         NSLog(@"Finished!  Was Cached: %@", cachedImage ? @"YES" : @"NO");
         
         self.imageView.image = image;  // don't forget .contentMode of the imageView is going to play a role.  Also consider what Autolayout might be doing...
     }];
    
    [self performSelector:@selector(loadANewImage) withObject:nil afterDelay:3.0f];
}

- (void)loadANewImage
{
    NSNumber *targetWidth = @(self.imageView.bounds.size.width);
    
    NSDictionary *newAttributes = @{HSHTMLAttributeTargetWidth : targetWidth,
                                    HSHTMLAttributeFont : [UIFont fontWithName:@"Helvetica" size:7]};
    
    // in order to use newAttributes, you wil want to make sure you ignore the cache!
    
    [[HSHTMLImageRenderer renderer] renderHTML:TestHTML
                                    identifier:@"Test"
                                        intent:HSHTMLImageRenderingIntentDefault
                                    attributes:newAttributes
                            ignoreCachedResult:YES
                             shouldCacheResult:YES
                                    completion:^(NSString *identifier, UIImage *image, BOOL cachedImage, NSError *error)
     {
         NSLog(@"Finished!  Was Cached: %@", cachedImage ? @"YES" : @"NO");
         
         self.imageView.image = image;  // don't forget .contentMode of the imageView is going to play a role.  Also consider what Autolayout might be doing...
     }];
}

@end
