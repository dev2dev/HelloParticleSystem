#import <UIKit/UIKit.h>

@class avTouchViewController;

@interface avTouchAppDelegate : NSObject <UIApplicationDelegate> {
    IBOutlet UIWindow *window;
    IBOutlet avTouchViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet avTouchViewController *viewController;

@end

