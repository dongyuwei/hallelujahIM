#import "CandidatePanel.h"

static const CGFloat kRowHeight = 26;
static const CGFloat kPadding = 8;
static const CGFloat kCellPadding = 12;
static const CGFloat kCornerRadius = 10;
static const CGFloat kSelectionGap = 4;
static const CGFloat kMinPanelWidth = 120;
static const CGFloat kFallbackLineHeight = 20;

// Renders the candidates described by CandidatePanelState. Single drawRect
// pass: vertical rows or grid cells, with a pill behind the active candidate.
@interface CandidatePanelContent : NSView

@property(nonatomic, strong) CandidatePanelState *state;
@property(nonatomic, copy) void (^clickHandler)(NSInteger index);

@end

@implementation CandidatePanelContent

- (BOOL)isFlipped {
    return YES; // top-left origin makes row math straightforward
}

- (void)animateHighlightCandidate {
    // no animation; redraw is enough
}

- (void)drawRect:(NSRect)dirtyRect {
    CandidatePanelState *state = self.state;
    if (state.candidates.count == 0) {
        return;
    }

    NSRect bounds = self.bounds;
    NSBezierPath *bg = [NSBezierPath bezierPathWithRoundedRect:bounds xRadius:kCornerRadius yRadius:kCornerRadius];
    [NSColor.windowBackgroundColor setFill];
    [bg fill];
    [[NSColor.separatorColor colorWithAlphaComponent:0.5] setStroke];
    [bg stroke];

    BOOL grid = state.layout == CandidatePanelLayoutGrid;
    NSInteger rowCount = grid ? state.gridRenderedRowCount : MIN((NSInteger)state.candidates.count, state.verticalVisibleRows);
    NSInteger rowOffset = grid ? state.gridVisibleRowOffset : state.verticalTopVisibleLine;

    NSInteger columns = grid ? state.gridColumns : 1;
    CGFloat cellWidth = grid ? bounds.size.width / columns : bounds.size.width;

    for (NSInteger row = 0; row < rowCount; row++) {
        for (NSInteger col = 0; col < columns; col++) {
            NSInteger index;
            if (grid) {
                index = (rowOffset + row) * columns + col;
            } else {
                index = rowOffset + row;
            }
            if (index >= (NSInteger)state.candidates.count) {
                continue;
            }
            NSRect cellRect = NSMakeRect(col * cellWidth, row * kRowHeight, cellWidth, kRowHeight);
            BOOL active = index == state.selectedIndex;
            [self drawCellWithText:state.candidates[index] numberKey:grid ? col + 1 : row + 1 active:active inRect:cellRect];
        }
    }
}

