#import <AppKit/AppKit.h>
#import <InputMethodKit/InputMethodKit.h>

#import "CandidatePanelState.h"

@class CandidatePanel;

@protocol CandidatePanelDelegate <NSObject>
- (void)candidatePanel:(CandidatePanel *)panel clickedIndex:(NSInteger)index;
@end

// Custom candidate panel replacing IMKCandidates: one borderless NSPanel that
// renders either the default vertical list or a 5-column grid. The input
// method keeps driving navigation through the panel methods; the panel owns
// the visible window (scrolling) and the geometry.
@interface CandidatePanel : NSObject

@property(nonatomic, weak) id<CandidatePanelDelegate> delegate;

@property(nonatomic, readonly) BOOL isVisible;
@property(nonatomic, readonly) NSInteger selectedIndex;
@property(nonatomic, readonly) NSRect candidateFrame;

- (void)updateCandidates:(NSArray<NSString *> *)candidates;
- (void)showAtClient:(id<IMKTextInput>)client;
- (void)hide;
- (void)setGridLayout:(BOOL)useGrid;

// Vertical list navigation.
- (void)moveSelectionDown;
- (void)moveSelectionUp;

// Grid navigation.
- (void)gridMoveDown;
- (void)gridMoveUp;
- (void)gridMoveRight;
- (void)gridMoveLeft;

@end
