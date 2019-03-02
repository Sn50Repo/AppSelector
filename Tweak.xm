#import "CKMessageEntryView.h"
#import <AudioToolbox/AudioToolbox.h>
#import "AppSelector.h"

static BOOL openStrip = false;
static BOOL stripOpen = false;
static BOOL appOpen = false;

static BOOL openWhenDown = false;

static BOOL pressed = false;

static NSInteger appSection = 0;
static NSInteger appId = 0;

static UIColor *defaultColor;

// issue: opening app drawer, then beginning to type then opening an app fucks everything up

// --

// static void loadQuickSelect () {
// 	NSDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:kPrefsPlistPath];
// 	appSection = settings[@"DefaultSection"] ?: 0;
// 	appId = settings[@"DefaultId"] ?: 0;
// }

// static void saveAppInfo () {
// 	settings[@"DefaultSection"] = appSection;
// 	settings[@"DefaultId"] = appId;
// 	[settings writeToFile:kPrefsPlistPath atomically:YES];
// }

// --

%hook CKMessageEntryView
+ (id) sharedInstance {
	return %orig;
}

- (void) layoutSubviews {
	%orig;

	if ([self appStrip] == nil && defaultColor != nil) {
		defaultColor = nil;
	}

	if (defaultColor == nil) {
		[self browserButtonTapped:self.browserButton];
	}

	if (![self isKeyboardVisible] && stripOpen && !appOpen && !openWhenDown) {
		[self browserButtonTapped:self.browserButton];
	}

	if (stripOpen && appOpen) {
		[self browserButtonTapped:self.browserButton];
	}
}

- (void) browserButtonTapped:(id)arg1 {
	// Handle auto closing App Drawer when selecting an app
	// -- v1.0.1 - fixed issue where app crashes when keyboard is hidden --
	if (stripOpen && appOpen) {
		stripOpen = false;
		appOpen = false;

		%orig;

		NSIndexPath *appIndex = [[NSIndexPath indexPathForRow:appId inSection:appSection] retain];
		[[self appStrip] collectionView:[[self appStrip] collectionView] didSelectItemAtIndexPath:appIndex];

		return;
	}

	if (defaultColor == nil) {
		defaultColor = [self.browserButton ckTintColor];
		%orig;
		%orig;
	} else {
		if (openStrip) {
			if (![self isKeyboardVisible]) openWhenDown = true;

			%orig;
			openStrip = false;
			stripOpen = true;
		} else if (stripOpen) {
			%orig;
			stripOpen = false;
			openWhenDown = false;
		} else {
			// -- v1.0.1 - fixes appStrip being nil when changing contacts --
			// issue: causes graphical bugs
			if ([self appStrip] == nil) {
				%orig;
				%orig;
			}

			if ([[self.browserButton ckTintColor] isEqual:defaultColor]) {
				NSIndexPath *appIndex = [[NSIndexPath indexPathForRow:appId inSection:appSection] retain];
				[[self appStrip] collectionView:[[self appStrip] collectionView] didSelectItemAtIndexPath:appIndex];
			} else {
				%orig;
			}
		}
	}
}

// - (void) setShowAppStrip:(bool)arg1 animated:(bool)arg2 completion:(id)arg3 {
// 	if (appOpen) {
// 		%orig(false, true, nil);
// 		self.backgroundColor = [UIColor redColor];
// 		appOpen = false;
// 		return;
// 	}
// 	%orig;
// }
%end

%hook CKEntryViewButton
- (void) touchesMoved:(id)arg1 withEvent:(id)arg2 {
	%orig;

	UITouch *touch = [arg1 anyObject];

	CGFloat maximumPossibleForce = touch.maximumPossibleForce;
	CGFloat force = touch.force;
	CGFloat normalizedForce = force/maximumPossibleForce;

	if (normalizedForce >= 0.75 && !pressed) {
		pressed = true;
		AudioServicesPlaySystemSound(1519);
		if (!stripOpen && [[self ckTintColor] isEqual:defaultColor]) openStrip = true;
	}
}

// -- v1.0.1 - fixed haptic feedback from fritzing --
- (void) touchesEnded:(id)arg1 withEvent:(id)arg2 {
	%orig;
	pressed = false;
}
%end

%hook CKBrowserSwitcherFooterView
- (void) collectionView:(id)arg1 didSelectItemAtIndexPath:(id)arg2 {
	NSIndexPath *index = (NSIndexPath*)arg2;
	appSection = index.section;
	appId = index.row;

	if (stripOpen) {
		%orig(nil, nil);
		appOpen = true;
		[self.superview setNeedsLayout];
		[self.superview layoutIfNeeded];
	} else {
		%orig;
	}
}
%end