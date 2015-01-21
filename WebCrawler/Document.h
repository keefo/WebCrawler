//
//  Document.h
//  WebCrawler
//
//  Created by Xu Lian on 2015-01-19.
//  Copyright (c) 2015 Beyondcow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GroupButton.h"

@interface Document : NSPersistentDocument
@property(assign) IBOutlet NSToolbar *toolbar;
@property(assign) IBOutlet NSSegmentedControl *tabbutton;
@property(assign) IBOutlet NSToolbarItem *groupbuttonitem;
@property(assign) IBOutlet NSImageView *statusicon;
@property(assign) IBOutlet NSView *tabview1;
@property(assign) IBOutlet NSView *tabview2;
@property(assign) IBOutlet NSView *tabview3;
@property(assign) IBOutlet NSView *contentview;
@property(assign) IBOutlet NSTextView *urlsview;
@property(assign) IBOutlet NSTextField *statusfield;

- (IBAction)tabAction:(id)sender;

@end
