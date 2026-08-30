#import <AppKit/AppKit.h>
#import <Carbon/Carbon.h>
#import <Foundation/Foundation.h>

// Minimal macOS keycode -> Rime keycode (X11 keysym) translation.
// Keycode and modifier-mask constants follow librime's rime/key_table.h.
// Rime modifier masks
static const int RimeShiftMask = 1 << 0;
static const int RimeLockMask = 1 << 1;
static const int RimeControlMask = 1 << 2;
static const int RimeAltMask = 1 << 3;
static const int RimeSuperMask = 1 << 26;
static const int RimeReleaseMask = 1 << 30;

// X11 keysyms used by luna_pinyin (letters, digits, punctuation, navigation)
static const int RimeXK_space = 0x0020;
static const int RimeXK_apostrophe = 0x0027;
static const int RimeXK_comma = 0x002c;
static const int RimeXK_minus = 0x002d;
static const int RimeXK_period = 0x002e;
static const int RimeXK_slash = 0x002f;
static const int RimeXK_semicolon = 0x03b;
static const int RimeXK_colon = 0x03a;
static const int RimeXK_equal = 0x03d;
static const int RimeXK_a = 0x061;
static const int RimeXK_z = 0x07a;
static const int RimeXK_grave = 0x060;
static const int RimeXK_bracketleft = 0x05b;
static const int RimeXK_backslash = 0x05c;
static const int RimeXK_bracketright = 0x05d;
static const int RimeXK_BackSpace = 0xff08;
static const int RimeXK_Tab = 0xff09;
static const int RimeXK_Return = 0xff0d;
static const int RimeXK_Escape = 0xff1b;
static const int RimeXK_Home = 0xff50;
static const int RimeXK_Left = 0xff51;
static const int RimeXK_Up = 0xff52;
static const int RimeXK_Right = 0xff53;
static const int RimeXK_Down = 0xff54;
static const int RimeXK_Page_Up = 0xff55;
static const int RimeXK_Page_Down = 0xff56;
static const int RimeXK_End = 0xff57;
static const int RimeXK_Delete = 0xffff;
static const int RimeXK_VoidSymbol = 0xffffff;

@interface RimeKeymap : NSObject

// Translates NSEvent modifier flags into a Rime modifier mask.
+ (int)rimeMaskForModifiers:(NSUInteger)modifierFlags;

// Translates an NSEvent keyDown into a Rime keycode.
// Returns RimeXK_VoidSymbol when the event cannot be represented.
+ (int)rimeKeycodeForKeyCode:(unsigned short)keyCode character:(NSString *)character modifierFlags:(NSUInteger)modifierFlags;

@end
