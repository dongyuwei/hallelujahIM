#import "PreferencesWindowController.h"
#import "CandidatePanel.h"
#import "CandidateTheme.h"
#import "ConversionEngine.h"
#import "PinyinCandidateRows.h"

extern NSUserDefaults *preference;
extern ConversionEngine *engine;
extern CandidatePanel *sharedCandidates;
// Defined in main.mm; starts librime when the pinyin preference is on.
extern void startRimeEngine(void);

static PreferencesWindowController *sharedWindow = nil;

static const CGFloat kMaxTableHeight = 160;

@interface PreferencesWindowController () <NSTableViewDataSource, NSTableViewDelegate>
@end

@implementation PreferencesWindowController {
    NSTableView *_substitutionsTable;
    NSArray<NSString *> *_substitutionKeys;
    NSDictionary<NSString *, NSString *> *_substitutions;
    NSTextField *_shortcutField;
    NSTextField *_expansionField;
    NSButton *_removeButton;
    NSLayoutConstraint *_tableHeightConstraint;
}

+ (void)showPreferences {
    if (!sharedWindow) {
        sharedWindow = [[PreferencesWindowController alloc] init];
    }
    NSWindow *window = sharedWindow.window;
    // Clicking the IM menu leaves the host app active, and this background
    // (LSUIElement) app can lose the activation race — the window would stay
    // buried under the host app's windows. Float above normal windows so it is
    // always visible (including over fullscreen hosts); activation below only
    // decides whether it also takes focus without an extra click.
    window.level = NSFloatingWindowLevel;
    window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary;
    [window makeKeyAndOrderFront:nil];
    // Deferred one tick: the menu click first completes the host app's own
    // activation, which would otherwise push us right back down.
    dispatch_async(dispatch_get_main_queue(), ^{
        if (@available(macOS 14.0, *)) {
            [NSApp activate];
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [NSApp activateIgnoringOtherApps:YES];
#pragma clang diagnostic pop
        }
        [window makeKeyAndOrderFront:nil];
    });
}

- (instancetype)init {
    self = [super initWithWindow:nil];
    if (self) {
        NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 560, 460)
                                                       styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];
        window.title = @"Hallelujah Preferences";
        // The controller keeps the window alive across closes.
        window.releasedWhenClosed = NO;
        window.contentView = [self buildContentView];
        [window center];
        self.window = window;
        [self reloadSubstitutions];
    }
    return self;
}

