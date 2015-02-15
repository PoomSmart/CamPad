#import "../PS.h"

@interface CAMBottomBar (Addition)
- (BOOL)_shouldHideFilterButton;
@end

BOOL restore;

static BOOL LargeScreen()
{
	return [UIScreen mainScreen]._referenceBounds.size.height >= 736.0f;
}

%group preiOS8

%hook PLCameraView

%new
- (BOOL)bottomBarShouldHideFilterButton:(id)arg1
{
	return [self _shouldHideFilterButtonForMode:self.cameraMode];
}

/*- (BOOL)_shouldApplyRotationDirectlyToTopBarForOrientation:(int)orientation cameraMode:(int)mode
{
	return YES;
}

- (void)_createFlashButtonIfNecessary
{
	restore = YES;
	%orig;
	restore = NO;
}

- (void)_applyTopBarRotationForDeviceOrientation:(int)orientation
{
	restore = YES;
	%orig;
	restore = NO;
}*/

%end

%end

%group iOS8Up

%hook CAMTopBar

- (CGSize)intrinsicContentSize
{
	return CGSizeMake([[UIScreen mainScreen] _referenceBounds].size.width*0.5, 40.0f);
}

%end

%hook CAMCameraView

%new
- (BOOL)bottomBarShouldHideFilterButton:(id)arg1
{
	return [self _shouldHideFilterButtonForMode:self.cameraMode];
}

/*- (BOOL)_shouldApplyRotationDirectlyToTopBarForOrientation:(int)orientation cameraMode:(int)mode
{
	return YES;
}

- (void)_applyTopBarRotationForDeviceOrientation:(int)orientation
{
	restore = YES;
	%orig;
	restore = NO;
}*/

- (void)_createFlashButtonIfNecessary
{
	restore = YES;
	%orig;
	restore = NO;
}

- (BOOL)_isLockedToPortraitOrientation
{
	int cameraMode = self.cameraMode;
	return !(cameraMode == 1 || cameraMode == 2 || cameraMode == 6);
}

- (NSInteger)_glyphOrientationForCameraOrientation:(NSInteger)orientation
{
	int cameraMode = self.cameraMode;
	return cameraMode == 1 || cameraMode == 2 || cameraMode == 6 ? %orig : 1;
}

%end

%end

%group Common

%hook CAMCameraSpec

+ (id)specForCurrentPlatform
{
	return [[self class] specForPad];
}

- (BOOL)isPhone
{
	return restore;
}

- (BOOL)isPad
{
	return !restore;
}

%end

%hook CAMPadApplicationSpec

- (BOOL)shouldCreateFlashButton
{
	return YES;
}

/*- (BOOL)shouldCreateTopBar
{
	return YES;
}*/

%end

%hook CAMBottomBar

%new
- (BOOL)_shouldHideFilterButton
{
	NSObject <cameraViewDelegate> *cameraView = [[self delegate] retain];
	BOOL condition1 = [cameraView respondsToSelector:@selector(bottomBarShouldHideFilterButton:)] && [cameraView bottomBarShouldHideFilterButton:nil];
	BOOL condition2 = [self _isTimerButtonExpanded];
	[cameraView release];
	if (LargeScreen()) {
		return ([self.timerButton numberOfMenuItems] >= 5 && condition2) || condition1;
	}
	return condition1 || condition2;
}

- (BOOL)_shouldHideFlipButton
{
	if (LargeScreen()) {
		NSObject <cameraViewDelegate> *cameraView = [[self delegate] retain];
		BOOL shouldHide = [cameraView respondsToSelector:@selector(bottomBarShouldHideFlipButton:)] && [cameraView bottomBarShouldHideFlipButton:nil];
		[cameraView release];
		return shouldHide;
	}
	BOOL HDRExpanded = MSHookIvar<BOOL>(self, "__HDRButtonExpanded");
	MSHookIvar<BOOL>(self, "__HDRButtonExpanded") = NO;
	BOOL orig = %orig;
	MSHookIvar<BOOL>(self, "__HDRButtonExpanded") = HDRExpanded;
	return orig;
}

- (void)_updateHiddenViewsForButtonExpansionAnimated:(BOOL)animated
{
	%orig;
	BOOL shouldHideFilterButton = [self _shouldHideFilterButton];
	CAMFilterButton *filterButton = self.filterButton;
	if ([filterButton respondsToSelector:@selector(cam_setHidden:animated:)])
		[filterButton cam_setHidden:shouldHideFilterButton animated:animated];
	else if ([filterButton respondsToSelector:@selector(pl_setHidden:animated:)])
		[filterButton pl_setHidden:shouldHideFilterButton animated:animated];
	else
		filterButton.hidden = shouldHideFilterButton;
}

%end

%end

%ctor
{
	%init(Common);
	if (isiOS8Up) {
		%init(iOS8Up);
	} else {
		%init(preiOS8);
	}
}
