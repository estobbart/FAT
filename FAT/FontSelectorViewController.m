//
//  FontSelectorViewController.m
//  FontAlignment
//
//  Created by Eric Stobbart on 1/29/16.
//  Copyright © 2016 Eric Stobbart. All rights reserved.
//

#import "FontSelectorViewController.h"
#import "FATContainerViewController.h"
#import "FontPresenterViewController.h"
#import "FontLoaderViewController.h"

@import CoreText;

/*
 TODO:

 - Show the added fonts in a different background, or some other indicator
 
 */


@implementation FontSelectorViewController {
  NSString *_cellIdentifier;
  UINavigationItem *_uiNavigationItem;

  NSString *_addedFontName;
  NSIndexPath *_addedFontIndexPath;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  Class _class = [UITableViewCell class];
  _cellIdentifier = NSStringFromClass(_class);
  [self.tableView registerClass:_class
         forCellReuseIdentifier:_cellIdentifier];

  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self
         selector:@selector(fat_registeredFontChange:)
             name:(NSString *)kCTFontManagerRegisteredFontsChangedNotification
           object:nil];
}

- (void)fat_registeredFontChange:(NSNotification *)note {
  /*

   For some reason you cant get the descriptors from this URL.

   __CFNotification 0x7fc0ea5d3bf0 {name = CTFontManagerFontChangedNotification; userInfo = {
     CTFontManagerAvailableFontURLsAdded =     (
       "file://..."
     );
   }}
   
   CFErrorRef error;
   Boolean reachable = CFURLResourceIsReachable((__bridge CFURLRef)(fileURL), &error);
   // error says file does not exist.
   CFArrayRef descriptors =  CTFontManagerCreateFontDescriptorsFromURL((__bridge CFURLRef)(fileURL));
   
   http://stackoverflow.com/questions/35137301/ios-font-name-from-kctfontmanagerregisteredfontschangednotification-notification

   */
  NSDictionary *userInfo = [note userInfo];
  CFURLRef fileURL = (__bridge CFURLRef)([userInfo objectForKey:@"CTFontManagerAvailableFontURLsAdded"][0]);
  CFArrayRef allDescriptors =  CTFontManagerCreateFontDescriptorsFromURL(fileURL);
  // I only happen to get a single descriptor
  CTFontDescriptorRef descriptor = CFArrayGetValueAtIndex(allDescriptors, 0);
  CFStringRef name = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute);
  NSLog(@"Name:%@", name);
  CFRelease(allDescriptors);

//  NSString *fragment = fileURL.fragment;
//  NSArray<NSString *> *components = [fragment componentsSeparatedByString:@"="];
   _addedFontName = CFBridgingRelease(name);
  [self.tableView reloadData];
  [self.tableView scrollToRowAtIndexPath:_addedFontIndexPath
                        atScrollPosition:UITableViewScrollPositionTop
                                animated:YES];
}

- (void)fat_fontNameAdded:(NSNotification *)note {

}


- (UINavigationItem *)navigationItem {
  if (!_uiNavigationItem) {
    _uiNavigationItem = [[UINavigationItem alloc] initWithTitle:@"Select a font"];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setAttributedTitle:[[NSAttributedString alloc] initWithString:@"+"
                                                            attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:24.0f]}]
                   forState:UIControlStateNormal];
    [btn sizeToFit];
    [btn addTarget:self
            action:@selector(fat_addFont:)
  forControlEvents:UIControlEventTouchUpInside];
    _uiNavigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
  }
  return _uiNavigationItem;
}

- (void)fat_addFont:(id)sender {
  FontLoaderViewController *flVC = [[FontLoaderViewController alloc] init];
  [((FATContainerViewController *)self.parentViewController) pushViewController:flVC];
}

- (NSString *)fat_fontNameForIndexPath:(NSIndexPath *)indexPath {
  NSString *familyName = [UIFont familyNames][indexPath.section];
  return [UIFont fontNamesForFamilyName:familyName][indexPath.row];
}

#pragma mark - @protocol UITableViewDataSource <NSObject>

// Default is 1 if not implemented
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return [UIFont familyNames].count;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  NSString *familyName = [UIFont familyNames][section];
  NSArray *fontNames = [UIFont fontNamesForFamilyName:familyName];
  return fontNames.count;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:_cellIdentifier];
  NSString *fontName = [self fat_fontNameForIndexPath:indexPath];
  NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:fontName
                                                                   attributes:
    @{NSFontAttributeName: [UIFont fontWithName:fontName size:[UIFont systemFontSize]]}];
  cell.textLabel.attributedText = attrString;
  if (_addedFontName && [_addedFontName isEqualToString:fontName]) {
    _addedFontIndexPath = indexPath;
  }
  return cell;
}

// fixed font style. use custom view (UILabel) if you want something different
- (nullable NSString *)tableView:(UITableView *)tableView
         titleForHeaderInSection:(NSInteger)section {
  return [UIFont familyNames][section];
}

