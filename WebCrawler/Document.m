//
//  Document.m
//  WebCrawler
//
//  Created by Xu Lian on 2015-01-19.
//  Copyright (c) 2015 Beyondcow. All rights reserved.
//

#import <ASIHTTPRequest/ASIHTTPRequest.h>
#import <TUIKit.h>
#import "Document.h"
#import "NSToolbar+Height.h"

@interface Document ()

@end

@implementation Document

- (instancetype)init {
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

//- (void)awakeFromNib
//{
//}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    [_tabbutton setSelectedSegment:0];
    [_statusicon setImage:[NSImage imageNamed:@"NSStatusNone"]];
    [(NSTextFieldCell*)[_statusfield cell] setBackgroundStyle:NSBackgroundStyleRaised];
    [_statusfield setStringValue:@""];
    [_urlsview setDelegate:self];
    
    // The Context
    NSString *string = @"https://news.google.ca/\nhttp://news.yahoo.com/";
    
    //Regex to find your links .. image:: images/ssafs/sdfd-sdfsdg-ewfsdf2.png
    //You can / should improve Reges patter.
    
    NSRegularExpression *regexPatternForFullLinks = [NSRegularExpression regularExpressionWithPattern:@"(\\.\\.\\s(.*?\\.png))"
                                                                                              options:NSRegularExpressionCaseInsensitive error:nil];
    //Here find all image links and add them into an Array
    NSArray *arrayOfAllMatches = [regexPatternForFullLinks matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    NSMutableArray *links = [[NSMutableArray alloc] init];
    for (NSTextCheckingResult *match in arrayOfAllMatches) {
        [links addObject:[[string substringWithRange:match.range] stringByReplacingOccurrencesOfString:@".. image:: " withString:@"/"]];
    }
    
    //Replacing All your links with string: [Image]
    NSString *modifiedString = [regexPatternForFullLinks stringByReplacingMatchesInString:string
                                                                                  options:0
                                                                                    range:NSMakeRange(0, [string length])
                                                                             withTemplate:@"[Image]"];
    
    NSRegularExpression *regexPatternReplaceLinksWithIMAGEStr = [NSRegularExpression regularExpressionWithPattern:@"\\[image\\]"
                                                                                                          options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString:modifiedString];
    
    //Here,looking for all [Image] strings and add them Link Attribute
    NSArray *arrayOfAllMatchesImageText = [regexPatternReplaceLinksWithIMAGEStr matchesInString:modifiedString
                                                                                        options:0
                                                                                          range:NSMakeRange(0, modifiedString.length)];
    
    for (int i = 0; i < arrayOfAllMatchesImageText.count; i++) {
        NSTextCheckingResult *checkingResult = [arrayOfAllMatchesImageText objectAtIndex:i];
        [attrString beginEditing];
        [attrString addAttribute:NSLinkAttributeName value:[links objectAtIndex:i] range:checkingResult.range];
        [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor greenColor] range:checkingResult.range];
        [attrString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:0] range:checkingResult.range];
        [attrString endEditing];
    }
    
    //Set NSTextView Storage text...
    [_urlsview.textStorage setAttributedString:attrString];
    [self tabAction:_tabbutton];
    
}

+ (BOOL)autosavesInPlace {
    return YES;
}

- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"Document";
}

- (IBAction)startStopAction:(id)sender
{
    NSLog(@"startStopAction");
}

- (IBAction)tabAction:(NSSegmentedControl*)sender;
{
    if ([_tabbutton selectedSegment]==0) {
        [[_contentview subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [_tabview1 setFrame:_contentview.bounds];
        [_tabview1 setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [_contentview addSubview:_tabview1];
    }
    else if([_tabbutton selectedSegment]==1){
        [[_contentview subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [_tabview2 setFrame:_contentview.bounds];
        [_tabview2 setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [_contentview addSubview:_tabview2];
    
    }
    else if([_tabbutton selectedSegment]==2){
        [[_contentview subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        [_tabview3 setFrame:_contentview.bounds];
        [_tabview3 setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [_contentview addSubview:_tabview3];
    }
}
@end
