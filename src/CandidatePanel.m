#import "CandidatePanel.h"

// SwiftType-style palette and metrics (cloned from its Theme):
// background #1B1B1B, border #1B1B1B (2pt), corner radius 6,
// text #FCFCFC, number #A0796A, highlight text #FF9900, highlight #533566.
static const CGFloat kRowHeight = 24;
static const CGFloat kPadding = 3;
static const CGFloat kCellPadding = 3;
static const CGFloat kCornerRadius = 6;
static const CGFloat kSelectionGap = 3;
static const CGFloat kMinPanelWidth = 44;
static const CGFloat kMaxCellWidth = 150; // a single cell never grows wider than this
static const CGFloat kFallbackLineHeight = 20;
static const CGFloat kFooterGap = 5;              // space above the translation footer
static const CGFloat kDetailGap = 3;              // vertical: gap between candidate and detail columns
static const CGFloat kMaxDetailColumnWidth = 240; // vertical: widest the detail column grows before wrapping

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

// Translation/IPA summary for the highlighted candidate, drawn as a single
// bottom row. Empty string renders no footer (panel collapses back).
@property(nonatomic, copy) NSString *annotation;

- (NSAttributedString *)cellText:(NSString *)text number:(NSInteger)number active:(BOOL)active;
- (NSArray<NSNumber *> *)gridColumnWidths;
- (CGFloat)footerHeight;
- (NSString *)annotationText;

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

    if (state.layout == CandidatePanelLayoutGrid) {
        [self drawGridCellsForState:state];
        [self drawFooterInRect:[self footerRect]];
        return;
    }

    [self drawVerticalCellsForState:state];
    if (self.annotation.length > 0) {
        [self drawVerticalDetailInRect:[self verticalDetailRect]];
    }
}

// Grid: 5 columns per row, cells sized per column. Rendering/footer both
// live on the panel's dark background.
- (void)drawGridCellsForState:(CandidatePanelState *)state {
    NSInteger rowCount = state.gridRenderedRowCount;
    NSInteger rowOffset = state.gridVisibleRowOffset;
    NSInteger columns = state.gridColumns;
    NSArray<NSNumber *> *columnWidths = [self gridColumnWidths];

    for (NSInteger row = 0; row < rowCount; row++) {
        for (NSInteger col = 0; col < columns; col++) {
            NSInteger index = (rowOffset + row) * columns + col;
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
            NSInteger number = ((rowOffset + row) == state.gridActiveRow) ? col + 1 : 0;
            [self drawCellWithAttributedText:[self cellText:state.candidates[index] number:number active:active]
                                      active:active
                                      inRect:cellRect];
        }
    }
}

// Vertical: 2 equal columns when the highlight has an annotation — candidates
// on the left, ipa + translation wrapping on the right. Single column when
// there's no annotation (panel collapses back to the list).
- (void)drawVerticalCellsForState:(CandidatePanelState *)state {
    NSInteger rowCount = MIN((NSInteger)state.candidates.count, state.verticalVisibleRows);
    NSInteger rowOffset = state.verticalTopVisibleLine;
    for (NSInteger row = 0; row < rowCount; row++) {
        NSInteger index = rowOffset + row;
        if (index >= (NSInteger)state.candidates.count) {
            break;
        }
        BOOL active = index == state.selectedIndex;
        NSRect cellRect = NSMakeRect(0, kPadding + row * kRowHeight, [self verticalCandidateColumnWidth], kRowHeight);
        [self drawCellWithAttributedText:[self cellText:state.candidates[index] number:row + 1 active:active]
                                  active:active
                                  inRect:cellRect];
    }
}

// Left column: widest candidate cell. Independent of the annotation.
- (CGFloat)verticalCandidateColumnWidth {
    CandidatePanelState *state = self.state;
    NSInteger count = MIN((NSInteger)state.candidates.count, state.verticalVisibleRows);
    CGFloat widest = 0;
    for (NSInteger row = 0; row < count; row++) {
        NSInteger index = state.verticalTopVisibleLine + row;
        if (index >= (NSInteger)state.candidates.count) {
            break;
        }
        NSAttributedString *cell = [self cellText:state.candidates[index] number:row + 1 active:NO];
        widest = MAX(widest, cell.size.width);
    }
    return widest + kCellInset;
}