- (void)drawCellWithText:(NSString *)text numberKey:(NSInteger)numberKey active:(BOOL)active inRect:(NSRect)cellRect {
    NSDictionary *wordAttrs = @{
        NSFontAttributeName : [NSFont systemFontOfSize:14 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName : active ? NSColor.alternateSelectedControlTextColor : NSColor.labelColor,
    };
    NSDictionary *numberAttrs = @{
        NSFontAttributeName : [NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName : active ? NSColor.alternateSelectedControlTextColor
                                                : [NSColor.secondaryLabelColor colorWithAlphaComponent:0.8],
    };

    NSRect pillRect = NSInsetRect(cellRect, kPadding, kSelectionGap);
    if (active) {
        NSBezierPath *pill = [NSBezierPath bezierPathWithRoundedRect:pillRect xRadius:kCornerRadius - 2 yRadius:kCornerRadius - 2];
        [NSColor.controlAccentColor setFill];
        [pill fill];
    }

    NSString *number = [NSString stringWithFormat:@"%ld ", (long)numberKey];
    CGSize numberSize = [number sizeWithAttributes:numberAttrs];
    NSRect textRect = NSInsetRect(pillRect, kCellPadding, 0);
    CGFloat wordHeight = [wordAttrs[NSFontAttributeName] pointSize];
    [number drawInRect:NSMakeRect(textRect.origin.x, textRect.origin.y + (kRowHeight - numberSize.height) / 2, numberSize.width,
                                  numberSize.height)
        withAttributes:numberAttrs];
    [text drawInRect:NSMakeRect(textRect.origin.x + numberSize.width, textRect.origin.y + (kRowHeight - wordHeight) * 0.75,
                                MAX(0, textRect.size.width - numberSize.width), textRect.size.height)
        withAttributes:wordAttrs];
}

- (void)mouseDown:(NSEvent *)event {
    CandidatePanelState *state = self.state;
    if (state.candidates.count == 0) {
        return;
    }
    NSPoint p = [self convertPoint:event.locationInWindow fromView:nil];
    BOOL grid = state.layout == CandidatePanelLayoutGrid;
    NSInteger columns = grid ? state.gridColumns : 1;
    NSInteger row = MIN((NSInteger)(p.y / kRowHeight), (grid ? state.gridRenderedRowCount : state.verticalVisibleRows) - 1);
    NSInteger col = MAX(0, MIN((NSInteger)(p.x / (self.bounds.size.width / columns)), columns - 1));
    NSInteger index = row * columns + col;
    if (grid) {
        index += state.gridVisibleRowOffset * columns;
    } else {
        index += state.verticalTopVisibleLine;
    }
    if (index >= 0 && index < (NSInteger)state.candidates.count && self.clickHandler) {
        self.clickHandler(index);
    }
}

@end

@interface CandidatePanel ()

@property(nonatomic, strong) NSPanel *panel;
@property(nonatomic, strong) CandidatePanelContent *content;
@property(nonatomic, strong) CandidatePanelState *state;
@property(nonatomic) NSRect lastCursorRect;

@end

@implementation CandidatePanel

- (instancetype)init {
    self = [super init];
    if (self) {
        _panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 300, 30)
                                            styleMask:(NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel)
                                              backing:NSBackingStoreBuffered
                                                defer:YES];
        _panel.level = NSPopUpMenuWindowLevel;
        _panel.hasShadow = NO;
        _panel.opaque = NO;
        _panel.backgroundColor = NSColor.clearColor;
        _panel.hidesOnDeactivate = NO;
        _panel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary;

        _content = [[CandidatePanelContent alloc] initWithFrame:_panel.contentView.bounds];
        _content.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [_panel.contentView addSubview:_content];
        __weak typeof(self) weakSelf = self;
        _content.clickHandler = ^(NSInteger index) {
            [weakSelf.delegate candidatePanel:weakSelf clickedIndex:index];
        };
    }
    return self;
}

- (BOOL)isVisible {
    return self.panel.isVisible;
}

- (NSRect)candidateFrame {
    return self.panel.frame;
}

- (NSInteger)selectedIndex {
    return self.state.selectedIndex;
}

- (void)updateCandidates:(NSArray<NSString *> *)candidates {
    BOOL grid = self.state.layout == CandidatePanelLayoutGrid;
    self.state = [[CandidatePanelState alloc] initWithCandidates:candidates
                                                          layout:grid ? CandidatePanelLayoutGrid : CandidatePanelLayoutVertical];
    self.content.state = self.state;
    [self resizeToFit];
    [self reposition];
}

- (void)setGridLayout:(BOOL)useGrid {
    CandidatePanelLayout layout = useGrid ? CandidatePanelLayoutGrid : CandidatePanelLayoutVertical;
    NSArray *candidates = self.state.candidates;
    self.state = [[CandidatePanelState alloc] initWithCandidates:candidates layout:layout];
    self.content.state = self.state;
    [self.content setNeedsDisplay:YES];
    [self resizeToFit];
    [self reposition];
}

- (void)showAtClient:(id<IMKTextInput>)client {
    if (self.state.candidates.count == 0) {
        [self hide];
        return;
    }
    self.lastCursorRect = [self resolveCursorRectFromClient:client];
    [self.content setNeedsDisplay:YES];
    [self resizeToFit];
    [self reposition];
    [self.panel orderFront:nil];
}

- (void)hide {
    [self.panel orderOut:nil];
}

#pragma mark - Navigation (vertical)

- (void)moveSelectionDown {
    [self.state moveDown];
    [self contentDidChangeWithReframe:YES];
}

- (void)moveSelectionUp {
    [self.state moveUp];
    [self contentDidChangeWithReframe:YES];
}

