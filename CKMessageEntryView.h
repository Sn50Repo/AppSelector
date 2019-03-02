#import "CKBrowserSwitcherFooterView.h"
#import "CKEntryViewButton.h"

@interface CKMessageEntryView : UIView
	@property (nonatomic, retain) CKBrowserSwitcherFooterView *appStrip;
	@property (nonatomic, retain) CKEntryViewButton *browserButton;

	- (void) setShowAppStrip:(bool)arg1 animated:(bool)arg2 completion:(id)arg3;
	- (void) setKeyboardVisible:(bool)arg1;
	- (bool) isKeyboardVisible;

	- (void) minifyAppStrip;
	- (void) setAppStrip:(CKBrowserSwitcherFooterView *)arg1;
	- (void) updateAppStripFrame;

	- (CKBrowserSwitcherFooterView*) appStrip;

	- (CKEntryViewButton*) browserButton;
	- (void) browserButtonTapped:(id)arg1;
	- (void) setBrowserButton:(CKEntryViewButton*)arg1;
@end