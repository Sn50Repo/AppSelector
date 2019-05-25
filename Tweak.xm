#import "CKMessageEntryView.h"
#import <AudioToolbox/AudioToolbox.h>
#import "CKBrowserPluginCell.h"
#import "SettingsReader.h"

static BOOL openStrip;
static BOOL stripOpen;
static BOOL appOpen;

static BOOL openWhenDown;

static BOOL pressed;

static NSInteger appSection;
static NSInteger appId;

static UIColor *defaultColor;
static UIImage *icon;

static void initTweak () {
	openStrip = false;
	stripOpen = false;
	appOpen = false;

	openWhenDown = false;

	pressed = false;

	appSection = 0;
	appId = 0;

	CFPreferencesSetAppValue(CFSTR("AppStripEnabled"), kCFBooleanFalse, CFSTR("com.apple.MobileSMS"));
	CFPreferencesAppSynchronize(CFSTR("com.apple.MobileSMS"));
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.apple.MobileSMS.AppStripEnabled"), NULL, NULL, TRUE);
}

%hook CKMessageEntryView
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

	NSString* functionType = [SettingsReader getObject:@"function"];
	if (![functionType isEqual:@"default"]) { return; }

	// Called when user swipes down with app strip still open
	if (![self isKeyboardVisible] && stripOpen && !appOpen && !openWhenDown) {
		[self browserButtonTapped:self.browserButton];
	}

	// Called when app strip is open and an app is selected
	if (stripOpen && appOpen) {
		[self browserButtonTapped:self.browserButton];
	}
  
  	// Set Browser Button Image
	if ([self appStrip] != nil && [self browserButton] != nil) {
		NSIndexPath *appIndex = [NSIndexPath indexPathForRow:appId inSection:appSection];
		CKBrowserPluginCell *cell = [[self appStrip] collectionView:[[self appStrip] collectionView] cellForItemAtIndexPath:appIndex];
		icon = cell.browserImage.image;
	}

	// -- v1.0.4 - Fixes issues causes by leaving the app strip open and beginning to type
	if ([self isSendingMessage] && stripOpen) {
		[self browserButtonTapped:self.browserButton];
	}
}

- (void) photoButtonTapped:(id)arg1 {
	NSString* functionType = [SettingsReader getObject:@"function"];
	if ([functionType isEqual:@"camera"]) {
		if (openStrip) {
			openStrip = false;
			%orig;
		} else {
			
			if ([[self.browserButton ckTintColor] isEqual:defaultColor]) {
				NSIndexPath *appIndex = [NSIndexPath indexPathForRow:appId inSection:appSection];
				[[self appStrip] collectionView:[[self appStrip] collectionView] didSelectItemAtIndexPath:appIndex];
			} else {
				[self browserButtonTapped:self.browserButton];
			}

		}
	} else if ([functionType isEqual:@"force"]) {
		if (openStrip) {
			openStrip = false;
			
			NSIndexPath *appIndex = [NSIndexPath indexPathForRow:appId inSection:appSection];
			[[self appStrip] collectionView:[[self appStrip] collectionView] didSelectItemAtIndexPath:appIndex];
		} else {
			if (![[self.browserButton ckTintColor] isEqual:defaultColor]) {
				[self browserButtonTapped:self.browserButton];
			} else {
				%orig;
			}
		}
	} else {
		%orig;
	}
}

- (void) browserButtonTapped:(id)arg1 {
	NSString* functionType = [SettingsReader getObject:@"function"];
	if ([functionType isEqual:@"default"]) {
		// Handle auto closing App Drawer when selecting an app
		if (stripOpen && appOpen) {
			stripOpen = false;
			appOpen = false;

			%orig;

			NSIndexPath *appIndex = [NSIndexPath indexPathForRow:appId inSection:appSection];
			[[self appStrip] collectionView:[[self appStrip] collectionView] didSelectItemAtIndexPath:appIndex];

			return;
		}

		if (defaultColor == nil) {
			defaultColor = [self.browserButton ckTintColor];
			%orig; // find a way to remove one of these
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
					NSIndexPath *appIndex = [NSIndexPath indexPathForRow:appId inSection:appSection];
					[[self appStrip] collectionView:[[self appStrip] collectionView] didSelectItemAtIndexPath:appIndex];
				} else {
					%orig;
				}
			}
		}
	} else {
		if (defaultColor == nil) {
			defaultColor = [self.browserButton ckTintColor];
			%orig; // find a way to remove one of these
			%orig;
		} else {
			%orig;
		}
	}
}
%end

%hook CKEntryViewButton
+ (id) buttonWithType:(long long)arg1 {
	return %orig(UIButtonTypeCustom);
}

- (void) layoutSubviews {
	%orig;

	if (self.entryViewButtonType == 2 && icon) {
		[self setImage:icon forState:UIControlStateNormal];
		[self setBounds:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, 40, 30)];
	}
}

- (void) touchesMoved:(id)arg1 withEvent:(id)arg2 {
	%orig;

	NSString* functionType = [SettingsReader getObject:@"function"];
	if ([self entryViewButtonType] == 2 && ![functionType isEqual:@"default"]) { return; } // App Button
	if ([self entryViewButtonType] == 0 && [functionType isEqual:@"default"]) { return; } // Camera

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

- (void) touchesEnded:(id)arg1 withEvent:(id)arg2 {
	pressed = false;
	%orig;
}
%end

%hook CKBrowserSwitcherFooterView
- (void) collectionView:(id)arg1 didSelectItemAtIndexPath:(NSIndexPath*)index {
	// if quick select is enabled, set the app to the last opened one
	if ([SettingsReader getBool:@"quick"] && [[SettingsReader getObject:@"function"] isEqual:@"default"]) {
		appSection = index.section;
		appId = index.row;
	}

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
	// -- v1.0.4 - Tames the beast (http://redd.it/4za4n1) Stops AppSelector from injecting itself anywhere else except iMessage --
	@autoreleasepool {
		NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
		NSUInteger count = args.count;
		if (count != 0) {
			NSString *executablePath = args[0];
			if (executablePath) {
				NSString *processName = [executablePath lastPathComponent];
				BOOL isSpringBoard = [processName isEqualToString:@"SpringBoard"];
				BOOL isApplication = [executablePath rangeOfString:@"/Application/"].location != NSNotFound || [executablePath rangeOfString:@"/Applications/"].location != NSNotFound;

				if ((isSpringBoard || isApplication) && [processName isEqualToString:@"MobileSMS"] && [SettingsReader getBool:@"enabled"]) {
					%init;
					initTweak();
				}
			}
		}
	}
}
