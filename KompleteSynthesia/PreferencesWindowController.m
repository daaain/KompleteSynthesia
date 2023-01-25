//
//  PreferencesWindowController.m
//  KompleteSynthesia
//
//  Created by Till Toenshoff on 20.01.23.
//

#import "PreferencesWindowController.h"
#import "SynthesiaController.h"
#import "MIDI2HIDController.h"

@interface PreferencesWindowController ()
@end

@implementation PreferencesWindowController {
    NSArray<ColorField*>* controls;
    NSArray<NSString*>* names;

    PaletteViewController* paletteViewController;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    controls = @[ _colorUnpressed,
                  _colorPressed,
                  _colorLeft,
                  _colorLeftThumb,
                  _colorLeftPressed,
                  _colorRight,
                  _colorRightThumb,
                  _colorRightPressed ];

    names = @[ @"kColorMapUnpressed",
               @"kColorMapPressed",
               @"kColorMapLeft",
               @"kColorMapLeftThumb",
               @"kColorMapLeftPressed",
               @"kColorMapRight",
               @"kColorMapRightThumb",
               @"kColorMapRightPressed" ];
    
    for (int key = 0;key < controls.count;key++) {
        ColorField* colorField = controls[key];
        colorField.keyState = _midi2hid.colors[key];
        colorField.rounded = YES;
    }

    [self.forwardButtonsOnlyToSynthesia setState:_midi2hid.forwardButtonsToSynthesiaOnly ? NSControlStateValueOn : NSControlStateValueOff];
}

- (IBAction)selectKeyState:(id)sender
{
    if (sender == nil || ![controls containsObject:sender]) {
        return;
    }
    ColorField* colorField = sender;
    
    NSPopover* popOver = [NSPopover new];

    if (paletteViewController == nil) {
        paletteViewController = [[PaletteViewController alloc] initWithNibName:@"PaletteViewController" bundle:NULL];
        paletteViewController.delegate = self;
    }
    paletteViewController.keyState = colorField.keyState;

    NSInteger key = [controls indexOfObject:colorField];
    assert(key != NSNotFound);
    assert(key < kColorMapSize);
    paletteViewController.index = key;
    popOver.contentViewController = paletteViewController;
    popOver.contentSize = paletteViewController.view.bounds.size;
    popOver.animates = YES;
    popOver.behavior = NSPopoverBehaviorTransient;
    [popOver showRelativeToRect:colorField.frame ofView:[self.window contentView] preferredEdge:NSMaxXEdge];
}

- (void)keyStatePicked:(const unsigned char)keyState index:(const unsigned char)index
{
    NSLog(@"picked key state %02Xh for map index %d", keyState, index);

    assert(index < kColorMapSize);
    _midi2hid.colors[index] = keyState;
    if (index == 0) {
        [_midi2hid lightsDefault];
    }

    assert(controls.count > index);
    ColorField* colorField = controls[index];
    colorField.keyState = keyState;
    [colorField setNeedsDisplay:YES];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:keyState forKey:names[index]];
}

- (IBAction)fowardingValueChanged:(id)sender
{
    _midi2hid.forwardButtonsToSynthesiaOnly = self.forwardButtonsOnlyToSynthesia.state == NSControlStateValueOn;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:_midi2hid.forwardButtonsToSynthesiaOnly forKey:@"forward_buttons_to_synthesia_only"];
}

- (IBAction)assertSynthesiaConfig:(id)sender
{
    NSError* error = nil;
    if ([_synthesia assertMultiDeviceConfig:&error] == NO) {
        NSLog(@"failed to assert Synthesia key light loopback setup");
        [[NSAlert alertWithError:error] runModal];
    }
}

@end