//- (nullable NSString *)tableView:(UITableView *)tableView
//         titleForFooterInSection:(NSInteger)section {
//  return nil;
//}

// Editing

// Individual rows can opt out of having the -editing property set for them. If not implemented, all rows are assumed to be editable.
//- (BOOL)tableView:(UITableView *)tableView
//canEditRowAtIndexPath:(NSIndexPath *)indexPath { return NO; }

// Moving/reordering

// Allows the reorder accessory view to optionally be shown for a particular row. By default, the reorder control will be shown only if the datasource implements -tableView:moveRowAtIndexPath:toIndexPath:
//- (BOOL)tableView:(UITableView *)tableView
//canMoveRowAtIndexPath:(NSIndexPath *)indexPath { return NO; }

// Index

// return list of section titles to display in section index view (e.g. "ABCD...Z#")
//- (nullable NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView { return nil; }

// tell table which section corresponds to section title/index (e.g. "B",1))
//- (NSInteger)tableView:(UITableView *)tableView
//sectionForSectionIndexTitle:(NSString *)title
//               atIndex:(NSInteger)index { return 0; }

// Data manipulation - insert and delete support

// After a row has the minus or plus button invoked (based on the UITableViewCellEditingStyle for the cell), the dataSource must commit the change
// Not called for edit actions using UITableViewRowAction - the action's handler will be invoked instead
//- (void)tableView:(UITableView *)tableView
//commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
//forRowAtIndexPath:(NSIndexPath *)indexPath {}

// Data manipulation - reorder / moving support

//- (void)tableView:(UITableView *)tableView
//moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath
//      toIndexPath:(NSIndexPath *)destinationIndexPath {}

#pragma mark - protocol UITableViewDelegate<NSObject, UIScrollViewDelegate>

// Display customization

//- (void)tableView:(UITableView *)tableView
//  willDisplayCell:(UITableViewCell *)cell
//forRowAtIndexPath:(NSIndexPath *)indexPath {}

//- (void)tableView:(UITableView *)tableView
//willDisplayHeaderView:(UIView *)view
//       forSection:(NSInteger)section {}

//- (void)tableView:(UITableView *)tableView
//willDisplayFooterView:(UIView *)view
//       forSection:(NSInteger)section {}

//- (void)tableView:(UITableView *)tableView
//didEndDisplayingCell:(UITableViewCell *)cell
//forRowAtIndexPath:(NSIndexPath*)indexPath {}

//- (void)tableView:(UITableView *)tableView
//didEndDisplayingHeaderView:(UIView *)view
//       forSection:(NSInteger)section {}

//- (void)tableView:(UITableView *)tableView
//didEndDisplayingFooterView:(UIView *)view
//       forSection:(NSInteger)section {}

// Variable height support
//
//- (CGFloat)tableView:(UITableView *)tableView
//heightForRowAtIndexPath:(NSIndexPath *)indexPath { return 0.0f; }

//- (CGFloat)tableView:(UITableView *)tableView
//heightForHeaderInSection:(NSInteger)section { return 0.0f; }

//- (CGFloat)tableView:(UITableView *)tableView
//heightForFooterInSection:(NSInteger)section { return 0.0f; }

// Use the estimatedHeight methods to quickly calcuate guessed values which will allow for fast load times of the table.
// If these methods are implemented, the above -tableView:heightForXXX calls will be deferred until views are ready to be displayed, so more expensive logic can be placed there.
//- (CGFloat)tableView:(UITableView *)tableView
//estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath { return 0.0f; }

//- (CGFloat)tableView:(UITableView *)tableView
//estimatedHeightForHeaderInSection:(NSInteger)section { return 0.0f; }

//- (CGFloat)tableView:(UITableView *)tableView
//estimatedHeightForFooterInSection:(NSInteger)section { return 0.0f; }

// Section header & footer information. Views are preferred over title should you decide to provide both

// custom view for header. will be adjusted to default or specified header height
//- (nullable UIView *)tableView:(UITableView *)tableView
//        viewForHeaderInSection:(NSInteger)section { return nil; }

// custom view for footer. will be adjusted to default or specified footer height
//- (nullable UIView *)tableView:(UITableView *)tableView
//        viewForFooterInSection:(NSInteger)section { return nil; }

// Accessories (disclosures).

//- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView
//         accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath { return 0; }

//- (void)tableView:(UITableView *)tableView
//accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {}

// Selection

// -tableView:shouldHighlightRowAtIndexPath: is called when a touch comes down on a row.
// Returning NO to that message halts the selection process and does not cause the currently selected row to lose its selected look while the touch is down.
//- (BOOL)tableView:(UITableView *)tableView
//shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath { return NO; }

//- (void)tableView:(UITableView *)tableView
//didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {}

//- (void)tableView:(UITableView *)tableView
//didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath {}

