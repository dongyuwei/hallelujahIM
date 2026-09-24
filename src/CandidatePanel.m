#import "CandidatePanel.h"

// SwiftType-style palette and metrics (cloned from its Theme):
// background #1B1B1B, border #1B1B1B (2pt), corner radius 6,
// text #FCFCFC, number #A0796A, highlight #533566.
// Selection is carried by the opaque highlight pill plus a white candidate
// (7.6:1 on the rendered pill); the number keycap keeps the theme's warm accent
// but brightened to #FFCC80 (5.1:1), because the muted #A0796A it uses when
// unselected would be 2.8:1 on the pill and effectively invisible.
static const CGFloat kRowHeight = 24;
// kPadding + kCellPadding is also the horizontal gap between grid columns
// (2 * (kPadding + kCellPadding) per cell, i.e. 8pt today). Keep them tight:
// this is a HUD, and the panel is as wide as the sum of its columns.
static const CGFloat kPadding = 2;
static const CGFloat kCellPadding = 2;
static const CGFloat kCornerRadius = 6;
// Gap between the highlight pill and the row edge. The pill is therefore
// kRowHeight - 2 * kSelectionGap = 20pt tall, only 3pt more than the 14pt
// font's line box: at 3pt (18pt pill) the baseline sat low enough that a
// descender ('y' in "testimony") came within 1pt of the pill's bottom edge.
static const CGFloat kSelectionGap = 2;
// Optical correction: a line box reserves more room above its ascenders than a
// lowercase word actually uses, so centring the BOX leaves the ink about 0.5pt
// below the middle of the pill. Nudging the text up makes the common
// (descender-less) candidate look centred; it is applied to every cell, so all
// rows keep one baseline.
static const CGFloat kTextOpticalRise = 0.5;
static const CGFloat kMinPanelWidth = 44;
static const CGFloat kMinCellWidth = 44;     // per-cell floor when the display forces a narrower grid
static const CGFloat kMaxCellWidth = 150;    // a single cell never grows wider than this
static const CGFloat kNumberGapFontSize = 5; // gap between a digit and its word, in the key font
static const CGFloat kFallbackLineHeight = 20;
static const CGFloat kFooterGap = 5;        // space above the translation footer
static const CGFloat kMaxFooterWidth = 240; // widest the footer grows before wrapping

static NSColor *PanelColor(int r, int g, int b, CGFloat alpha) {
    return [NSColor colorWithCalibratedRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:alpha];
}

// Cell insets used by drawing (kPadding + kCellPadding on each side).
static const CGFloat kCellInset = (kPadding + kCellPadding) * 2;

// Renders the candidates described by CandidatePanelState. Single drawRect
// pass: grid cells, with a pill behind the active candidate.
@interface CandidatePanelContent : NSView

@property(nonatomic, strong) CandidatePanelState *state;
@property(nonatomic, copy) void (^clickHandler)(NSInteger index);

// Translation/IPA summary for the highlighted candidate, drawn as a single
// bottom row. Empty string renders no footer (panel collapses back).
@property(nonatomic, copy) NSString *annotation;

// Derived measurements and the text attributes they are built from. A single
// keystroke used to measure the same cells several times (preferredSize,
// drawRect, mouseDown), so the results are cached here. Everything cached is
// derived from (state, annotation, bounds width); -invalidateLayoutCache drops
// it and the state/annotation setters call it automatically. Bounds width is
// folded into the footer height cache separately because the panel is resized
// from the footer height it just measured.
@property(nonatomic) BOOL layoutCacheValid;
@property(nonatomic, strong) NSArray<NSNumber *> *cachedGridColumnWidths;
@property(nonatomic) CGFloat cachedFooterHeight;
@property(nonatomic) CGFloat cachedFooterHeightWidth;
@property(nonatomic) CGFloat cachedFooterTextWidth;
@property(nonatomic, copy) NSString *cachedAnnotationText;
@property(nonatomic) BOOL cachedAnnotationTextValid;
@property(nonatomic, strong) NSDictionary *wordAttrs;
@property(nonatomic, strong) NSDictionary *wordAttrsActive;
@property(nonatomic, strong) NSDictionary *numberAttrs;
@property(nonatomic, strong) NSDictionary *numberAttrsActive;
@property(nonatomic, strong) NSDictionary *gapAttrs;
@property(nonatomic, strong) NSDictionary *gapAttrsActive;
@property(nonatomic, strong) NSDictionary *detailAttrs;

