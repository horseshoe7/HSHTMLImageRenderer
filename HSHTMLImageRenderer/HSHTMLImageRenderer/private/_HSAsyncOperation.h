//
//  HSOperation.h
//  HSHTMLImageRenderer
//
//  Created by Stephen O'Connor on 12/04/16.
//  MIT License.  Hack away!
//

// ASYNCHRNONOUS OPERATION!

#import <Foundation/Foundation.h>

typedef void(^HSOperationCompletionBlock)(BOOL success, id userInfo, NSError *error);

@interface _HSAsyncOperation : NSOperation
{
    @protected
    
    BOOL _isExecuting;
    BOOL _isFinished;
}
@property (nonatomic, strong) NSError *error;  // these are ideally in a protected, private interface, that you would implement via a separate category header.
@property (nonatomic, copy) HSOperationCompletionBlock opCompletionBlock;  // generally not needed to read

- (instancetype)initWithCompletion:(HSOperationCompletionBlock)completion;

// DO OVERRIDE!
- (void)work;  // should override this and call finish inside of this method somewhere, or once your work is done, if asynchronous

// DO NOT OVERRIDE
- (void)finish;  // you'll see...


@end