// Called before the user changes the selection. Return a new indexPath, or nil, to change the proposed selection.
//- (nullable NSIndexPath *)tableView:(UITableView *)tableView
//           willSelectRowAtIndexPath:(NSIndexPath *)indexPath { return nil; }

//- (nullable NSIndexPath *)tableView:(UITableView *)tableView
//         willDeselectRowAtIndexPath:(NSIndexPath *)indexPath { return nil; }

// Called after the user changes the selection.
- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *fontName = [self fat_fontNameForIndexPath:indexPath];
  UIFont *font = [UIFont fontWithName:fontName size:[UIFont systemFontSize]];
  FontPresenterViewController *fpVC = [[FontPresenterViewController alloc] initWithFont:font];
  [((FATContainerViewController *)self.parentViewController) pushViewController:fpVC];
}

//- (void)tableView:(UITableView *)tableView
//didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {}

// Editing

// Allows customization of the editingStyle for a particular cell located at 'indexPath'. If not implemented, all editable cells will have UITableViewCellEditingStyleDelete set for them when the table has editing property set to YES.
//- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
//           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath { return 0; }

//- (nullable NSString *)tableView:(UITableView *)tableView
//titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath { return nil; }

// supercedes -tableView:titleForDeleteConfirmationButtonForRowAtIndexPath: if return value is non-nil
//- (nullable NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView
//                           editActionsForRowAtIndexPath:(NSIndexPath *)indexPath { return nil; }

// Controls whether the background is indented while editing.  If not implemented, the default is YES.  This is unrelated to the indentation level below.  This method only applies to grouped style table views.
//- (BOOL)tableView:(UITableView *)tableView
//shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath { return NO; }

// The willBegin/didEnd methods are called whenever the 'editing' property is automatically changed by the table (allowing insert/delete/move). This is done by a swipe activating a single row
//- (void)tableView:(UITableView*)tableView
//willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {}

//- (void)tableView:(UITableView*)tableView
//didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {}

// Moving/reordering

// Allows customization of the target row for a particular row as it is being moved/reordered
//- (NSIndexPath *)tableView:(UITableView *)tableView
//targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath
//       toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath { return nil; }

// Indentation

// return 'depth' of row for hierarchies
//- (NSInteger)tableView:(UITableView *)tableView
//indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath { return 0; }

// Copy/Paste.  All three methods must be implemented by the delegate.

//- (BOOL)tableView:(UITableView *)tableView
//shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath { return NO; }

//- (BOOL)tableView:(UITableView *)tableView
// canPerformAction:(SEL)action
//forRowAtIndexPath:(NSIndexPath *)indexPath
//       withSender:(nullable id)sender { return NO; }

//- (void)tableView:(UITableView *)tableView
//    performAction:(SEL)action
//forRowAtIndexPath:(NSIndexPath *)indexPath
//       withSender:(nullable id)sender {}

// Focus

//- (BOOL)tableView:(UITableView *)tableView
//canFocusRowAtIndexPath:(NSIndexPath *)indexPath { return NO; }

//- (BOOL)tableView:(UITableView *)tableView
//shouldUpdateFocusInContext:(UITableViewFocusUpdateContext *)context { return NO; }

//- (void)tableView:(UITableView *)tableView
//didUpdateFocusInContext:(UITableViewFocusUpdateContext *)context
//withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {}

//- (nullable NSIndexPath *)indexPathForPreferredFocusedViewInTableView:(UITableView *)tableView { return nil; }

#pragma mark - protocol UIScrollViewDelegate<NSObject>

// any offset changes
//- (void)scrollViewDidScroll:(UIScrollView *)scrollView {}

// any zoom scale changes
//- (void)scrollViewDidZoom:(UIScrollView *)scrollView {}

// called on start of dragging (may require some time and or distance to move)
//- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {}

// called on finger up if the user dragged. velocity is in points/millisecond. targetContentOffset may be changed to adjust where the scroll view comes to rest
//- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
//                     withVelocity:(CGPoint)velocity
//              targetContentOffset:(inout CGPoint *)targetContentOffset {}

// called on finger up if the user dragged. decelerate is true if it will continue moving afterwards
//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
//                  willDecelerate:(BOOL)decelerate {}

// called on finger up as we are moving
//- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {}

// called when scroll view grinds to a halt
//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {}

// called when setContentOffset/scrollRectVisible:animated: finishes. not called if not animating
//- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {}

// return a view that will be scaled. if delegate returns nil, nothing happens
//- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView { return nil; }

// called before the scroll view begins zooming its content
//- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView
//                          withView:(nullable UIView *)view {}

// scale between minimum and maximum. called after any 'bounce' animations
//- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView
//                       withView:(nullable UIView *)view
//                        atScale:(CGFloat)scale {}

// return a yes if you want to scroll to the top. if not defined, assumes YES
//- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView { return nil; }

// called when scrolling animation finished. may be called immediately if already at top
//- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {}

@end