- (NSView *)buildContentView {
    NSTextField *prefsHeader = [self sectionHeader:@"Preferences"];

    NSButton *showTranslation = [NSButton checkboxWithTitle:@"Show translation" target:self action:@selector(toggleTranslation:)];
    showTranslation.state = [preference boolForKey:@"showTranslation"] ? NSControlStateValueOn : NSControlStateValueOff;

    NSButton *commitWithSpace = [NSButton checkboxWithTitle:@"Commit word with space" target:self action:@selector(toggleCommitWithSpace:)];
    commitWithSpace.state = [preference boolForKey:@"commitWordWithSpace"] ? NSControlStateValueOn : NSControlStateValueOff;

    NSPopUpButton *gridColumns = [[NSPopUpButton alloc] init];
    for (NSInteger n = 5; n <= 9; n++) {
        [gridColumns addItemWithTitle:[NSString stringWithFormat:@"%ld", (long)n]];
        gridColumns.lastItem.tag = n;
    }
    [gridColumns selectItemWithTag:[preference integerForKey:@"gridCandidateColumns"]];
    gridColumns.target = self;
    gridColumns.action = @selector(chooseGridColumns:);

    NSPopUpButton *skin = [[NSPopUpButton alloc] init];
    NSString *currentSkin = [preference stringForKey:@"candidatePanelSkin"] ?: [CandidateTheme defaultSkinID];
    for (NSString *skinID in [CandidateTheme allSkinIDs]) {
        [skin addItemWithTitle:[self displayNameForSkinID:skinID]];
        skin.lastItem.representedObject = skinID;
        // Preview the skin on each item: active-word color on the panel background.
        skin.lastItem.attributedTitle = [self attributedSkinTitle:skinID];
        if ([skinID isEqualToString:currentSkin]) {
            [skin selectItem:skin.lastItem];
        }
    }
    skin.target = self;
    skin.action = @selector(chooseSkin:);

    NSButton *enablePinyin = [NSButton checkboxWithTitle:@"Enable pinyin (Rime) input" target:self action:@selector(togglePinyin:)];
    enablePinyin.state = [preference boolForKey:@"enablePinyinInput"] ? NSControlStateValueOn : NSControlStateValueOff;

    NSPopUpButton *pinyinPosition = [[NSPopUpButton alloc] init];
    for (NSInteger n = [PinyinCandidateRows minPosition]; n <= [PinyinCandidateRows maxPosition]; n++) {
        [pinyinPosition addItemWithTitle:[NSString stringWithFormat:@"%ld", (long)n]];
        pinyinPosition.lastItem.tag = n;
    }
    [pinyinPosition selectItemWithTag:[PinyinCandidateRows clampedPosition:[preference integerForKey:@"pinyinRawInputCandidatePosition"]]];
    pinyinPosition.target = self;
    pinyinPosition.action = @selector(choosePinyinPosition:);

    NSTextField *subsHeader = [self sectionHeader:@"Substitutions"];
    NSTextField *hint = [self substitutionsHint];
    NSScrollView *scroll = [self substitutionsScrollView];
    NSStackView *fieldRow = [self substitutionsFieldRow];

    NSView *columnsRow = [self formRowWithControl:gridColumns label:@"Grid columns (5-9)"];
    NSView *skinRow = [self formRowWithControl:skin label:@"Skin"];
    NSView *positionRow = [self formRowWithControl:pinyinPosition label:@"Pinyin raw input candidate position"];

    NSStackView *stack = [NSStackView stackViewWithViews:@[
        prefsHeader, showTranslation, commitWithSpace, columnsRow, skinRow, enablePinyin, positionRow, subsHeader, hint, scroll, fieldRow,
        _removeButton
    ]];
    stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    stack.alignment = NSLayoutAttributeLeading;
    stack.spacing = 8;
    [stack setCustomSpacing:4 afterView:prefsHeader];
    [stack setCustomSpacing:24 afterView:positionRow];
    [stack setCustomSpacing:4 afterView:subsHeader];
    [stack setCustomSpacing:10 afterView:hint];
    stack.edgeInsets = NSEdgeInsetsMake(16, 16, 16, 16);
    stack.translatesAutoresizingMaskIntoConstraints = NO;

    NSView *content = [[NSView alloc] init];
    [content addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:content.topAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:content.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:content.trailingAnchor],
        [stack.bottomAnchor constraintLessThanOrEqualToAnchor:content.bottomAnchor],
        // Stack width includes its edgeInsets; subtract them so these views stay
        // inside the inset instead of outdenting to the window edge.
        [hint.widthAnchor constraintEqualToAnchor:stack.widthAnchor constant:-32],
        [scroll.widthAnchor constraintEqualToAnchor:stack.widthAnchor constant:-32],
    ]];
    return content;
}

- (NSTextField *)sectionHeader:(NSString *)title {
    NSTextField *label = [NSTextField labelWithString:title];
    label.font = [NSFont systemFontOfSize:[NSFont labelFontSize] weight:NSFontWeightSemibold];
    return label;
}

- (NSView *)formRowWithControl:(NSView *)control label:(NSString *)labelText {
    NSTextField *label = [NSTextField labelWithString:labelText];

    NSStackView *row = [NSStackView stackViewWithViews:@[ label, control ]];
    row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    row.spacing = 10;
    row.alignment = NSLayoutAttributeCenterY;
    row.translatesAutoresizingMaskIntoConstraints = NO;
    return row;
}