#pragma mark - Navigation (grid)

- (void)gridMoveDown {
    [self.state gridMoveDown];
    [self contentDidChangeWithReframe:YES];
}

- (void)gridMoveUp {
    [self.state gridMoveUp];
    [self contentDidChangeWithReframe:YES];
}

- (void)gridMoveRight {
    [self.state gridMoveRight];
    [self contentDidChangeWithReframe:NO];
}

- (void)gridMoveLeft {
    [self.state gridMoveLeft];
    [self contentDidChangeWithReframe:NO];
}

#pragma mark - Private

- (void)contentDidChangeWithReframe:(BOOL)reframe {
    [self.content setNeedsDisplay:YES];
    if (reframe) {
        [self resizeToFit];
        [self reposition];
    }
}

- (NSRect)resolveCursorRectFromClient:(id<IMKTextInput>)client {
    NSRect rect = NSZeroRect;
    if (client != nil) {
        [client attributesForCharacterIndex:0 lineHeightRectangle:&rect];
        if (!NSEqualRects(rect, NSZeroRect)) {
            return rect;
        }
    }
    NSPoint mouse = NSEvent.mouseLocation;
    return NSMakeRect(mouse.x, mouse.y - kFallbackLineHeight, 0, kFallbackLineHeight);
}

- (NSSize)preferredSize {
    CandidatePanelState *state = self.state;
    if (state.candidates.count == 0) {
        return NSZeroSize;
    }
    BOOL grid = state.layout == CandidatePanelLayoutGrid;
    NSFont *font = [NSFont systemFontOfSize:14 weight:NSFontWeightMedium];
    NSDictionary *attrs = @{NSFontAttributeName : font};

    if (grid) {
        NSInteger rows = state.gridRenderedRowCount;
        CGFloat cellWidth = 0;
        for (NSInteger row = 0; row < rows; row++) {
            for (NSInteger col = 0; col < state.gridColumns; col++) {
                NSInteger index = (state.gridVisibleRowOffset + row) * state.gridColumns + col;
                if (index >= (NSInteger)state.candidates.count) {
                    continue;
                }
                CGFloat w = [state.candidates[index] sizeWithAttributes:attrs].width;
                cellWidth = MAX(cellWidth, w);
            }
        }
        cellWidth += kCellPadding * 2 + 20; // number key + paddings
        return NSMakeSize(MAX(kMinPanelWidth, cellWidth * state.gridColumns), rows * kRowHeight + kPadding * 2);
    }

    CGFloat width = 0;
    NSInteger count = MIN((NSInteger)state.candidates.count, state.verticalVisibleRows);
    for (NSInteger i = 0; i < count; i++) {
        NSInteger index = state.verticalTopVisibleLine + i;
        if (index >= (NSInteger)state.candidates.count) {
            break;
        }
        CGFloat w = [state.candidates[index] sizeWithAttributes:attrs].width;
        width = MAX(width, w);
    }
    width += kCellPadding * 2 + 20;
    return NSMakeSize(MAX(kMinPanelWidth, width), count * kRowHeight + kPadding * 2);
}

- (void)resizeToFit {
    NSSize size = [self preferredSize];
    if (NSEqualSizes(size, NSZeroSize)) {
        return;
    }
    NSRect frame = self.panel.frame;
    frame.size = size;
    [self.panel setFrame:frame display:YES];
}

- (void)reposition {
    NSSize size = self.panel.frame.size;
    if (NSEqualSizes(size, NSZeroSize)) {
        return;
    }
    NSRect cursor = self.lastCursorRect;
    NSPoint origin = NSMakePoint(cursor.origin.x, cursor.origin.y - size.height - kSelectionGap);
    if (NSScreen.mainScreen != nil) {
        NSRect visible = NSScreen.mainScreen.visibleFrame;
        origin.x = MIN(MAX(origin.x, visible.origin.x), visible.origin.x + visible.size.width - size.width);
        if (origin.y < visible.origin.y) {
            origin.y = cursor.origin.y + cursor.size.height + kSelectionGap;
        }
    }
    [self.panel setFrameOrigin:origin];
}

@end
