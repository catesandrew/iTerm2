//
//  ToolPasteHistory.m
//  iTerm
//
//  Created by George Nachman on 9/5/11.
//  Copyright 2011 Georgetech. All rights reserved.
//

#import "ToolPasteHistory.h"
#import "NSDateFormatterExtras.h"
#import "iTermController.h"

@implementation ToolPasteHistory

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        const CGFloat kButtonHeight = 23;
        const CGFloat kMargin = 4;

        clear_ = [[NSButton alloc] initWithFrame:NSMakeRect(0, frame.size.height - kButtonHeight, frame.size.width, kButtonHeight)];
        [clear_ setButtonType:NSMomentaryPushInButton];
        [clear_ setTitle:@"Clear All"];
        [clear_ setTarget:self];
        [clear_ setAction:@selector(clear:)];
        [clear_ setBezelStyle:NSSmallSquareBezelStyle];
        [clear_ sizeToFit];
        [clear_ setAutoresizingMask:NSViewMinYMargin];
        [self addSubview:clear_];
        [clear_ release];

        scrollView_ = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height - kButtonHeight - kMargin)];
        [scrollView_ setHasVerticalScroller:YES];
        [scrollView_ setHasHorizontalScroller:NO];
        NSSize contentSize = [scrollView_ contentSize];
        [scrollView_ setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

        tableView_ = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
        NSTableColumn *col;
        col = [[NSTableColumn alloc] initWithIdentifier:@"contents"];
        [col setEditable:NO];
        [tableView_ addTableColumn:col];
        [[col headerCell] setStringValue:@"Contents"];
        NSFont *theFont = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
        [[col dataCell] setFont:theFont];
        [tableView_ setRowHeight:[[[[NSLayoutManager alloc] init] autorelease] defaultLineHeightForFont:theFont]];

        [tableView_ setDataSource:self];
        [tableView_ setDelegate:self];

        [tableView_ setDoubleAction:@selector(doubleClickOnTableView:)];
        [tableView_ setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];


        [scrollView_ setDocumentView:tableView_];
        [self addSubview:scrollView_];

        [tableView_ sizeToFit];
        [tableView_ setColumnAutoresizingStyle:NSTableViewSequentialColumnAutoresizingStyle];
        
        pasteHistory_ = [PasteboardHistory sharedInstance];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(pasteboardHistoryDidChange:)
                                                     name:kPasteboardHistoryDidChange
                                                   object:nil];
        minuteRefreshTimer_ = [NSTimer scheduledTimerWithTimeInterval:61
                                                               target:self
                                                             selector:@selector(pasteboardHistoryDidChange:)
                                                             userInfo:nil
                                                              repeats:YES];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [minuteRefreshTimer_ invalidate];
    [tableView_ release];
    [scrollView_ release];
    [super dealloc];
}

- (void)shutdown
{
    [minuteRefreshTimer_ invalidate];
    minuteRefreshTimer_ = nil;
}

- (BOOL)isFlipped
{
    return YES;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[pasteHistory_ entries] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    PasteboardEntry* entry = [[pasteHistory_ entries] objectAtIndex:[[pasteHistory_ entries] count] - rowIndex - 1];
    if ([[aTableColumn identifier] isEqualToString:@"date"]) {
        // Date
        return [NSDateFormatter compactDateDifferenceStringFromDate:entry->timestamp];
    } else {
        // Contents
        NSString* value = [[entry mainValue] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        return value;
    }
}

- (void)pasteboardHistoryDidChange:(id)sender
{
    [tableView_ reloadData];
}

- (void)doubleClickOnTableView:(id)sender
{
    NSInteger selectedIndex = [tableView_ selectedRow];
    if (selectedIndex < 0) {
        return;
    }
    PasteboardEntry* entry = [[pasteHistory_ entries] objectAtIndex:[[pasteHistory_ entries] count] - selectedIndex - 1];
    NSPasteboard* thePasteboard = [NSPasteboard generalPasteboard];
    [thePasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [thePasteboard setString:[entry mainValue] forType:NSStringPboardType];
    [[[iTermController sharedInstance] frontTextView] paste:nil];
}

- (void)clear:(id)sender
{
    [pasteHistory_ eraseHistory];
    [pasteHistory_ clear];
    [tableView_ reloadData];
}

@end