- (NSTextField *)substitutionsHint {
    NSTextField *hint = [NSTextField wrappingLabelWithString:@"Shortcuts that expand into full text (e.g. \"yem\" → \"you expand me\")"];
    hint.textColor = NSColor.secondaryLabelColor;
    return hint;
}

- (NSScrollView *)substitutionsScrollView {
    NSTableColumn *keyColumn = [[NSTableColumn alloc] initWithIdentifier:@"key"];
    keyColumn.title = @"Shortcut";
    keyColumn.width = 140;
    NSTableColumn *valueColumn = [[NSTableColumn alloc] initWithIdentifier:@"value"];
    valueColumn.title = @"Expansion";

    _substitutionsTable = [[NSTableView alloc] init];
    [_substitutionsTable addTableColumn:keyColumn];
    [_substitutionsTable addTableColumn:valueColumn];
    _substitutionsTable.dataSource = self;
    _substitutionsTable.delegate = self;
    _substitutionsTable.usesAlternatingRowBackgroundColors = YES;
    _substitutionsTable.rowSizeStyle = NSTableViewRowSizeStyleDefault;
    [_substitutionsTable sizeLastColumnToFit];

    NSScrollView *scroll = [[NSScrollView alloc] init];
    scroll.documentView = _substitutionsTable;
    scroll.hasVerticalScroller = YES;
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    // Re-fitted to the row count on every reload.
    _tableHeightConstraint = [scroll.heightAnchor constraintEqualToConstant:kMaxTableHeight];
    _tableHeightConstraint.active = YES;
    return scroll;
}

- (NSStackView *)substitutionsFieldRow {
    _shortcutField = [NSTextField textFieldWithString:@""];
    _shortcutField.placeholderString = @"shortcut";
    [_shortcutField.widthAnchor constraintEqualToConstant:140].active = YES;
    _expansionField = [NSTextField textFieldWithString:@""];
    _expansionField.placeholderString = @"expansion";
    [_expansionField.widthAnchor constraintGreaterThanOrEqualToConstant:240].active = YES;

    NSButton *addButton = [NSButton buttonWithTitle:@"Add" target:self action:@selector(addSubstitution:)];
    _removeButton = [NSButton buttonWithTitle:@"Remove" target:self action:@selector(removeSubstitution:)];
    _removeButton.enabled = NO;

    // Return in either field adds the pair.
    for (NSTextField *field in @[ _shortcutField, _expansionField ]) {
        field.target = self;
        field.action = @selector(addSubstitution:);
    }

    NSStackView *fieldRow = [NSStackView stackViewWithViews:@[ _shortcutField, _expansionField, addButton, _removeButton ]];
    fieldRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    fieldRow.spacing = 8;
    fieldRow.alignment = NSLayoutAttributeCenterY;
    fieldRow.translatesAutoresizingMaskIntoConstraints = NO;
    return fieldRow;
}

#pragma mark - Actions

- (void)toggleTranslation:(NSButton *)sender {
    [preference setBool:sender.state == NSControlStateValueOn forKey:@"showTranslation"];
}

- (void)toggleCommitWithSpace:(NSButton *)sender {
    [preference setBool:sender.state == NSControlStateValueOn forKey:@"commitWordWithSpace"];
}

- (void)chooseGridColumns:(NSPopUpButton *)sender {
    // CandidatePanelState clamps; store the accepted value.
    [sharedCandidates setGridColumns:sender.selectedTag];
    [preference setInteger:[sharedCandidates gridColumns] forKey:@"gridCandidateColumns"];
}

- (void)chooseSkin:(NSPopUpButton *)sender {
    NSString *skinID = sender.selectedItem.representedObject;
    if (skinID.length == 0) {
        return;
    }
    [sharedCandidates setSkin:skinID];
    [preference setObject:skinID forKey:@"candidatePanelSkin"];
}

