//
//  HSRenderingWebView.h
//  HSHTMLImageRenderer
//
//  Open-sourced with permission from qLearning Applications GmbH
//  Created by Stephen O'Connor on 15/04/16.
//  MIT License.  Hack away!
//

#import <UIKit/UIKit.h>

@class _HSHTMLImageRenderingOperation;

@interface _HSRenderingWebView : UIWebView

@property (nonatomic, weak) _HSHTMLImageRenderingOperation *operation;

@end
