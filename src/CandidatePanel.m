#import "CandidatePanel.h"

// SwiftType-style palette and metrics (cloned from its Theme):
// background #1B1B1B, border #1B1B1B (2pt), corner radius 6,
// text #FCFCFC, number #A0796A, highlight text #FF9900, highlight #533566.
static const CGFloat kRowHeight = 24;
static const CGFloat kPadding = 3;
static const CGFloat kCellPadding = 3;
static const CGFloat kCornerRadius = 6;
static const CGFloat kSelectionGap = 3;
static const CGFloat kMinPanelWidth = 120;
static const CGFloat kMaxCellWidth = 150; // a single cell never grows wider than this
static const CGFloat kFallbackLineHeight = 20;

static NSColor *PanelColor(int r, int g, int b, CGFloat alpha) {
    return [NSColor colorWithCalibratedRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:alpha];
}

// Cell insets used by drawing (kPadding + kCellPadding on each side).
static const CGFloat kCellInset = (kPadding + kCellPadding) * 2;

// Renders the candidates described by CandidatePanelState. Single drawRect
// pass: vertical rows or grid cells, with a pill behind the active candidate.
@interface CandidatePanelContent : NSView

@property(nonatomic, strong) CandidatePanelState *state;
@property(nonatomic, copy) void (^clickHandler)(NSInteger index);

- (NSAttributedString *)cellText:(NSString *)text number:(NSInteger)number active:(BOOL)active;
- (NSArray<NSNumber *> *)gridColumnWidths;

@end

@implementation CandidatePanelContent

- (BOOL)isFlipped {
    return YES; // top-left origin makes row math straightforward
}

- (void)drawRect:(NSRect)dirtyRect {
    CandidatePanelState *state = self.state;
    if (state.candidates.count == 0) {
        return;
    }

    NSRect bounds = self.bounds;
    NSBezierPath *bg = [NSBezierPath bezierPathWithRoundedRect:bounds xRadius:kCornerRadius yRadius:kCornerRadius];
    [PanelColor(0x1B, 0x1B, 0x1B, 1) setFill];
    [bg fill];
    [[PanelColor(0x1B, 0x1B, 0x1B, 1) colorWithAlphaComponent:0.85] setStroke];
    [bg stroke];

    BOOL grid = state.layout == CandidatePanelLayoutGrid;
    NSInteger rowCount = grid ? state.gridRenderedRowCount : MIN((NSInteger)state.candidates.count, state.verticalVisibleRows);
    NSInteger rowOffset = grid ? state.gridVisibleRowOffset : state.verticalTopVisibleLine;

    NSInteger columns = grid ? state.gridColumns : 1;
    NSArray<NSNumber *> *columnWidths = grid ? [self gridColumnWidths] : nil;

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
            CGFloat x = 0;
            for (NSInteger c = 0; c < col; c++) {
                x += columnWidths[c].doubleValue;
            }
            NSRect cellRect = NSMakeRect(x, row * kRowHeight, columnWidths[col].doubleValue, kRowHeight);
            BOOL active = index == state.selectedIndex;
            // Selection keys apply to the active grid row only: digits pick
            // the column of the highlighted row, so numerate that row.
            NSInteger number = 0;
            if (grid) {
                number = ((rowOffset + row) == state.gridActiveRow) ? col + 1 : 0;
            } else {
                number = row + 1;
            }
            [self drawCellWithAttributedText:[self cellText:state.candidates[index] number:number active:active]
                                      active:active
                                      inRect:cellRect];
        }
    }
}

// Each grid column is sized to its widest candidate (with the number gutter),
// so short-word columns stay snug instead of inheriting the widest word.
- (NSArray<NSNumber *> *)gridColumnWidths {
    CandidatePanelState *state = self.state;
    NSInteger columns = state.gridColumns;
    CGFloat widths[8] = {0};
    for (NSInteger index = 0; index < (NSInteger)state.candidates.count; index++) {
        NSInteger col = index % columns;
        NSInteger number = col + 1; // worst case: gutter present
        NSAttributedString *cell = [self cellText:state.candidates[index] number:number active:NO];
        widths[col] = MAX(widths[col], cell.size.width + kCellInset);
    }
    NSMutableArray<NSNumber *> *result = [NSMutableArray arrayWithCapacity:columns];
    for (NSInteger col = 0; col < columns; col++) {
        [result addObject:@(MIN(widths[col], kMaxCellWidth))];
    }
    return result;
}