// Right column: hugs the annotation's longest line so the gloss doesn't
// leave a big empty gutter, but never exceeds kMaxDetailColumnWidth (a
// single overlong translation then wraps instead of ballooning). 0 when the
// annotation is hidden.
- (CGFloat)verticalDetailColumnWidth {
    if (self.annotation.length == 0) {
        return 0;
    }
    NSDictionary *attrs = @{
        NSFontAttributeName : [NSFont systemFontOfSize:12 weight:NSFontWeightRegular],
        NSForegroundColorAttributeName : PanelColor(0xB8, 0xC4, 0xCD, 1),
    };
    CGFloat widest = 0;
    NSArray *lines = [self.annotation componentsSeparatedByString:@"\n"];
    for (NSString *line in lines) {
        CGFloat w = [line sizeWithAttributes:attrs].width;
        widest = MAX(widest, w);
    }
    return MIN(widest + kCellInset, kMaxDetailColumnWidth);
}

- (NSRect)verticalDetailRect {
    CGFloat width = [self verticalDetailColumnWidth];
    CGFloat x = [self verticalCandidateColumnWidth] + kDetailGap;
    CGFloat height = self.bounds.size.height - kPadding * 2;
    return NSMakeRect(x, kPadding, width, height);
}

// The annotation for the highlight, multi-line (ipa first, gloss lines below)
// wrapped inside the right column. Reads lighter than the candidate text.
- (void)drawVerticalDetailInRect:(NSRect)detailRect {
    NSString *text = self.annotation;
    if (text.length == 0 || NSEqualRects(detailRect, NSZeroRect)) {
        return;
    }
    NSDictionary *attrs = @{
        NSFontAttributeName : [NSFont systemFontOfSize:12 weight:NSFontWeightRegular],
        NSForegroundColorAttributeName : PanelColor(0xB8, 0xC4, 0xCD, 1),
    };
    NSRect box = detailRect;
    box.origin.x += kCellPadding;
    box.origin.y += kSelectionGap;
    box.size.width -= kCellPadding * 2;
    box.size.height -= kSelectionGap * 2;
    [text drawWithRect:box options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil];
}

// Height the annotation needs once wrapped into its column, 0 when hidden.
- (CGFloat)verticalDetailHeightCost {
    if (self.annotation.length == 0) {
        return 0;
    }
    NSDictionary *attrs = @{
        NSFontAttributeName : [NSFont systemFontOfSize:12 weight:NSFontWeightRegular],
        NSForegroundColorAttributeName : PanelColor(0xB8, 0xC4, 0xCD, 1),
    };
    CGFloat width = [self verticalDetailColumnWidth] - kCellPadding * 2;
    NSRect textRect = [self.annotation boundingRectWithSize:NSMakeSize(width, CGFLOAT_MAX)
                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                 attributes:attrs
                                                    context:nil];
    return ceil(textRect.size.height);
}

