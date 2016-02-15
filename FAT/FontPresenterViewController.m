//
//  FontPresenterViewController.m
//  FontAlignment
//
//  Created by Eric Stobbart on 1/29/16.
//  Copyright © 2016 Eric Stobbart. All rights reserved.
//

#import "FontPresenterViewController.h"
#import "FATContainerViewController.h"
#import "FATKit.h"

@import CoreText;

NSString * const kFPDemoString = @"5Hlpx";

#pragma mark - @interface UIFont (CTFontRefCasting)

@interface UIFont (CTFontRefCasting)

- (CTFontRef)coreTextFont;

@end

@implementation UIFont (CTFontRefCasting)

- (CTFontRef)coreTextFont {
  CTFontRef fontRef = CTFontCreateWithName((CFStringRef)self.fontName, self.pointSize, NULL);
  return CFAutorelease(fontRef);
}

@end

#pragma mark - @interface TextMeasurement : UIView

@interface TextMeasurement : UIView

@property (readwrite, nonatomic, strong) UIColor *color;

@end

@implementation TextMeasurement

- (instancetype)initWithColor:(UIColor *)color {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    _color = color ? color : [UIColor redColor];
    self.opaque = NO;
  }
  return self;
}

- (void)drawRect:(CGRect)rect {
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGContextClearRect(ctx, rect);
  CGContextSetStrokeColorWithColor(ctx, _color.CGColor);

  CGFloat height = CGRectGetHeight(rect);
  CGContextSetLineWidth(ctx, height);

  CGFloat minX, minY;
  minX = CGRectGetMinX(rect);
  minY = CGRectGetMinY(rect);
  CGContextMoveToPoint(ctx, minX, minY);

  CGFloat maxX;
  maxX = CGRectGetMaxX(rect);
  CGContextAddLineToPoint(ctx, maxX, minY);

  CGContextStrokePath(ctx);
}

- (CGSize)intrinsicContentSize {
  return CGSizeMake(UIViewNoIntrinsicMetric, 0.5f);
}

@end

#pragma mark - @interface RulerView

@interface RulerView : UIView

@end

@implementation RulerView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.opaque = NO;
  }
  return self;
}


- (void)drawRect:(CGRect)rect {
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGContextClearRect(ctx, rect);
  CGContextSetStrokeColorWithColor(ctx, [UIColor blackColor].CGColor);

  CGFloat lengths[] = {1.0f, 9.0f};
  CGContextSetLineDash(ctx, 0.0f, lengths, 2);
  CGContextSetLineWidth(ctx, 10.0f);

  CGFloat maxX, minY;
  maxX = CGRectGetMaxX(rect);
  minY = CGRectGetMinY(rect);
  CGContextMoveToPoint(ctx, maxX, minY);

  CGFloat maxY;
  maxY = CGRectGetMaxY(rect);
  CGContextAddLineToPoint(ctx, maxX, maxY);

  CGContextStrokePath(ctx);
}

- (CGSize)intrinsicContentSize {
  return CGSizeMake(10.0f, UIViewNoIntrinsicMetric);
}

@end

#pragma mark - @interface FontPresenterViewController

/*
 TODO:
 
 - Change this to a UIScrollView and allow zoom
 - Make a metric page to show uem, ascender, descender, etc.
 */

@interface FontPresenterViewController ()

@end

@implementation FontPresenterViewController {
  UIFont *_font;
  UILabel *_label;

  UILabel *_size;
  UIButton *_plus;
  UIButton *_minus;
  UIButton *_measure;

  UIView *_measurements;

  TextMeasurement *_baseline;
  TextMeasurement *_capHeight;
  TextMeasurement *_xHeight;
  TextMeasurement *_ascender;
  TextMeasurement *_descender;

  UINavigationItem *_navigationItem;

  RulerView *_ruler;
}

- (instancetype)initWithFont:(UIFont *)font {
  self = [super init];
  if (self) {
    _font = font;
    CTFontRef ctFont = [_font coreTextFont];
    // see above
    unsigned uem = CTFontGetUnitsPerEm(ctFont);
    NSLog(@"UEM:%i", uem);
    CGFloat ascent = CTFontGetAscent(ctFont);
    CGFloat descent = CTFontGetDescent(ctFont);
    NSLog(@"ascent:%f descent:%f", ascent, descent);
  }
  return self;
}

