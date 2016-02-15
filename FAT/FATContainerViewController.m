//
//  FATContainerViewController.m
//  FontAlignment
//
//  Created by Eric Stobbart on 1/29/16.
//  Copyright © 2016 Eric Stobbart. All rights reserved.
//

#import "FATContainerViewController.h"
#import "FATKit.h"

#pragma mark - @interface FATContainerView

@interface FATContainerView : UIView

@end

@implementation FATContainerView

// We want to fire up the layout engine as early as possible
+ (BOOL)requiresConstraintBasedLayout {
  return YES;
}

@end



#pragma mark - @interface FATContainerViewController

@interface FATContainerViewController ()

@end

@implementation FATContainerViewController {
  UINavigationBar *_navigationBar;
  NSMutableArray <UIViewController *> *_vcStack;

  UIView *_placeholder;

  // Used for the animation of controller views on/off screen.
  CGAffineTransform _transformRight;
  CGAffineTransform _transformLeft;
}

- (instancetype)initWithBaseViewController:(UIViewController *)viewController {
  self = [super init];
  if (self) {
    _vcStack = [[NSMutableArray alloc] init];
    [self addChildViewController:viewController];
    [_vcStack addObject:viewController];
  }
  return self;

}

- (void)loadView {
  self.view = [[FATContainerView alloc] init];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  self.view.backgroundColor = [UIColor whiteColor];

  CGFloat offset = CGRectGetWidth(self.view.frame);
  _transformRight = CGAffineTransformMakeTranslation(offset, 0.0f);
  _transformLeft = CGAffineTransformMakeTranslation(offset * -1.0f, 0.0f);

  _placeholder = [[UIView alloc] init];
  _placeholder.translatesAutoresizingMaskIntoConstraints = NO;
  // TODO: Remove this. It signals that views were mismanaged.
  //_placeholder.backgroundColor = [UIColor redColor];
  [self.view addSubview:_placeholder];

  _navigationBar = [[UINavigationBar alloc] init];
  _navigationBar.translatesAutoresizingMaskIntoConstraints = NO;
  [_navigationBar setBackgroundImage:[UIImage new]
             forBarMetrics:UIBarMetricsDefault];
  // NOTE(estobbart): For now I prefer the shadow.
//  [_navigationBar setShadowImage:[UIImage new]];
  [self.view addSubview:_navigationBar];

  [self.view setNeedsUpdateConstraints];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  // This really only happens once anyway, but just in case.
  static dispatch_once_t predicate = 0;
  dispatch_once(&predicate, ^{
    UIViewController *topVC = _vcStack.lastObject;
    CGRect frame = CGRectMake(0.0f,
                              0.0f,
                              CGRectGetWidth(_placeholder.frame),
                              CGRectGetHeight(_placeholder.frame));
    topVC.view.frame = frame;
    _navigationBar.items = @[topVC.navigationItem];
    [_placeholder addSubview:topVC.view];
    [topVC didMoveToParentViewController:self];
    [_placeholder addConstraints:[self fat_createConstraintsForTopView:topVC.view
                                                                toView:_placeholder]];
  });
}

- (void)pushViewController:(UIViewController *)viewController {
  UIViewController *topController = _vcStack.lastObject;
  [self addChildViewController:viewController];
  [_vcStack addObject:viewController];
  CGRect placeholderFrame = topController.view.frame;

  viewController.view.frame = placeholderFrame;
  viewController.view.transform = _transformRight;
  [_placeholder addSubview:viewController.view];

  [viewController didMoveToParentViewController:self];
  UINavigationItem *navItem = viewController.navigationItem;

  [_navigationBar pushNavigationItem:navItem
                            animated:YES];
  [UIView animateWithDuration:0.25f
                   animations:^{
                     viewController.view.transform = CGAffineTransformIdentity;
                     topController.view.transform = _transformLeft;
                   }
                   completion:^(BOOL finished) {
                     [_placeholder addConstraints:[self fat_createConstraintsForTopView:viewController.view
                                                                                 toView:_placeholder]];
                     [_placeholder layoutIfNeeded];
                   }];
}