// Translates the highlight's raw annotation (which the engine joins with \n:
// "[ipa]\ntranslation...") into a compact single-line footer. The `·` reads
// as a separator between the phonetic symbol and the gloss, matching
// SwiftType's "testa · n. [植]外种皮…" line. Returns nil when there's no
// annotation at all (footer stays hidden).
- (NSString *)annotationText {
    if (self.annotation.length == 0) {
        return nil;
    }
    NSArray *lines = [self.annotation componentsSeparatedByString:@"\n"];
    NSMutableArray *trimmed = [NSMutableArray arrayWithCapacity:lines.count];
    for (NSString *line in lines) {
        NSString *t = [line stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        if (t.length > 0) {
            [trimmed addObject:t];
        }
    }
    if (trimmed.count == 0) {
        return nil;
    }
    return [trimmed componentsJoinedByString:@" · "];
}

// Footer sits below every candidate row, stretched across the panel width.
// It's drawn on the panel's dark background (a single tile, like the grid
// cells); lighter than candidate text so the gloss doesn't compete.
- (void)drawFooterInRect:(NSRect)footerRect {
    NSString *text = [self annotationText];
    if (text == nil || NSEqualRects(footerRect, NSZeroRect)) {
        return;
    }
    NSDictionary *attrs = @{
        NSFontAttributeName : [NSFont systemFontOfSize:12 weight:NSFontWeightRegular],
        NSForegroundColorAttributeName : PanelColor(0xB8, 0xC4, 0xCD, 1),
    };
    // One wrap pass to get the height for a laid-out line; drawing the same
    // string again guarantees the glyphs sit inside the box.
    NSRect box = footerRect;
    box.origin.x += kCellPadding;
    box.origin.y += kSelectionGap;
    box.size.width -= kCellPadding * 2;
    box.size.height -= kSelectionGap * 2;

    NSRect textRect = [text boundingRectWithSize:box.size
                                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                      attributes:attrs
                                         context:nil];
    textRect.origin.x = box.origin.x;
    textRect.origin.y = box.origin.y + MAX(0, (box.size.height - textRect.size.height) / 2);
    [text drawWithRect:textRect
               options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
            attributes:attrs
               context:nil];
}

// Where the footer row is drawn, or NSZeroRect when hidden.
- (NSRect)footerRect {
    NSString *text = [self annotationText];
    if (text == nil) {
        return NSZeroRect;
    }
    NSRect bounds = self.bounds;
    CGFloat height = [self footerHeight];
    return NSMakeRect(kPadding, bounds.size.height - height - kPadding, bounds.size.width - kPadding * 2, height);
}

// Padded box height for the footer, or 0 when hidden.
- (CGFloat)footerHeight {
    NSString *text = [self annotationText];
    if (text == nil) {
        return 0;
    }
    NSDictionary *attrs = @{
        NSFontAttributeName : [NSFont systemFontOfSize:12 weight:NSFontWeightRegular],
        NSForegroundColorAttributeName : PanelColor(0xB8, 0xC4, 0xCD, 1),
    };
    CGFloat width = self.bounds.size.width - kPadding * 2 - kCellPadding * 2;
    NSRect textRect = [text boundingRectWithSize:NSMakeSize(width, CGFLOAT_MAX)
                                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                      attributes:attrs
                                         context:nil];
    return ceil(textRect.size.height) + kFooterGap + kSelectionGap * 2;
}

// Each grid column is sized to its widest candidate among the VISIBLE rows
// only, like NSGridView's fitting size (hidden rows contribute nothing). A
// collapsed single-row bar therefore stays snug; the panel widens when the
// grid expands and already-showing rows come into play.
- (NSArray<NSNumber *> *)gridColumnWidths {
    CandidatePanelState *state = self.state;
    NSInteger columns = state.gridColumns;
    CGFloat widths[8] = {0};
    NSInteger rows = state.gridRenderedRowCount;
    for (NSInteger row = 0; row < rows; row++) {
        for (NSInteger col = 0; col < columns; col++) {
            NSInteger index = (state.gridVisibleRowOffset + row) * columns + col;
            if (index >= (NSInteger)state.candidates.count) {
                continue;
            }
            NSInteger number = col + 1; // worst case: gutter present
            NSAttributedString *cell = [self cellText:state.candidates[index] number:number active:NO];
            widths[col] = MAX(widths[col], cell.size.width + kCellInset);
        }
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

    NSInteger row = MIN((NSInteger)((p.y - kPadding) / kRowHeight), (grid ? state.gridRenderedRowCount : state.verticalVisibleRows) - 1);
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
    } else if (self.annotation.length > 0 && p.x > [self verticalCandidateColumnWidth]) {
        return; // tap on the detail column, not a candidate
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

// The translation/IPA gloss for the highlighted candidate. Feeding it here
// (instead of opening a separate annotation window) lets the panel grow a
// footer row in place; empty annotation keeps the panel at candidate rows.
- (void)setAnnotation:(NSString *)annotation {
    if ([self.content.annotation isEqual:annotation]) {
        return;
    }
    self.content.annotation = annotation;
    [self.content setNeedsDisplay:YES];
    [self resizeToFit];
    [self reposition];
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
        return NSMakeSize(MAX(kMinPanelWidth, panelWidth),
                          state.gridRenderedRowCount * kRowHeight + [self.content footerHeight] + kPadding * 2);
    }

    NSInteger count = MIN((NSInteger)state.candidates.count, state.verticalVisibleRows);
    CGFloat candidateWidth = [self.content verticalCandidateColumnWidth];
    CGFloat detailWidth = [self.content verticalDetailColumnWidth];
    BOOL hasDetail = detailWidth > 0;
    CGFloat width =
        hasDetail ? candidateWidth + kDetailGap + detailWidth + kPadding * 2 : MAX(kMinPanelWidth, candidateWidth + kPadding * 2);
    CGFloat height = MAX(count * kRowHeight, hasDetail ? [self.content verticalDetailHeightCost] : 0) + kPadding * 2;
    return NSMakeSize(width, height);
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