- (UINavigationItem *)navigationItem {
  if (!_navigationItem) {
    _navigationItem = [[UINavigationItem alloc] init];
    _navigationItem.title = _font.fontName;
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


- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  self.view.backgroundColor = [UIColor whiteColor];

  _ruler = [[RulerView alloc] init];
  _ruler.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:_ruler];

  _measurements = [[UIView alloc] init];
  _measurements.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:_measurements];

  _label = [[UILabel alloc] init];
  _label.translatesAutoresizingMaskIntoConstraints = NO;
  _label.font = _font;
  _label.text = kFPDemoString;
  [self.view addSubview:_label];

  _baseline = [[TextMeasurement alloc] initWithColor:nil];
  _baseline.translatesAutoresizingMaskIntoConstraints = NO;
  [_measurements addSubview:_baseline];

  _capHeight = [[TextMeasurement alloc] initWithColor:nil];
  _capHeight.translatesAutoresizingMaskIntoConstraints = NO;
  [_measurements addSubview:_capHeight];

  _xHeight = [[TextMeasurement alloc] initWithColor:nil];
  _xHeight.translatesAutoresizingMaskIntoConstraints = NO;
  [_measurements addSubview:_xHeight];

  _ascender = [[TextMeasurement alloc] initWithColor:nil];
  _ascender.translatesAutoresizingMaskIntoConstraints = NO;
  [_measurements addSubview:_ascender];

  _descender = [[TextMeasurement alloc] initWithColor:nil];
  _descender.translatesAutoresizingMaskIntoConstraints = NO;
  [_measurements addSubview:_descender];

  _size = [[UILabel alloc] init];
  _size.translatesAutoresizingMaskIntoConstraints = NO;
  _size.text = [self fat_fontPointSizeString:_font.pointSize];
  [self.view addSubview:_size];

  _minus = [UIButton buttonWithType:UIButtonTypeCustom];
  _minus.translatesAutoresizingMaskIntoConstraints = NO;
  [_minus setAttributedTitle:[[NSAttributedString alloc] initWithString:@"-"
                                                             attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:26.0f]}]
                    forState:UIControlStateNormal];
  [_minus addTarget:self
             action:@selector(fat_decreaseFont:)
  forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:_minus];

  _plus = [UIButton buttonWithType:UIButtonTypeCustom];
  _plus.translatesAutoresizingMaskIntoConstraints = NO;
  [_plus setAttributedTitle:[[NSAttributedString alloc] initWithString:@"+"
                                                            attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:26.0f]}]
                   forState:UIControlStateNormal];
  [_plus addTarget:self
            action:@selector(fat_increaseFont:)
  forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:_plus];

  [self.view setNeedsUpdateConstraints];
}

- (NSString *)fat_fontPointSizeString:(CGFloat)pointSize {
  return [NSString stringWithFormat:@"%.2f", pointSize];
}

- (void)fat_increaseFont:(id)sender {
  [self fat_changeFont:1.0f];
}

- (void)fat_decreaseFont:(id)sender {
  [self fat_changeFont:-1.0f];
}