- (UIViewController *)popViewController {
  if (_vcStack.count <= 1) {
    return nil;
  }
  UIViewController *poppedController = _vcStack.lastObject;
  [_vcStack removeLastObject];
  UIViewController *presentedController = _vcStack.lastObject;

  [_navigationBar popNavigationItemAnimated:YES];
  [UIView animateWithDuration:0.25f
                   animations:^{
                     poppedController.view.transform = _transformRight;
                     presentedController.view.transform = CGAffineTransformIdentity;
                   }
                   completion:^(BOOL finished) {
                     [poppedController.view removeFromSuperview];
                     [_placeholder addConstraints:[self fat_createConstraintsForTopView:presentedController.view
                                                                                 toView:_placeholder]];
                     [_placeholder layoutIfNeeded];
                   }];
  return poppedController;
}

// Constraints used to align the top view controller in the stack with
// the placeholder view.
- (NSArray <NSLayoutConstraint *> *)fat_createConstraintsForTopView:(UIView *)topView
                                                             toView:(UIView *)parentView {
  return @[
           EQUAL_ATTRIBUTES(topView, parentView, NSLayoutAttributeLeft),
           EQUAL_ATTRIBUTES(topView, parentView, NSLayoutAttributeTop),
           EQUAL_ATTRIBUTES(topView, parentView, NSLayoutAttributeHeight),
           EQUAL_ATTRIBUTES(topView, parentView, NSLayoutAttributeWidth)
           ];
}

- (void)updateViewConstraints {
  [super updateViewConstraints];
  CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
  [self.view addConstraints:@[
      // placeholder
      [NSLayoutConstraint constraintWithItem:_placeholder
                                   attribute:NSLayoutAttributeTop
                                   relatedBy:NSLayoutRelationEqual
                                      toItem:_navigationBar
                                   attribute:NSLayoutAttributeBottom
                                  multiplier:1.0f
                                    constant:0.0f],
      [NSLayoutConstraint constraintWithItem:_placeholder
                                   attribute:NSLayoutAttributeBottom
                                   relatedBy:NSLayoutRelationEqual
                                      toItem:self.view
                                   attribute:NSLayoutAttributeBottom
                                  multiplier:1.0f
                                    constant:0.0f],
      [NSLayoutConstraint constraintWithItem:_placeholder
                                   attribute:NSLayoutAttributeLeft
                                   relatedBy:NSLayoutRelationEqual
                                      toItem:self.view
                                   attribute:NSLayoutAttributeLeft
                                  multiplier:1.0f
                                    constant:0.0f],
      [NSLayoutConstraint constraintWithItem:_placeholder
                                   attribute:NSLayoutAttributeRight
                                   relatedBy:NSLayoutRelationEqual
                                      toItem:self.view
                                   attribute:NSLayoutAttributeRight
                                  multiplier:1.0f
                                    constant:0.0f],
      // UINavigationBar
      [NSLayoutConstraint constraintWithItem:_navigationBar
                                   attribute:NSLayoutAttributeTop
                                   relatedBy:NSLayoutRelationEqual
                                      toItem:self.view
                                   attribute:NSLayoutAttributeTop
                                  multiplier:1.0f
                                    constant:statusBarFrame.size.height],
      [NSLayoutConstraint constraintWithItem:_navigationBar
                                   attribute:NSLayoutAttributeLeft
                                   relatedBy:NSLayoutRelationEqual
                                      toItem:self.view
                                   attribute:NSLayoutAttributeLeft
                                  multiplier:1.0f
                                    constant:0.0f],
      [NSLayoutConstraint constraintWithItem:_navigationBar
                                   attribute:NSLayoutAttributeWidth
                                   relatedBy:NSLayoutRelationEqual
                                      toItem:self.view
                                   attribute:NSLayoutAttributeWidth
                                  multiplier:1.0f
                                    constant:0.0f],
                              ]];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


@end
