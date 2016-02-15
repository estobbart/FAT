//
//  FAKit.h
//  FontAlignment
//
//  Created by Eric Stobbart on 1/29/16.
//  Copyright © 2016 Eric Stobbart. All rights reserved.
//

// FATKit sounds like Fat Kid, might rename it.

#ifndef FAKit_h
#define FAKit_h

#define kFABorderWidth 0.5f
#define kFACornerRadius 8.0f


#define EQUAL_ATTRIBUTES(x, y, attr) [NSLayoutConstraint constraintWithItem:x\
                                                                  attribute:attr\
                                                                  relatedBy:NSLayoutRelationEqual\
                                                                     toItem:y\
                                                                  attribute:attr\
                                                                 multiplier:1.0f\
                                                                   constant:0.0f]

#endif /* FAKit_h */
