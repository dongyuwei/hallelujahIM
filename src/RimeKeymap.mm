#import "RimeKeymap.h"

@implementation RimeKeymap

+ (int)rimeMaskForModifiers:(NSUInteger)modifierFlags {
    int mask = 0;
    if (modifierFlags & NSEventModifierFlagShift) {
        mask |= RimeShiftMask;
    }
    if (modifierFlags & NSEventModifierFlagCapsLock) {
        mask |= RimeLockMask;
    }
    if (modifierFlags & NSEventModifierFlagControl) {
        mask |= RimeControlMask;
    }
    if (modifierFlags & NSEventModifierFlagOption) {
        mask |= RimeAltMask;
    }
    if (modifierFlags & NSEventModifierFlagCommand) {
        mask |= RimeSuperMask;
    }
    return mask;
}

+ (int)rimeKeycodeForKeyCode:(unsigned short)keyCode character:(NSString *)character modifierFlags:(NSUInteger)modifierFlags {
    switch (keyCode) {
    case kVK_Space:
        return RimeXK_space;
    case kVK_Return:
        return RimeXK_Return;
    case kVK_Tab:
        return RimeXK_Tab;
    case kVK_Escape:
        return RimeXK_Escape;
    case kVK_Delete:
        return RimeXK_BackSpace;
    case kVK_ForwardDelete:
        return RimeXK_Delete;
    case kVK_Home:
        return RimeXK_Home;
    case kVK_End:
        return RimeXK_End;
    case kVK_LeftArrow:
        return RimeXK_Left;
    case kVK_RightArrow:
        return RimeXK_Right;
    case kVK_DownArrow:
        return RimeXK_Down;
    case kVK_UpArrow:
        return RimeXK_Up;
    case kVK_PageUp:
        return RimeXK_Page_Up;
    case kVK_PageDown:
        return RimeXK_Page_Down;
    default:
        break;
    }

    // Printable keys: use the typed character so shifted punctuation
    // (e.g. ? : ") arrives as the right keysym for luna_pinyin.
    if (character.length == 1) {
        unichar ch = [character characterAtIndex:0];
        if (ch >= 0x20 && ch <= 0x7e) {
            // For letters, lowercase/uppercase follows shift^caps like X11 expects.
            if (ch >= 'a' && ch <= 'z') {
                BOOL shiftHeld = (modifierFlags & NSEventModifierFlagShift) != 0;
                BOOL capsLockOn = (modifierFlags & NSEventModifierFlagCapsLock) != 0;
                if (shiftHeld != capsLockOn) {
                    ch = ch - 'a' + 'A';
                }
                return RimeXK_a + (ch - 'a');
            }
            return ch;
        }
    }
    return RimeXK_VoidSymbol;
}

@end
