#import <UIKit/UIKit.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>
#define CGRectSetY(rect, y) CGRectMake(rect.origin.x, y, rect.size.width, rect.size.height)

NSInteger statusBarStyle, screenRoundness, appswitcherRoundness;
BOOL enabled, wantsHomeBarSB, wantsHomeBarLS, wantsKeyboardDock, wantsRoundedAppSwitcher, wantsReduceRows, wantsRoundedCorners, wants11Camera, wantsXButtons, wantsbottomInset;
BOOL disableGestures = NO, wantsGesturesDisabledWhenKeyboard, wantsCCGrabber, wantsPIP, wantsProudLock, wantsHideSBCC,wantsLSShortcuts, wantsBatteryPercent, wantsiPadDock;
BOOL wantsDeviceSpoofing, wantsCompatabilityMode, wantsiPadMultitasking;

%hook BSPlatform
- (NSInteger)homeButtonType {
	return 2;
}
%end

%group ForceDefaultKeyboard
%hook UIKeyboardImpl
+(UIEdgeInsets)deviceSpecificPaddingForInterfaceOrientation:(NSInteger)orientation inputMode:(id)mode {
    UIEdgeInsets const orig = %orig;    
    return UIEdgeInsetsMake(orig.top, 0, 0, 0);
}
%end
%end

@interface CSQuickActionsView : UIView
- (UIEdgeInsets)_buttonOutsets;
@property (nonatomic, retain) UIControl *flashlightButton; 
@property (nonatomic, retain) UIControl *cameraButton;
@end

%hook CSQuickActionsView
- (BOOL)_prototypingAllowsButtons {
	return wantsLSShortcuts;
}
- (void)_layoutQuickActionButtons {
    CGRect const screenBounds = [UIScreen mainScreen].bounds;
    int const y = screenBounds.size.height - 90 - [self _buttonOutsets].top;

    [self flashlightButton].frame = CGRectMake(46, y, 50, 50);
	[self cameraButton].frame = CGRectMake(screenBounds.size.width - 96, y, 50, 50);
}
%end

%group HideSBCC
%hook CCUIModularControlCenterOverlayViewController
- (CCUIHeaderPocketView*)overlayHeaderView {
    return nil;
}
%end
%end

%group batteryPercent
%hook _UIBatteryView 
-(BOOL)_currentlyShowsPercentage {
    return YES;
}
-(BOOL)_shouldShowBolt {
    return NO;
}
%end 

%hook _UIStatusBarStringView  
- (void)setText:(NSString *)text {
	if ([text containsString:@"%"]) 
      return;
    else 
       %orig(text);
}     
%end
%end

%hook SBReachabilitySettings
- (void)setSystemWideSwipeDownHeight:(double) systemWideSwipeDownHeight { 
    %orig(100);
}
%end

%group StatusBarX
%hook _UIStatusBarVisualProvider_iOS
+ (Class)class {
    return NSClassFromString(@"_UIStatusBarVisualProvider_Split58");
}
%end

%hook SBIconListGridLayoutConfiguration
- (UIEdgeInsets)portraitLayoutInsets { 
    UIEdgeInsets const x = %orig;
    NSUInteger const locationRows = MSHookIvar<NSUInteger>(self, "_numberOfPortraitRows");
    if (locationRows == 3) {
        return x;
    }
    return UIEdgeInsetsMake(x.top+10, x.left, x.bottom, x.right);
}
%end

%hook UIScrollView
- (UIEdgeInsets)adjustedContentInset {
	UIEdgeInsets orig = %orig;

    if (orig.top == 64) orig.top = 88; 
    else if (orig.top == 32) orig.top = 0;
    else if (orig.top == 128) orig.top = 152;

    return orig;
}
%end
%end

%group StatusBariPad
%hook _UIStatusBarVisualProvider_iOS
+ (Class)class {
    if (wantsRoundedCorners && screenRoundness > 15) return NSClassFromString(@"_UIStatusBarVisualProvider_RoundedPad_ForcedCellular");
    return NSClassFromString(@"_UIStatusBarVisualProvider_Pad_ForcedCellular");
}
%end

%hook CCUIHeaderPocketView
- (void)setFrame:(CGRect)frame {
    if (wantsRoundedCorners && screenRoundness > 15) %orig(CGRectSetY(frame, -20));
    else %orig(CGRectSetY(frame, -24));
}
%end

