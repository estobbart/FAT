//
//  FATContainerViewController.h
//  FontAlignment
//
//  Created by Eric Stobbart on 1/29/16.
//  Copyright © 2016 Eric Stobbart. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FATContainerViewController : UIViewController

- (instancetype)initWithBaseViewController:(UIViewController *)viewController;

- (void)pushViewController:(UIViewController *)viewController;

- (UIViewController *)popViewController;

@end