- (NSAttributedString *)cellText:(NSString *)text number:(NSInteger)number active:(BOOL)active;
- (NSArray<NSNumber *> *)gridColumnWidths;
- (CGFloat)maxGridCellWidthForColumns:(NSInteger)columns;
- (CGFloat)footerHeight;
- (CGFloat)footerHeightForWidth:(CGFloat)width;
- (CGFloat)footerTextWidth;
- (NSString *)annotationText;
- (void)invalidateLayoutCache;

@end

@implementation CandidatePanelContent

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self buildTextAttributes];
    }
    return self;
}

// Fonts and colors never change, so the attribute runs are built once instead
// of once per cell per measurement.
- (void)buildTextAttributes {
    _wordAttrs = @{
        NSFontAttributeName : [NSFont systemFontOfSize:14 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName : PanelColor(0xFC, 0xFC, 0xFC, 1),
    };
    _wordAttrsActive = @{
        NSFontAttributeName : [NSFont systemFontOfSize:14 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName : PanelColor(0xFF, 0xFF, 0xFF, 1),
    };
    _numberAttrs = @{
        NSFontAttributeName : [NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName : PanelColor(0xA0, 0x79, 0x6A, 1),
    };
    _numberAttrsActive = @{
        NSFontAttributeName : [NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName : PanelColor(0xFF, 0xCC, 0x80, 1),
    };
    _gapAttrs = @{
        NSFontAttributeName : [NSFont monospacedSystemFontOfSize:kNumberGapFontSize weight:NSFontWeightMedium],
        NSForegroundColorAttributeName : PanelColor(0xA0, 0x79, 0x6A, 1),
    };
    _gapAttrsActive = @{
        NSFontAttributeName : [NSFont monospacedSystemFontOfSize:kNumberGapFontSize weight:NSFontWeightMedium],
        NSForegroundColorAttributeName : PanelColor(0xFF, 0xCC, 0x80, 1),
    };
    _detailAttrs = @{
        NSFontAttributeName : [NSFont systemFontOfSize:12 weight:NSFontWeightRegular],
        NSForegroundColorAttributeName : PanelColor(0xB8, 0xC4, 0xCD, 1),
    };
}

// Drops every derived measurement; they are recomputed together on next use.
- (void)invalidateLayoutCache {
    _layoutCacheValid = NO;
    _cachedGridColumnWidths = nil;
    _cachedFooterHeight = 0;
    _cachedFooterHeightWidth = 0;
    _cachedFooterTextWidth = 0;
}

- (void)setState:(CandidatePanelState *)state {
    _state = state;
    [self invalidateLayoutCache];
}

- (void)setAnnotation:(NSString *)annotation {
    if (_annotation == annotation || [_annotation isEqualToString:annotation]) {
        return;
    }
    _annotation = [annotation copy];
    _cachedAnnotationText = nil;
    _cachedAnnotationTextValid = NO;
    [self invalidateLayoutCache];
}

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

    [self drawGridCellsForState:state];
    [self drawFooterInRect:[self footerRect]];
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

// Fills every layout-dependent measurement in one pass. The flag is set before
// measuring so that a nested accessor reads what is already cached instead of
// recursing.
- (void)ensureLayoutCache {
    if (self.layoutCacheValid) {
        return;
    }
    self.layoutCacheValid = YES;
    self.cachedGridColumnWidths = [self measureGridColumnWidths];
    self.cachedFooterTextWidth = [self measureFooterTextWidth];
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
    if (self.cachedAnnotationTextValid) {
        return self.cachedAnnotationText;
    }
    self.cachedAnnotationTextValid = YES;
    NSArray *lines = [self.annotation componentsSeparatedByString:@"\n"];
    NSMutableArray *trimmed = [NSMutableArray arrayWithCapacity:lines.count];
    for (NSString *line in lines) {
        NSString *t = [line stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        if (t.length > 0) {
            [trimmed addObject:t];
        }
    }
    self.cachedAnnotationText = trimmed.count > 0 ? [trimmed componentsJoinedByString:@" · "] : nil;
    return self.cachedAnnotationText;
}

// Footer sits below every candidate row, stretched across the panel width.
// It's drawn on the panel's dark background (a single tile, like the grid
// cells); lighter than candidate text so the gloss doesn't compete.
- (void)drawFooterInRect:(NSRect)footerRect {
    NSString *text = [self annotationText];
    if (text == nil || NSEqualRects(footerRect, NSZeroRect)) {
        return;
    }
    NSDictionary *attrs = self.detailAttrs;
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

// Padded box height for the footer, or 0 when hidden. The wrap depends on the
// panel width, so the cached value remembers the width it was measured for and
// is recomputed once the panel is resized.
- (CGFloat)footerHeight {
    return [self footerHeightForWidth:self.bounds.size.width];
}

// preferredSize passes the width it is about to resize to, so a footer-driven
// widening lands on the one-line height in the same pass instead of a
// keystroke later.
- (CGFloat)footerHeightForWidth:(CGFloat)width {
    NSString *text = [self annotationText];
    if (text == nil) {
        return 0;
    }
    if (self.cachedFooterHeight > 0 && self.cachedFooterHeightWidth == width) {
        return self.cachedFooterHeight;
    }
    CGFloat wrapWidth = width - kPadding * 2 - kCellPadding * 2;
    NSRect textRect = [text boundingRectWithSize:NSMakeSize(wrapWidth, CGFLOAT_MAX)
                                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                      attributes:self.detailAttrs
                                         context:nil];
    self.cachedFooterHeight = ceil(textRect.size.height) + kFooterGap + kSelectionGap * 2;
    self.cachedFooterHeightWidth = width;
    return self.cachedFooterHeight;
}

// One-line width of the footer text plus its padding, 0 when hidden. This is
// the grid panel's content-driven minimum width: the columns alone are only as
// wide as the visible words, which wrapped the gloss under a one-candidate
// grid.
- (CGFloat)footerTextWidth {
    [self ensureLayoutCache];
    return self.cachedFooterTextWidth;
}

- (CGFloat)measureFooterTextWidth {
    NSString *text = [self annotationText];
    if (text == nil) {
        return 0;
    }
    return [text sizeWithAttributes:self.detailAttrs].width + kPadding * 2 + kCellPadding * 2;
}

// Per-cell width cap for a grid of `columns` columns. kMaxCellWidth keeps a
// single long candidate from ballooning its column; the display budget keeps
// the whole grid on screen when many columns are configured, shrinking the cap
// (and so ellipsizing sooner) instead of letting the panel grow off-screen.
- (CGFloat)maxGridCellWidthForColumns:(NSInteger)columns {
    CGFloat budget = kMaxCellWidth;
    NSScreen *screen = NSScreen.mainScreen;
    if (screen != nil && columns > 0) {
        budget = MIN(budget, (screen.visibleFrame.size.width - kPadding * 2) / columns);
    }
    return MAX(kMinCellWidth, budget);
}

// Columns are sized to the rows actually on screen - the first row while
// collapsed, the visible window while expanded - so the grid is never wider
// than what the user can read.
//
// Fitting every candidate instead (so that scrolling could never re-fit) made
// the grid as wide as words that are scrolled out of view: in a measured
// 7-column session the panel was 808pt, and 83pt of that was two columns
// reserving room for off-screen words (column 2 held 124pt for visible words
// that needed 80pt). Compactness wins over never re-fitting: the panel is a
// floating HUD that must not sprawl, and re-fitting on scroll is the same
// behaviour the list had before the grid existed.
- (NSArray<NSNumber *> *)gridColumnWidths {
    [self ensureLayoutCache];
    return self.cachedGridColumnWidths ?: @[];
}

- (NSArray<NSNumber *> *)measureGridColumnWidths {
    CandidatePanelState *state = self.state;
    NSInteger columns = state.gridColumns;
    CGFloat widths[kCandidateGridMaxColumns] = {0};
    CGFloat cellCap = [self maxGridCellWidthForColumns:columns];
    NSInteger count = (NSInteger)state.candidates.count;
    NSInteger first = state.gridVisibleRowOffset * columns;
    NSInteger last = MIN(count, first + state.gridRenderedRowCount * columns);
    for (NSInteger index = first; index < last; index++) {
        NSInteger col = index % columns; // the column this candidate is laid out in
        // worst case: gutter present, so the word x never depends on the row
        // that happens to carry the selection keys
        NSAttributedString *cell = [self cellText:state.candidates[index] number:col + 1 active:NO];
        widths[col] = MAX(widths[col], cell.size.width + kCellInset);
    }
    NSMutableArray<NSNumber *> *result = [NSMutableArray arrayWithCapacity:columns];
    for (NSInteger col = 0; col < columns; col++) {
        [result addObject:@(MIN(widths[col], cellCap))];
    }
    return result;
}

// Single attributed string per cell: number gutter (mono, muted) + word.
// Measuring and drawing the same string guarantees the pill and width always
// fit.
//
// The gutter is reserved on EVERY cell, numbered row or not, so all rows of a
// column share one word x. Numbers are drawn only on the row that owns the
// selection keys, and without a reserved gutter that row's words sat a full
// gutter to the right of every other row's words in the same column.
//
// The gap after the digit is a U+00A0 at kNumberGapFontSize rather than a
// full-size space: a full space put the word 6.8pt away and the reserved hole
// in every unnumbered cell read as dead space (a measured 7-column session).
// U+00A0 can never be split from the digit by line breaking, and a digit and
// U+00A0 share the monospaced key font's advance at the same size - so a
// numbered cell ("1" + gap) and a blank one (U+00A0 + gap) reserve exactly the
// same width, which is what keeps the columns aligned.
// Colors cloned from SwiftType's default theme: word #FCFCFC (highlight
// #FFFFFF on the #533566 pill), number #A0796A (#FFCC80 when highlighted).
- (NSAttributedString *)cellText:(NSString *)text number:(NSInteger)number active:(BOOL)active {
    NSDictionary *wordAttrs = active ? self.wordAttrsActive : self.wordAttrs;
    NSDictionary *numberAttrs = active ? self.numberAttrsActive : self.numberAttrs;
    NSDictionary *gapAttrs = active ? self.gapAttrsActive : self.gapAttrs;
    NSString *numberText =
        (number > 0 && number <= kCandidateGridMaxColumns) ? [NSString stringWithFormat:@"%ld", (long)number] : @"\u00A0";
    NSMutableAttributedString *cell = [[NSMutableAttributedString alloc] init];
    [cell appendAttributedString:[[NSAttributedString alloc] initWithString:numberText attributes:numberAttrs]];
    [cell appendAttributedString:[[NSAttributedString alloc] initWithString:@"\u00A0" attributes:gapAttrs]];
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
        // Opaque, so the highlight's lightness (and therefore the candidate
        // text contrast) does not depend on what is painted behind it.
        [PanelColor(0x53, 0x35, 0x66, 1) setFill];
        [pill fill];
    }

    // Centred on the line box, then raised by the optical correction so the
    // ink - not the box - sits in the middle of the pill (see
    // kTextOpticalRise). Same offset for every cell, so the rows share one
    // baseline whether or not they are highlighted.
    CGFloat textY = pillRect.origin.y + MAX(0, (pillRect.size.height - textSize.height) / 2) - kTextOpticalRise;
    NSRect textRect = NSMakeRect(pillRect.origin.x + kCellPadding, textY,
                                 MAX(0, MIN(textSize.width, pillRect.size.width - kCellPadding * 2)), textSize.height);
    [cellText drawWithRect:textRect options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine context:nil];
}

- (void)mouseDown:(NSEvent *)event {
    CandidatePanelState *state = self.state;
    if (state.candidates.count == 0) {
        return;
    }
    NSPoint p = [self convertPoint:event.locationInWindow fromView:nil];
    NSInteger columns = state.gridColumns;
    NSArray<NSNumber *> *columnWidths = [self gridColumnWidths];

    NSInteger row = MIN((NSInteger)((p.y - kPadding) / kRowHeight), state.gridRenderedRowCount - 1);
    NSInteger col = 0;
    CGFloat x = 0;
    for (NSInteger c = 0; c < columns; c++) {
        x += columnWidths[c].doubleValue;
        if (p.x < x) {
            col = c;
            break;
        }
        col = c;
    }
    NSInteger index = row * columns + col + state.gridVisibleRowOffset * columns;
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
        _gridColumns = kCandidateGridDefaultColumns;
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

- (void)applyCandidates:(NSArray<NSString *> *)candidates {
    self.state = [[CandidatePanelState alloc] initWithCandidates:candidates columns:self.gridColumns];
    self.content.state = self.state;
}

- (void)updateCandidates:(NSArray<NSString *> *)candidates {
    [self applyCandidates:candidates];
    [self resizeToFit];
    [self reposition];
}

// One keystroke used to call updateCandidates:, showAtClient: and
// setAnnotation: in turn, and each of the three measured, resized, repositioned
// and marked the panel dirty on its own. This applies all of it and lays the
// panel out once. A nil annotation leaves the current gloss in place (pinyin
// mode shows none).
- (void)updateCandidates:(NSArray<NSString *> *)candidates annotation:(NSString *)annotation atClient:(id<IMKTextInput>)client {
    [self applyCandidates:candidates];
    if (annotation != nil) {
        self.content.annotation = annotation;
    }
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

// The state clamps to 5...9 columns, so read the count back from it: a caller
// asking for 20 columns gets a 9-column panel whose digits are all reachable.
// Assigns the ivar directly - this *is* the property's setter.
- (void)setGridColumns:(NSInteger)columns {
    NSArray *candidates = self.state.candidates;
    self.state = [[CandidatePanelState alloc] initWithCandidates:candidates columns:columns];
    _gridColumns = self.state.gridColumns;
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
    // navigation mutates the state in place, so the measurements derived from
    // it have to be dropped
    [self.content invalidateLayoutCache];
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
    NSArray<NSNumber *> *widths = [self.content gridColumnWidths];
    CGFloat panelWidth = 0;
    for (NSNumber *w in widths) {
        panelWidth += w.doubleValue;
    }
    // The gloss reads as one line: the panel is at least as wide as the
    // footer needs (capped, so a long translation wraps instead of sprawling
    // the HUD).
    CGFloat footerMinWidth = MIN([self.content footerTextWidth], kMaxFooterWidth);
    CGFloat width = MAX(MAX(kMinPanelWidth, panelWidth), footerMinWidth);
    return NSMakeSize(width, state.gridRenderedRowCount * kRowHeight + [self.content footerHeightForWidth:width] + kPadding * 2);
}

- (void)resizeToFit {
    NSSize size = [self preferredSize];
    if (NSEqualSizes(size, NSZeroSize)) {
        return;
    }
    NSRect frame = self.panel.frame;
    // A redundant resize still triggers AppKit layout (and, with display:YES,
    // an immediate redraw), so only touch the frame when the size really
    // changed. The panel is resized several times per keystroke.
    if (!NSEqualSizes(frame.size, size)) {
        frame.size = size;
        [self.panel setFrame:frame display:YES];
    }
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
    if (NSEqualPoints(self.panel.frame.origin, origin)) {
        return;
    }
    [self.panel setFrameOrigin:origin];
}

@end
