#import "CKMessageEntryView.h"
#import <AudioToolbox/AudioToolbox.h>
#import "AppSelector.h"
#import "CKBrowserPluginCell.h"

static BOOL openStrip;
static BOOL stripOpen;
static BOOL appOpen;

static BOOL openWhenDown;

static BOOL pressed;

static NSInteger appSection;
static NSInteger appId;

static UIColor *defaultColor;
static CIImage *newImage;

// -- v1.0.2 - fixed version issue (http://redd.it/2xmdng) --

// issue: opening app drawer, then beginning to type then opening an app fucks everything up
// possible fix: check if user is typing, if so hide it

// -- v1.0.2 - magically fixed itself --
// issue: Quick Reply doesn't function (no clue why) [its fixed?]

// issue: Opening 'More' app causes graphical bugs
// temp. fix: the user can swipe out of the conversation and come back in

// --

static void initTweak () {
	openStrip = false;
	stripOpen = false;
	appOpen = false;

	openWhenDown = false;

	pressed = false;

	appSection = 0;
	appId = 0;
}

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

	// Resets defaultColor when appStrip is nil. This is used for when the user switches chats and defaultColor is already set
	if ([self appStrip] == nil && defaultColor != nil) {
		defaultColor = nil;
	}

	// Setup
	if (defaultColor == nil) {
		[self browserButtonTapped:self.browserButton];
	}

	// Called when user swipes down with app strip still open
	if (![self isKeyboardVisible] && stripOpen && !appOpen && !openWhenDown) {
		[self browserButtonTapped:self.browserButton];
	}

	// Called when app strip is open and an app is selected
	if (stripOpen && appOpen) {
		[self browserButtonTapped:self.browserButton];
	}

	// Change Browser Button Image to Quick Select App Image
	// issue: looks like a solid oval
	if ([self appStrip] != nil) {
		NSIndexPath *appIndex = [[NSIndexPath indexPathForRow:appId inSection:appSection] retain];
		CKBrowserPluginCell *cell = [[self appStrip] collectionView:[[self appStrip] collectionView] cellForItemAtIndexPath:appIndex];
		if ([[cell browserImage] image] != nil) {
			if ([self browserButton] != nil) {
				newImage = [[cell browserImage] image];
			}
		}
	}
}

- (void) browserButtonTapped:(id)arg1 {
	// Handle auto closing App Drawer when selecting an app
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
			if ([[self.browserButton ckTintColor] isEqual:defaultColor]) {
				NSIndexPath *appIndex = [[NSIndexPath indexPathForRow:appId inSection:appSection] retain];
				[[self appStrip] collectionView:[[self appStrip] collectionView] didSelectItemAtIndexPath:appIndex];
			} else {
				%orig;
			}
		}
	}
}
%end

%hook CKEntryViewButton
- (void) touchesMoved:(id)arg1 withEvent:(id)arg2 {
	%orig;

	// -- v1.0.2 - removed force touch from camera button
	if ([self entryViewButtonType] != 2) { return; }// App Button

	UITouch *touch = [arg1 anyObject];

	CGFloat maximumPossibleForce = touch.maximumPossibleForce;
	CGFloat force = touch.force;
	CGFloat normalizedForce = force/maximumPossibleForce;

	if (normalizedForce >= 0.75 && !pressed) {
		pressed = true;
		AudioServicesPlaySystemSound(1519);
		if (!stripOpen && [[self ckTintColor] isEqual:defaultColor]) openStrip = true;
		// for reference: camera button id
		//else if ([self entryViewButtonType] == 0) { } // Camera Button
	}
}

// -- Successfully changes image (but tint covers it to be a solid oval)
- (id) _generateBackdropMaskImage {
	if (self.entryViewButtonType == 2) {
		return nil;
	} else return %orig;
}

- (void) setImage:(id)arg1 forState:(id)arg2 {
	if (self.entryViewButtonType == 2) {
		return %orig(newImage, arg2);
	} else return %orig;
}

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

%ctor {
	@autoreleasepool {
		NSString *bundleId = NSBundle.mainBundle.bundleIdentifier;

		if ([bundleId isEqualToString:@"com.apple.MobileSMS"]) {
			initTweak();
		}
	}
}