- (void)togglePinyin:(NSButton *)sender {
    BOOL enable = sender.state == NSControlStateValueOn;
    [preference setBool:enable forKey:@"enablePinyinInput"];
    if (enable) {
        // Button actions run on the main queue, same as the launch path.
        startRimeEngine();
    }
}

- (void)choosePinyinPosition:(NSPopUpButton *)sender {
    [preference setInteger:[PinyinCandidateRows clampedPosition:sender.selectedTag] forKey:@"pinyinRawInputCandidatePosition"];
}

- (void)addSubstitution:(id)sender {
    NSString *key = _shortcutField.stringValue;
    NSString *value = _expansionField.stringValue;
    if (key.length == 0 || value.length == 0) {
        return;
    }
    [engine addSubstitution:key value:value];
    _shortcutField.stringValue = @"";
    _expansionField.stringValue = @"";
    [self reloadSubstitutions];
}

- (void)removeSubstitution:(id)sender {
    NSInteger row = _substitutionsTable.selectedRow;
    if (row < 0) {
        return;
    }
    [engine removeSubstitution:_substitutionKeys[row]];
    [self reloadSubstitutions];
}

#pragma mark - Substitution table

- (void)reloadSubstitutions {
    _substitutions = [engine allSubstitutions] ?: @{};
    _substitutionKeys = [_substitutions.allKeys sortedArrayUsingSelector:@selector(compare:)];
    [_substitutionsTable reloadData];
    _removeButton.enabled = NO;

    // Fit the scroll view to the rows, capped at kMaxTableHeight. A few spare
    // points keep the vertical scroller from appearing for rounding slop.
    CGFloat contentHeight = _substitutionKeys.count ? NSMaxY([_substitutionsTable rectOfRow:_substitutionKeys.count - 1]) : 0;
    CGFloat headerHeight = _substitutionsTable.headerView.frame.size.height;
    _tableHeightConstraint.constant = MIN(kMaxTableHeight, headerHeight + contentHeight + 2);
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _substitutionKeys.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *key = _substitutionKeys[row];
    return [tableColumn.identifier isEqualToString:@"key"] ? key : _substitutions[key];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    _removeButton.enabled = _substitutionsTable.selectedRow >= 0;
}

#pragma mark - Skin display

- (NSString *)displayNameForSkinID:(NSString *)skinID {
    NSDictionary<NSString *, NSString *> *names = @{
        @"matrix" : @"Matrix 矩阵",
        @"verdant" : @"Verdant 青葱",
        @"carbon" : @"Carbon 碳黑",
        @"graphite" : @"Graphite 石墨",
        @"tangerine" : @"Tangerine 橘色",
        @"classic" : @"Classic 暗色",
    };
    return names[skinID] ?: skinID;
}

// Skin name in the skin's own colors (active-word text on panel background),
// padded on all sides. Horizontal padding uses non-breaking spaces — plain
// trailing spaces get no background paint; vertical padding comes from the
// raised minimum line height.
- (NSAttributedString *)attributedSkinTitle:(NSString *)skinID {
    CandidateTheme *theme = [CandidateTheme themeForSkinID:skinID];
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.minimumLineHeight = 20;

    return [[NSAttributedString alloc]
        initWithString:[NSString stringWithFormat:@"\u00A0\u00A0%@\u00A0\u00A0", [self displayNameForSkinID:skinID]]
            attributes:@{
                NSForegroundColorAttributeName : [self colorFromHex:theme.wordActiveColor],
                NSBackgroundColorAttributeName : [self colorFromHex:theme.backgroundColor],
                NSParagraphStyleAttributeName : paragraph,
            }];
}

- (NSColor *)colorFromHex:(NSUInteger)hex {
    return [NSColor colorWithCalibratedRed:((hex >> 16) & 0xFF) / 255.0
                                     green:((hex >> 8) & 0xFF) / 255.0
                                      blue:(hex & 0xFF) / 255.0
                                     alpha:1];
}

@end