- (void)fat_changeFont:(CGFloat)adjustment {
  _font = [UIFont fontWithName:_font.fontName
                          size:_font.pointSize + adjustment];
  _label.font = _font;
  _size.text = [self fat_fontPointSizeString:_font.pointSize];
  [self.view setNeedsUpdateConstraints];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)updateViewConstraints {
  [super updateViewConstraints];

  NSArray <NSLayoutConstraint *> *constraints = [self fat_existingConstraintsForViews:self.view.subviews
                                                                               onView:self.view];
  [self.view removeConstraints:constraints];

  // _ruler
  [self.view addConstraint:EQUAL_ATTRIBUTES(_ruler, self.view, NSLayoutAttributeLeft)];
  [self.view addConstraint:EQUAL_ATTRIBUTES(_ruler, self.view, NSLayoutAttributeHeight)];
  [self.view addConstraint:EQUAL_ATTRIBUTES(_ruler, self.view, NSLayoutAttributeTop)];

  // _label
  [self.view addConstraint:EQUAL_ATTRIBUTES(_label, self.view, NSLayoutAttributeCenterX)];
  [self.view addConstraint:EQUAL_ATTRIBUTES(_label, self.view, NSLayoutAttributeCenterY)];

  // _measurements
  [self.view addConstraint:EQUAL_ATTRIBUTES(_measurements, _label, NSLayoutAttributeTop)];
  [self.view addConstraint:EQUAL_ATTRIBUTES(_measurements, _label, NSLayoutAttributeHeight)];
  [self.view addConstraint:EQUAL_ATTRIBUTES(_measurements, _label, NSLayoutAttributeLeft)];
  [self.view addConstraint:EQUAL_ATTRIBUTES(_measurements, _label, NSLayoutAttributeWidth)];

  // _size
  [self.view addConstraint:EQUAL_ATTRIBUTES(_size, self.view, NSLayoutAttributeCenterX)];
  [self.view addConstraint:EQUAL_ATTRIBUTES(_size, _plus, NSLayoutAttributeCenterY)];

  // _plus
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_plus
                                                        attribute:NSLayoutAttributeLeft
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_size
                                                        attribute:NSLayoutAttributeRight
                                                       multiplier:1.0f
                                                         constant:0.0f]];
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_plus
                                                        attribute:NSLayoutAttributeBottom
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.view
                                                        attribute:NSLayoutAttributeBottom
                                                       multiplier:1.0f
                                                         constant:-8.0f]];

  // _minus
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_minus
                                                        attribute:NSLayoutAttributeRight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_size
                                                        attribute:NSLayoutAttributeLeft
                                                       multiplier:1.0f
                                                         constant:0.0f]];
  [self.view addConstraint:EQUAL_ATTRIBUTES(_minus, _plus, NSLayoutAttributeCenterY)];

  // _baseline
  [self.view addConstraint:EQUAL_ATTRIBUTES(_baseline, _measurements, NSLayoutAttributeWidth)];
  [self.view addConstraint:EQUAL_ATTRIBUTES(_baseline, _measurements, NSLayoutAttributeLeft)];
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_baseline
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_label
                                                        attribute:NSLayoutAttributeBaseline
                                                       multiplier:1.0f
                                                         constant:0.0f]];
  // _capHeight
  [self.view addConstraint:EQUAL_ATTRIBUTES(_capHeight, _measurements, NSLayoutAttributeWidth)];
  [self.view addConstraint:EQUAL_ATTRIBUTES(_capHeight, _measurements, NSLayoutAttributeLeft)];
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_capHeight
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_label
                                                        attribute:NSLayoutAttributeBaseline
                                                       multiplier:1.0f
                                                         constant:_font.capHeight * -1.0f]];

  // _xHeight
  [self.view addConstraint:EQUAL_ATTRIBUTES(_xHeight, _measurements, NSLayoutAttributeWidth)];
  [self.view addConstraint:EQUAL_ATTRIBUTES(_xHeight, _measurements, NSLayoutAttributeLeft)];
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_xHeight
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_label
                                                        attribute:NSLayoutAttributeBaseline
                                                       multiplier:1.0f
                                                         constant:_font.xHeight * -1.0f]];

  // _ascender
  [self.view addConstraint:EQUAL_ATTRIBUTES(_ascender, _measurements, NSLayoutAttributeWidth)];
  [self.view addConstraint:EQUAL_ATTRIBUTES(_ascender, _measurements, NSLayoutAttributeLeft)];
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_ascender
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_label
                                                        attribute:NSLayoutAttributeBaseline
                                                       multiplier:1.0f
                                                         constant:_font.ascender * -1.0f]];

  // _descender
  [self.view addConstraint:EQUAL_ATTRIBUTES(_descender, _measurements, NSLayoutAttributeWidth)];
  [self.view addConstraint:EQUAL_ATTRIBUTES(_descender, _measurements, NSLayoutAttributeLeft)];
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_descender
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_label
                                                        attribute:NSLayoutAttributeBaseline
                                                       multiplier:1.0f
                                                         constant:_font.descender * -1.0f]];
}

// TODO: Make an autolayout utils class
- (NSArray <NSLayoutConstraint *> *)fat_existingConstraintsForViews:(NSArray <UIView *> *)views
                                                             onView:(UIView *)parentView {
  NSMutableArray <NSLayoutConstraint *> *constraints = [[NSMutableArray alloc] init];
  for (NSLayoutConstraint *layoutConstraint in parentView.constraints) {
    if ([views indexOfObject:layoutConstraint.firstItem] != NSNotFound || [views indexOfObject:layoutConstraint.secondItem] != NSNotFound) {
      [constraints addObject:layoutConstraint];
    }
  }
  return constraints;
}

@end
