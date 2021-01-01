//
//  OutlineView.h
//  AtemOSC
//
//  Created by Peter Steffey on 12/26/20.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface OutlineView : NSOutlineView<NSOutlineViewDelegate, NSOutlineViewDataSource> {
	long selectedRow;
}
- (void)refreshList;
@end

NS_ASSUME_NONNULL_END