%hook SBFHomeGrabberSettings
- (BOOL)isEnabled {
    return wantsHomeBarSB;
} 
%end

%group hideHomeBarLS
%hook CSTeachableMomentsContainerView
-(void)setHomeAffordanceContainerView:(UIView *)arg1{
    return;
}
%end
%end

%group completelyRemoveHomeBar
%hook MTLumaDodgePillSettings
- (void)setHeight:(double)arg1 {
	arg1 = 0;
	%orig;
}
%end
%end

%group KeyboardDock
%hook UIKeyboardImpl
+(UIEdgeInsets)deviceSpecificPaddingForInterfaceOrientation:(NSInteger)orientation inputMode:(id)mode {
    UIEdgeInsets orig = %orig;
    if (!NSClassFromString(@"BarmojiCollectionView")) 
         orig.bottom = 46;
	if (orig.left == 75)  {
        orig.left = 0;
        orig.right = 0;
    }
    return orig;
}
%end

%hook UIKeyboardDockView
- (CGRect)bounds {
    CGRect const bounds = %orig;
    if (NSClassFromString(@"BarmojiCollectionView")) 
        return bounds;

    return CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height + 15);
}
%end
%end


%group roundedDock
%hook UITraitCollection
- (CGFloat)displayCornerRadius {
	return appswitcherRoundness;
}
%end
%end


%group reduceRows
%hook SBIconListView
-(unsigned long long)iconRowsForCurrentOrientation{
    int const orig = %orig;
    if (orig < 4) return orig;
	return orig - wantsReduceRows + wantsiPadDock;
}
%end
%end


%group ccGrabber

@interface CSTeachableMomentsContainerView : UIView
@property(retain, nonatomic) UIView *controlCenterGrabberView;
@property(retain, nonatomic) UIView *controlCenterGrabberEffectContainerView;
@property (retain, nonatomic) UIImageView * controlCenterGlyphView; 
@end

%hook CSTeachableMomentsContainerView
- (void)_layoutControlCenterGrabberAndGlyph  {
    %orig;
    if (statusBarStyle == 2) {
        self.controlCenterGrabberEffectContainerView.frame = CGRectMake(self.frame.size.width - 73,36,46,2.5);
        self.controlCenterGrabberView.frame = CGRectMake(0,0,46,2.5);
        self.controlCenterGlyphView.frame = CGRectMake(315,45,16.6,19.3);
    } else if (statusBarStyle == 1) {
        self.controlCenterGrabberEffectContainerView.frame = CGRectMake(self.frame.size.width - 75.5,24,60.5,2.5);
        self.controlCenterGrabberView.frame = CGRectMake(0,0,60.5,2.5);
        self.controlCenterGlyphView.frame = CGRectMake(320,35,16.6,19.3);
    }
}
%end
%end

// Allows you to use the non-X iPhone button combinations. For some reason only works on some devices - Just as the iPhone X Combinations
%group originalButtons
%hook SBLockHardwareButtonActions
- (id)initWithHomeButtonType:(long long)arg1 proximitySensorManager:(id)arg2 {
    return %orig(1, arg2);
}
%end

%hook SBHomeHardwareButtonActions
- (id)initWitHomeButtonType:(long long)arg1 {
    return %orig(1);
}
%end

int applicationDidFinishLaunching = 2;

%hook SBPressGestureRecognizer
- (void)setAllowedPressTypes:(NSArray *)arg1 {
    NSArray *lockHome = @[@104, @101];
    NSArray *lockVol = @[@104, @102, @103];
    if ([arg1 isEqual:lockVol] && applicationDidFinishLaunching == 2) {
        %orig(lockHome);
        applicationDidFinishLaunching--;
        return;
    }
    %orig;
}
%end

%hook SBClickGestureRecognizer
- (void)addShortcutWithPressTypes:(id)arg1 {
    if (applicationDidFinishLaunching == 1) {
        applicationDidFinishLaunching--;
        return;
    }
    %orig;
}
%end

%hook SBHomeHardwareButton
- (id)initWithScreenshotGestureRecognizer:(id)arg1 homeButtonType:(long long)arg2 buttonActions:(id)arg3 gestureRecognizerConfiguration:(id)arg4 {
    return %orig(arg1,1,arg3,arg4);
}
- (id)initWithScreenshotGestureRecognizer:(id)arg1 homeButtonType:(long long)arg2 {
    return %orig(arg1,1);
}
%end