// Single attributed string per cell: number (mono, muted) + word. Measuring
// and drawing the same string guarantees the pill and width always fit.
// Colors cloned from SwiftType's default theme: word #FCFCFC (highlight
// #FF9900), number #A0796A.
- (NSAttributedString *)cellText:(NSString *)text number:(NSInteger)number active:(BOOL)active {
    NSDictionary *wordAttrs = @{
        NSFontAttributeName : [NSFont systemFontOfSize:14 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName : active ? PanelColor(0xFF, 0x99, 0x00, 1) : PanelColor(0xFC, 0xFC, 0xFC, 1),
    };
    NSDictionary *numberAttrs = @{
        NSFontAttributeName : [NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName : PanelColor(0xA0, 0x79, 0x6A, 1),
    };
    NSMutableAttributedString *cell = [[NSMutableAttributedString alloc] init];
    if (number > 0 && number <= 9) {
        [cell appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", (long)number]
                                                                     attributes:numberAttrs]];
        [cell appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:numberAttrs]];
    }
    [cell appendAttributedString:[[NSAttributedString alloc] initWithString:text attributes:wordAttrs]];
    return cell;
}

- (void)drawCellWithAttributedText:(NSAttributedString *)cellText active:(BOOL)active inRect:(NSRect)cellRect {
    NSSize textSize = [cellText size];
    // Left-aligned cell content; the pill hugs the text (plus padding), never
    // the whole column, so a short highlighted word doesn't sit in an
    // oversized box.
    CGFloat pillWidth = MIN(textSize.width + kCellPadding * 2, cellRect.size.width - kPadding * 2);
    NSRect pillRect =
        NSMakeRect(cellRect.origin.x + kPadding, cellRect.origin.y + kSelectionGap, pillWidth, cellRect.size.height - kSelectionGap * 2);
    if (active) {
        NSBezierPath *pill = [NSBezierPath bezierPathWithRoundedRect:pillRect xRadius:kCornerRadius - 2 yRadius:kCornerRadius - 2];
        [PanelColor(0x53, 0x35, 0x66, 0.9) setFill];
        [pill fill];
    }

    NSRect textRect = NSMakeRect(pillRect.origin.x + kCellPadding, pillRect.origin.y + MAX(0, (pillRect.size.height - textSize.height) / 2),
                                 MAX(0, MIN(textSize.width, pillRect.size.width - kCellPadding * 2)), textSize.height);
    [cellText drawWithRect:textRect options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine context:nil];
}

- (void)mouseDown:(NSEvent *)event {
    CandidatePanelState *state = self.state;
    if (state.candidates.count == 0) {
        return;
    }
    NSPoint p = [self convertPoint:event.locationInWindow fromView:nil];
    BOOL grid = state.layout == CandidatePanelLayoutGrid;
    NSInteger columns = grid ? state.gridColumns : 1;
    NSArray<NSNumber *> *columnWidths = grid ? [self gridColumnWidths] : nil;

    NSInteger row = MIN((NSInteger)(p.y / kRowHeight), (grid ? state.gridRenderedRowCount : state.verticalVisibleRows) - 1);
    NSInteger col = 0;
    if (grid) {
        CGFloat x = 0;
        for (NSInteger c = 0; c < columns; c++) {
            x += columnWidths[c].doubleValue;
            if (p.x < x) {
                col = c;
                break;
            }
            col = c;
        }
    }
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

- (NSInteger)indexForDigit:(NSInteger)digit {
    return [self.state indexForDigit:digit];
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
    if (grid) {
        NSArray<NSNumber *> *widths = [self.content gridColumnWidths];
        CGFloat panelWidth = 0;
        for (NSNumber *w in widths) {
            panelWidth += w.doubleValue;
        }
        return NSMakeSize(MAX(kMinPanelWidth, panelWidth), state.gridRenderedRowCount * kRowHeight + kPadding * 2);
    }

    CGFloat width = 0;
    NSInteger count = MIN((NSInteger)state.candidates.count, state.verticalVisibleRows);
    for (NSInteger row = 0; row < count; row++) {
        NSInteger index = state.verticalTopVisibleLine + row;
        if (index >= (NSInteger)state.candidates.count) {
            break;
        }
        NSAttributedString *cell = [self.content cellText:state.candidates[index] number:row + 1 active:NO];
        width = MAX(width, cell.size.width);
    }
    width += kPadding * 2 + kCellPadding * 2;
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
    // keep the content view in lockstep with the panel in case a resize
    // happened while the content was not yet in the window
    [self.content setFrame:self.panel.contentView.bounds];
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
