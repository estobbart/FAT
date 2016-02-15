//
//  FontLoaderViewController.m
//  FontAlignment
//
//  Created by Eric Stobbart on 1/29/16.
//  Copyright © 2016 Eric Stobbart. All rights reserved.
//

#import "FontLoaderViewController.h"
#import "FATKit.h"
#import "FATContainerViewController.h"

@import CoreText;

@interface FontLoaderViewController ()

@end

@implementation FontLoaderViewController {
  UITextField *_urlTextField;
  UINavigationItem *_navigationItem;
}

- (void)loadView {
  UIControl *view = [[UIControl alloc] init];
  [view addTarget:self
           action:@selector(fat_dismissKeyboard:)
 forControlEvents:UIControlEventTouchUpInside];
  self.view = view;
}

- (void)fat_dismissKeyboard:(id)sender {
  [self.view endEditing:YES];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.

  self.view.backgroundColor = [UIColor whiteColor];

  _urlTextField = [[UITextField alloc] init];
  _urlTextField.translatesAutoresizingMaskIntoConstraints = NO;
  _urlTextField.placeholder = @"http://<your otf||ttf font file url>";
  _urlTextField.layer.borderWidth = kFABorderWidth;
  _urlTextField.layer.cornerRadius = kFACornerRadius;
  _urlTextField.layer.borderColor = [UIColor grayColor].CGColor;
  _urlTextField.delegate = self;
  _urlTextField.keyboardType = UIKeyboardTypeURL;
  _urlTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  _urlTextField.autocorrectionType = UITextAutocorrectionTypeNo;
  _urlTextField.spellCheckingType = UITextSpellCheckingTypeNo;
  _urlTextField.returnKeyType = UIReturnKeyGo;
  _urlTextField.enablesReturnKeyAutomatically = YES;
  [self.view addSubview:_urlTextField];

  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self
         selector:@selector(fat_keyboardWillShow:)
             name:UIKeyboardWillShowNotification
           object:nil];
  [nc addObserver:self
         selector:@selector(fat_keyboardWillHide:)
             name:UIKeyboardWillHideNotification
           object:nil];

  [self.view setNeedsUpdateConstraints];
}

- (void)fat_keyboardWillShow:(NSNotification *)note {
  NSDictionary *info = [note userInfo];
  CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
  [UIView animateWithDuration:[[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]
                        delay:0.0f
                      options:[[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue]
                   animations:^{
                     self.view.transform = CGAffineTransformMakeTranslation(0.0f, kbSize.height * -0.5f);
                   }
                   completion:^(BOOL finished) {
                     //
                   }];
}

- (void)fat_keyboardWillHide:(NSNotification *)note {
  self.view.transform = CGAffineTransformIdentity;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (UINavigationItem *)navigationItem {
  if (!_navigationItem) {
    _navigationItem = [[UINavigationItem alloc] init];
    _navigationItem.title = @"Font Loader";
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setAttributedTitle:[[NSAttributedString alloc] initWithString:@"<"
                                                            attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:24.0f]}]
                   forState:UIControlStateNormal];
    [btn sizeToFit];
    [btn addTarget:(FATContainerViewController *)self.parentViewController
            action:@selector(popViewController)
  forControlEvents:UIControlEventTouchUpInside];
    _navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
  }
  return _navigationItem;
}

- (void)updateViewConstraints {
  [super updateViewConstraints];

  [self.view addConstraints:@[
    [NSLayoutConstraint constraintWithItem:_urlTextField
                                 attribute:NSLayoutAttributeCenterX
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self.view
                                 attribute:NSLayoutAttributeCenterX
                                multiplier:1.0f
                                  constant:0.0f],
    [NSLayoutConstraint constraintWithItem:_urlTextField
                                 attribute:NSLayoutAttributeCenterY
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self.view
                                 attribute:NSLayoutAttributeCenterY
                                multiplier:1.0f
                                  constant:0.0f],
    [NSLayoutConstraint constraintWithItem:_urlTextField
                                 attribute:NSLayoutAttributeWidth
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self.view
                                 attribute:NSLayoutAttributeWidth
                                multiplier:0.8f
                                  constant:0.0f]
  ]];
}

- (void)fat_loadFont:(NSString *)text {
  NSURL *url = [NSURL URLWithString:text];
  if (url && url.scheme && url.host) {
    NSError *err = nil;
    NSData *inData = [NSData dataWithContentsOfURL:url
                                           options:NSDataReadingUncached
                                             error:&err];
    if (inData && !err) {

      NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[url.pathComponents componentsJoinedByString:@""]];
      NSURL *fileURL = [NSURL fileURLWithPath:path];
      NSError *error = nil;
      if ([inData writeToURL:fileURL options:NSDataWritingAtomic error:&error]) {
        CFErrorRef cferror;
        if (CTFontManagerRegisterFontsForURL((__bridge CFURLRef)fileURL, kCTFontManagerScopeProcess, &cferror)) {
          dispatch_async(dispatch_get_main_queue(), ^{
            _urlTextField.layer.borderColor = [UIColor greenColor].CGColor;
          });
          return;
        }
        CFStringRef errorDescription = CFErrorCopyDescription(cferror);
        NSLog(@"Failed to load font: %@", errorDescription);
        CFRelease(errorDescription);

      }

      // This is the commonly documented way to load the fonts from SO, but it
      // doesn't exactly do what I'm looking for.
      
      //CFErrorRef error;
      //CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)inData);
      //CGFontRef font = CGFontCreateWithDataProvider(provider);
      //CFStringRef fullName = CGFontCopyFullName(font);

//      if (CTFontManagerRegisterGraphicsFont(font, &error)) {
//        CFRelease(font);
//        CFRelease(provider);
//        dispatch_async(dispatch_get_main_queue(), ^{
//          _urlTextField.layer.borderColor = [UIColor greenColor].CGColor;
//        });
//        return;
//      }
//      CFStringRef errorDescription = CFErrorCopyDescription(error);
//      NSLog(@"Failed to load font: %@", errorDescription);
//      CFRelease(errorDescription);
    }

  }
  _urlTextField.layer.borderColor = [UIColor redColor].CGColor;
}

#pragma mark - @protocol UITextFieldDelegate <NSObject>

// return NO to disallow editing.
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
  return YES;
}

// became first responder
- (void)textFieldDidBeginEditing:(UITextField *)textField {
  textField.layer.borderColor = [UIColor grayColor].CGColor;
}

// return YES to allow editing to stop and to resign first responder status. NO to disallow the editing session to end
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
  return YES;
}

// may be called if forced even if shouldEndEditing returns NO (e.g. view removed from window) or endEditing:YES called
- (void)textFieldDidEndEditing:(UITextField *)textField {
}

// return NO to not change text
- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {
  return YES;
}

// called when clear button pressed. return NO to ignore (no notifications)
- (BOOL)textFieldShouldClear:(UITextField *)textField {
  return YES;
}

// called when 'return' key pressed. return NO to ignore.
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    [self fat_loadFont:textField.text];
  });
  return YES;
}



@end