%hook SBLockHardwareButton
- (id)initWithScreenshotGestureRecognizer:(id)arg1 shutdownGestureRecognizer:(id)arg2 proximitySensorManager:(id)arg3 homeHardwareButton:(id)arg4 volumeHardwareButton:(id)arg5 buttonActions:(id)arg6 homeButtonType:(long long)arg7 createGestures:(_Bool)arg8 {
    return %orig(arg1,arg2,arg3,arg4,arg5,arg6,1,arg8);
}
- (id)initWithScreenshotGestureRecognizer:(id)arg1 shutdownGestureRecognizer:(id)arg2 proximitySensorManager:(id)arg3 homeHardwareButton:(id)arg4 volumeHardwareButton:(id)arg5 homeButtonType:(long long)arg6 {
    return %orig(arg1,arg2,arg3,arg4,arg5,1);
}
%end

%hook SBVolumeHardwareButton
- (id)initWithScreenshotGestureRecognizer:(id)arg1 shutdownGestureRecognizer:(id)arg2 homeButtonType:(long long)arg3 {
    return %orig(arg1,arg2,1);
}
%end
%end

%group roundedCorners

@interface _UIRootWindow : UIView
@property (setter=_setContinuousCornerRadius:, nonatomic) double _continuousCornerRadius;
@end

%hook _UIRootWindow
-(void)layoutSubviews {
    %orig;
    self.clipsToBounds = YES;
    self._continuousCornerRadius = screenRoundness;
    return;
}
%end

%hook SBReachabilityBackgroundView
- (double)_displayCornerRadius {
    return screenRoundness;
}
%end
%end 

extern "C" Boolean MGGetBoolAnswer(CFStringRef);
%hookf(Boolean, MGGetBoolAnswer, CFStringRef key) {
#define keyy(key_) CFEqual(key, CFSTR(key_))
    if (keyy("nVh/gwNpy7Jv1NOk00CMrw"))
        return wantsPIP;
    return %orig;
}

%group ProudLock
%hook SBUIPasscodeBiometricResource
-(BOOL)hasPearlSupport {
    return YES;
}
-(BOOL)hasMesaSupport {
    return NO;
}
%end

@interface SBDashBoardMesaUnlockBehaviorConfiguration : NSObject
- (BOOL)_isAccessibilityRestingUnlockPreferenceEnabled;
@end

@interface SBDashBoardBiometricUnlockController : NSObject
@end

@interface SBLockScreenController : NSObject
+ (id)sharedInstance;
- (BOOL)_finishUIUnlockFromSource:(int)arg1 withOptions:(id)arg2;
@end

CGFloat offset = 0;

%hook SBFLockScreenDateView
-(id)initWithFrame:(CGRect)arg1 {
    CGFloat const screenWidth = UIScreen.mainScreen.bounds.size.width;

	if (screenWidth <= 320) {
		offset = 20;
	} else if (screenWidth <= 375) {
		offset = 35;
	} else if (screenWidth <= 414) {
		offset = 28;
	}

    return %orig;
}
- (void)layoutSubviews {
	%orig;

	UIView* timeView = MSHookIvar<UIView*>(self, "_timeLabel");
	UIView* dateSubtitleView = MSHookIvar<UIView*>(self, "_dateSubtitleView");
	UIView* customSubtitleView = MSHookIvar<UIView*>(self, "_customSubtitleView");
	
	[timeView setFrame:CGRectSetY(timeView.frame, timeView.frame.origin.y + offset)];
	[dateSubtitleView setFrame:CGRectSetY(dateSubtitleView.frame, dateSubtitleView.frame.origin.y + offset)];
	[customSubtitleView setFrame:CGRectSetY(customSubtitleView.frame, customSubtitleView.frame.origin.y + offset)];
}
%end

%hook SBDashBoardLockScreenEnvironment
- (void)handleBiometricEvent:(unsigned long long)arg1 {
	%orig;

	if (arg1 == 4) {
		SBDashBoardBiometricUnlockController* biometricUnlockController = MSHookIvar<SBDashBoardBiometricUnlockController*>(self, "_biometricUnlockController");
		SBDashBoardMesaUnlockBehaviorConfiguration* unlockBehavior = MSHookIvar<SBDashBoardMesaUnlockBehaviorConfiguration*>(biometricUnlockController, "_biometricUnlockBehaviorConfiguration");
		
		if ([unlockBehavior _isAccessibilityRestingUnlockPreferenceEnabled]) {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				[[%c(SBLockScreenManager) sharedInstance] _finishUIUnlockFromSource:12 withOptions:nil];
			});
		}
	}
}
%end

%hook BSUICAPackageView
- (id)initWithPackageName:(id)arg1 inBundle:(id)arg2 {
	if (![arg1 hasPrefix:@"lock"]) return %orig;
	
	NSString* packageName = [arg1 stringByAppendingString:@"-896h"];

	return %orig(packageName, [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/SpringBoardUIServices.framework"]);
}
%end

%hook CSCombinedListViewController
- (UIEdgeInsets)_listViewDefaultContentInsets {
    UIEdgeInsets orig = %orig;

    orig.top += offset;
    return orig;
}
%end

%hook SBUIBiometricResource
- (id)init {
	id r = %orig;
	
	MSHookIvar<BOOL>(r, "_hasMesaHardware") = NO;
	MSHookIvar<BOOL>(r, "_hasPearlHardware") = YES;
	
	return r;
}
%end
%end

%group iPhone11Cam
%hook CAMCaptureCapabilities 
-(BOOL)isCTMSupported {
    return YES;
}
%end

%hook CAMViewfinderViewController 
-(BOOL)_wantsHDRControlsVisible{
    return NO;
}
%end

%hook CAMViewfinderViewController 
-(BOOL)_shouldUseZoomControlInsteadOfSlider {
    return YES;
}
%end
%end

// Adds a bottom inset to the camera app.
%group CameraFix
%hook CAMBottomBar 
- (void)setFrame:(CGRect)frame {
    %orig(CGRectSetY(frame, frame.origin.y -40));
}
%end

%hook CAMZoomControl
- (void)setFrame:(CGRect)frame {
    %orig(CGRectSetY(frame, frame.origin.y -30));
}
%end
%end

%group disableGesturesWhenKeyboard // iOS 13.3 and below
%hook SBFluidSwitcherGestureManager
-(void)grabberTongueBeganPulling:(id)arg1 withDistance:(double)arg2 andVelocity:(double)arg3  {
    if (!disableGestures)
        %orig;
}
%end
%end

%group newDisableGesturesWhenKeyboard // iOS 13.4 and up
%hook SBFluidSwitcherGestureManager
- (void)grabberTongueBeganPulling:(id)arg1 withDistance:(double)arg2 andVelocity:(double)arg3 andGesture:(id)arg4  {
    if (!disableGestures)
        %orig;
}
%end
%end

%group iPadDock
%hook SBFloatingDockController
+ (BOOL)isFloatingDockSupported {
	return YES;
}
%end
%end 

%group iPadMultitasking
%hook SBApplication
- (BOOL)isMedusaCapable {
	return YES;
}
%end

%hook SBPlatformController
-(long long)medusaCapabilities {
	return 2;
}
%end

%hook SBMainWorkspace
-(BOOL)isMedusaEnabled {
	return YES;
}
%end
%end 

%group BoundsHack
%hookf(int, sysctl, const int *name, u_int namelen, void *oldp, size_t *oldlenp, const void *newp, size_t newlen) {
	if (namelen == 2 && name[0] == CTL_HW && name[1] == HW_MACHINE && oldp != NULL) {
        int const ret = %orig;
        const char *mechine1 = "iPhone12,1";
        strncpy((char*)oldp, mechine1, strlen(mechine1));
        return ret;
    } else {
        return %orig;
    }
}
%hookf(int, uname, struct utsname *value) {
	int const ret = %orig;
	NSString *utsmachine = @"iPhone12,1";
	if (utsmachine) {	 
		const char *utsnameCh = utsmachine.UTF8String; 
		strcpy(value->machine, utsnameCh);
	}
    return ret;
}
%end

%group CompatabilityMode
%hook UIScreen
- (CGRect)bounds {
	CGRect bounds = %orig;
    bounds.size.height > bounds.size.width ? bounds.size.height = 812 : bounds.size.width = 812;
	return bounds;
}
%end
%end 

%hook UIWindow
- (UIEdgeInsets)safeAreaInsets {
	UIEdgeInsets orig = %orig;
    orig.bottom = wantsbottomInset ? 20 : 0;
	return orig;
}
%end

%group bottominsetfix // AWE = TikTok, TFN = Twitter, YT = Youtube
%hook AWETabBar
- (void)setFrame:(CGRect)frame {
    %orig(CGRectSetY(frame, frame.origin.y + 40));
}
%end

%hook AWEFeedTableView
- (void)setFrame:(CGRect)frame {
	%orig(CGRectMake(frame.origin.x,frame.origin.y,frame.size.width,frame.size.height + 40));
}
%end

%hook TFNNavigationBarOverlayView  
- (void)setFrame:(CGRect)frame {
    %orig(CGRectMake(frame.origin.x,frame.origin.y,frame.size.width,frame.size.height + 6));
}
%end

%hook YTPivotBarView
- (void)setFrame:(CGRect)frame {
    %orig(CGRectSetY(frame, frame.origin.y - 40));
}
%end
%hook YTAppView
- (void)setFrame:(CGRect)frame {
    %orig(CGRectMake(frame.origin.x,frame.origin.y,frame.size.width,frame.size.height + 40));
}
%end

%hook YTNGWatchLayerView
-(CGRect)miniBarFrame{
    CGRect const frame = %orig;
	return CGRectSetY(frame, frame.origin.y - 40);
}
%end
%end 

%group InstagramFix

@interface IGNavigationBar : UINavigationBar
@end

%hook IGNavigationBar

- (void)layoutSubviews {    
    %orig;

    self.frame = CGRectSetY(self.frame, 20);

    /*CGRect _frame = self.frame;
    _frame.origin.y = 20;
    //_frame.size.height = 68; Fixes Instagram bug, but makes layout weird
    self.frame = _frame;*/
}
 
%end
%end

// Preferences.
void loadPrefs() {
     @autoreleasepool {

        NSString const *mainIdentifier = [NSBundle mainBundle].bundleIdentifier;
        NSDictionary const *prefs = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.ryannair05.little11prefs.plist"];

        if (prefs) {
            enabled = [[prefs objectForKey:@"enabled"] boolValue];
            statusBarStyle = [[prefs objectForKey:@"statusBarStyle"] integerValue];
            screenRoundness = [[prefs objectForKey:@"screenRoundness"] integerValue];
            appswitcherRoundness = [[prefs objectForKey:@"appswitcherRoundness"] integerValue];
            wantsbottomInset = [[prefs objectForKey:@"bottomInset"] boolValue];
            wantsHomeBarSB = [[prefs objectForKey:@"homeBarSB"] boolValue];
            wantsHomeBarLS = [[prefs objectForKey:@"homeBarLS"] boolValue];
            wantsKeyboardDock =  [[prefs objectForKey:@"keyboardDock"] boolValue];
            wantsRoundedAppSwitcher =[[prefs objectForKey:@"roundedAppSwitcher"] boolValue];
            wantsReduceRows =  [[prefs objectForKey:@"reduceRows"] boolValue];
            wantsCCGrabber = [[prefs objectForKey:@"ccGrabber"] boolValue];
            wantsBatteryPercent = [[prefs objectForKey:@"batteryPercent"] boolValue];
            wantsGesturesDisabledWhenKeyboard = [[prefs objectForKey:@"noGesturesForKeyboard"] boolValue];
            wantsiPadDock = [[prefs objectForKey:@"iPadDock"] boolValue];
            wantsiPadMultitasking = wantsiPadDock ? [[prefs objectForKey:@"iPadMultitasking"] boolValue] : NO;
            wantsXButtons =  [[prefs objectForKey:@"xButtons"] boolValue];
            wantsRoundedCorners = [[prefs objectForKey:@"roundedCorners"] boolValue];
            wantsPIP = [[prefs objectForKey:@"PIP"] boolValue];
            wantsProudLock = [[prefs objectForKey:@"ProudLock"] boolValue];
            wantsHideSBCC = [[prefs objectForKey:@"HideSBCC"] boolValue];
            wantsLSShortcuts = [[prefs objectForKey:@"lsShortcutsEnabled"] boolValue];
            wants11Camera = [[prefs objectForKey:@"11Camera"] boolValue];
            wantsDeviceSpoofing = [[prefs objectForKey:@"deviceSpoofing"] boolValue];
            wantsCompatabilityMode = [[prefs objectForKey:@"compatabilityMode"] boolValue];

            NSDictionary const *appSettings = [prefs objectForKey:mainIdentifier];
    
            if (appSettings) {
                wantsKeyboardDock = [appSettings objectForKey:@"keyboardDock"] ? [[appSettings objectForKey:@"keyboardDock"] boolValue] : wantsKeyboardDock;
                wantsbottomInset = [appSettings objectForKey:@"bottomInset"] ? [[appSettings objectForKey:@"bottomInset"] boolValue] : wantsbottomInset;
                wantsDeviceSpoofing = [appSettings objectForKey:@"deviceSpoofing"] ? [[appSettings objectForKey:@"deviceSpoofing"] boolValue] : wantsDeviceSpoofing;
                wantsCompatabilityMode = [appSettings objectForKey:@"compatabilityMode"] ? [[appSettings objectForKey:@"compatabilityMode"] boolValue] : wantsCompatabilityMode;
            }
        }
        else {
            NSString *path = @"/User/Library/Preferences/com.ryannair05.little11prefs.plist";
            NSString *pathDefault = @"/Library/PreferenceBundles/little11prefs.bundle/defaults.plist";
            NSFileManager const *fileManager = [NSFileManager defaultManager];

            if (![fileManager fileExistsAtPath:path]) {
                [fileManager copyItemAtPath:pathDefault toPath:path error:nil];
            }

            path = @"/System/Library/PrivateFrameworks/CameraUI.framework/CameraUI-d4x-n104.strings";
            pathDefault = @"/Library/PreferenceBundles/little11prefs.bundle/CameraUI-d4x-n104.strings";

            if (![fileManager fileExistsAtPath:path]) {
                [fileManager copyItemAtPath:pathDefault toPath:path error:nil];
            }

            loadPrefs();
        }
    }
}

%ctor {
    @autoreleasepool {

        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.ryannair05.little11prefs/prefsupdated"), NULL, CFNotificationSuspensionBehaviorCoalesce);
        loadPrefs();

        if (enabled) {

            bool const isSpringBoard = [@"SpringBoard" isEqualToString:[NSProcessInfo processInfo].processName];

            if (isSpringBoard) {

                if (statusBarStyle == 1) %init(StatusBariPad)      
                else if (statusBarStyle == 2) %init(StatusBarX);
                else wantsHideSBCC = YES;

                if (!wantsHomeBarLS) {
                    %init(hideHomeBarLS);
                    if (!wantsHomeBarSB) %init(completelyRemoveHomeBar);
                }

                if (wantsCCGrabber) %init(ccGrabber);
                if (wantsBatteryPercent) %init(batteryPercent);
                if (!wantsXButtons) %init(originalButtons);
                if (wantsHideSBCC) %init(HideSBCC);
                if (wantsRoundedAppSwitcher) %init(roundedDock);
                if (wantsRoundedCorners) %init(roundedCorners);
                if (wantsiPadDock) %init(iPadDock);
                if (wantsiPadMultitasking) %init(iPadMultitasking)
                if (wantsProudLock) %init(ProudLock);
                %init(reduceRows);

            } else {

                NSString* const bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];

                if ([bundleIdentifier containsString:@"com.apple"]) {
                    if (wants11Camera && [bundleIdentifier isEqualToString:@"com.apple.camera"])
                    %init(iPhone11Cam);
                }
                
                else {

                    if ([bundleIdentifier isEqualToString:@"com.google.ios.youtube"])
                        wantsCompatabilityMode = YES;
                    else if ([bundleIdentifier isEqualToString:@"com.facebook.Facebook"]) 
                        wantsbottomInset = YES;
                    else if ([bundleIdentifier isEqualToString:@"com.zhiliaoapp.musically"])
                        wantsDeviceSpoofing = YES;

                    if (wantsbottomInset || statusBarStyle == 2) {

                        %init(InstagramFix);

                        if (wantsCompatabilityMode) %init(CompatabilityMode);
                        if (wantsDeviceSpoofing) %init(BoundsHack);
                        if (wantsbottomInset) %init(CameraFix); 
                        else %init(bottominsetfix);
                    } 
                }
            }

            if (![[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/KeyboardPlus.dylib"]) {

                if (wantsKeyboardDock) %init(KeyboardDock);
                else %init(ForceDefaultKeyboard);

                if (wantsGesturesDisabledWhenKeyboard) {
                    [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardDidShowNotification object:nil queue:nil usingBlock:^(NSNotification *n){
                            disableGestures = true;
                        }];
                    [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillHideNotification object:nil queue:nil usingBlock:^(NSNotification *n){
                            disableGestures = false;
                        }];
                    if (@available(iOS 13.4, *)) 
                        %init(newDisableGesturesWhenKeyboard);
                    else
                        %init(disableGesturesWhenKeyboard);
                }
            }
            %init;
        }
    }
}
