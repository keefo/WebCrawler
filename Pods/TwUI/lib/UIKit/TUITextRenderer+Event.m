/*
 Copyright 2011 Twitter, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this work except in compliance with the License.
 You may obtain a copy of the License in the LICENSE file, or at:
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "TUITextRenderer+Event.h"
#import "ABActiveRange.h"
#import "TUICGAdditions.h"
#import "TUINSView.h"
#import "TUINSWindow.h"
#import "TUITextEditor.h"
#import "TUITextRenderer+Private.h"

@implementation TUITextRenderer (Event)

+ (void)initialize
{
	static BOOL initialized = NO;
	if(!initialized) {
		initialized = YES;
		// set up Services
		[NSApp registerServicesMenuSendTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] returnTypes:nil];
	}
}

- (id<TUITextRendererDelegate>)delegate
{
	return delegate;
}

- (void)setDelegate:(id<TUITextRendererDelegate>)d
{
	delegate = d;
	
	_flags.delegateActiveRangesForTextRenderer = [delegate respondsToSelector:@selector(activeRangesForTextRenderer:)];
	_flags.delegateWillBecomeFirstResponder = [delegate respondsToSelector:@selector(textRendererWillBecomeFirstResponder:)];
	_flags.delegateDidBecomeFirstResponder = [delegate respondsToSelector:@selector(textRendererDidBecomeFirstResponder:)];
	_flags.delegateWillResignFirstResponder = [delegate respondsToSelector:@selector(textRendererWillResignFirstResponder:)];
	_flags.delegateDidResignFirstResponder = [delegate respondsToSelector:@selector(textRendererDidResignFirstResponder:)];
}

- (CGPoint)localPointForEvent:(NSEvent *)event
{
	CGPoint p = [view localPointForEvent:event];
	p.x -= frame.origin.x;
	p.y -= frame.origin.y;
	return p;
}

- (CFIndex)stringIndexForPoint:(CGPoint)p
{
	return AB_CTFrameGetStringIndexForPosition([self ctFrame], p);
}

- (CFIndex)stringIndexForEvent:(NSEvent *)event
{
	return [self stringIndexForPoint:[self localPointForEvent:event]];
}

- (id<ABActiveTextRange>)rangeInRanges:(NSArray *)ranges forStringIndex:(CFIndex)index
{
	for(id<ABActiveTextRange> rangeValue in ranges) {
		NSRange range = [rangeValue rangeValue];
		if(NSLocationInRange(index, range))
			return rangeValue;
	}
	return nil;
}

- (NSImage *)dragImageForSelection:(NSRange)selection
{
	CGRect b = self.view.frame;
	
	_flags.drawMaskDragSelection = 1;
	NSImage *image = TUIGraphicsDrawAsImage(b.size, ^{
		[self draw];
	});
	_flags.drawMaskDragSelection = 0;
	return image;
}

- (BOOL)beginWaitForDragInRange:(NSRange)range string:(NSString *)string
{
	CFAbsoluteTime downTime = CFAbsoluteTimeGetCurrent();
	NSEvent *nextEvent = [NSApp nextEventMatchingMask:NSAnyEventMask
											untilDate:[NSDate distantFuture]
											   inMode:NSEventTrackingRunLoopMode
											  dequeue:YES];
	CFAbsoluteTime nextEventTime = CFAbsoluteTimeGetCurrent();
	if(([nextEvent type] == NSLeftMouseDragged) && (nextEventTime > downTime + 0.11)) {
		NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSDragPboard];
		[pasteboard clearContents];
		[pasteboard writeObjects:[NSArray arrayWithObject:string]];
		NSRect f = [view frameInNSView];
		
		CFIndex saveStart = _selectionStart;
		CFIndex saveEnd = _selectionEnd;
		_selectionStart = range.location;
		_selectionEnd = range.location + range.length;
		NSImage *image = [self dragImageForSelection:range];
		_selectionStart = saveStart;
		_selectionEnd = saveEnd;
		
		[view.nsView dragImage:image 
							at:f.origin
						offset:NSZeroSize
						 event:nextEvent 
					pasteboard:pasteboard 
						source:self 
					 slideBack:YES];
		return YES;
	} else {
		return NO;
	}
}

- (void)mouseDown:(NSEvent *)event
{
	CGRect previousSelectionRect = [self rectForCurrentSelection];
	
	switch([event clickCount]) {
		case 4:
			_selectionAffinity = TUITextSelectionAffinityParagraph;
			break;
		case 3:
			_selectionAffinity = TUITextSelectionAffinityLine;
			break;
		case 2:
			_selectionAffinity = TUITextSelectionAffinityWord;
			break;
		default:
			_selectionAffinity = TUITextSelectionAffinityCharacter;
			break;
	}
	
	CFIndex eventIndex = [self stringIndexForEvent:event];
	NSArray *ranges = nil;
	if(_flags.delegateActiveRangesForTextRenderer) {
		ranges = [delegate activeRangesForTextRenderer:self];
	}
	
	id<ABActiveTextRange> hitActiveRange = [self rangeInRanges:ranges forStringIndex:eventIndex];
	
	if([event clickCount] > 1)
		goto normal; // we want double-click-drag-select-by-word, not drag selected text
	
	if(hitActiveRange) {
		self.hitRange = hitActiveRange;
		[self.view redraw];
		self.hitRange = nil;
		
		NSRange r = [hitActiveRange rangeValue];
		NSString *s = [[attributedString string] substringWithRange:r];
		
		// bit of a hack
		if(hitActiveRange.rangeFlavor == ABActiveTextRangeFlavorURL) {
			if([hitActiveRange respondsToSelector:@selector(url)]) {
				NSString *urlString = [[hitActiveRange performSelector:@selector(url)] absoluteString];
				if(urlString)
					s = urlString;
			}
		}
		
		if(![self beginWaitForDragInRange:r string:s])
			goto normal;
	} else if(NSLocationInRange(eventIndex, [self selectedRange])) {
		if(![self beginWaitForDragInRange:[self selectedRange] string:[self selectedString]])
			goto normal;
	} else {
normal:
		if(([event modifierFlags] & NSShiftKeyMask) != 0) {
			CFIndex newIndex = [self stringIndexForEvent:event];
			if(newIndex < _selectionStart) {
				_selectionStart = newIndex;
			} else {
				_selectionEnd = newIndex;
			}
		} else {
			_selectionStart = [self stringIndexForEvent:event];
			_selectionEnd = _selectionStart;
		}
		
		self.hitRange = hitActiveRange;
	}
	
	CGRect totalRect = CGRectUnion(previousSelectionRect, [self rectForCurrentSelection]);
	[view setNeedsDisplayInRect:totalRect];
	if([self acceptsFirstResponder])
		[[view nsWindow] tui_makeFirstResponder:self];
}

- (void)mouseUp:(NSEvent *)event
{
	CGRect previousSelectionRect = [self rectForCurrentSelection];
	
	if(([event modifierFlags] & NSShiftKeyMask) == 0) {
		CFIndex i = [self stringIndexForEvent:event];
		_selectionEnd = i;
	}
	
	// fixup selection based on selection affinity
	BOOL flip = _selectionEnd < _selectionStart;
	CFRange trueRange = [self _selectedRange];
	_selectionStart = trueRange.location;
	_selectionEnd = _selectionStart + trueRange.length;
	if(flip) {
		// maintain anchor point, if we select with mouse, then start using keyboard to tweak
		CFIndex x = _selectionStart;
		_selectionStart = _selectionEnd;
		_selectionEnd = x;
	}
	
	_selectionAffinity = TUITextSelectionAffinityCharacter; // reset affinity
	
	CGRect totalRect = CGRectUnion(previousSelectionRect, [self rectForCurrentSelection]);
	[view setNeedsDisplayInRect:totalRect];
}

- (void)mouseDragged:(NSEvent *)event
{
	CGRect previousSelectionRect = [self rectForCurrentSelection];
	
	CFIndex i = [self stringIndexForEvent:event];
	_selectionEnd = i;
	
	CGRect totalRect = CGRectUnion(previousSelectionRect, [self rectForCurrentSelection]);
	[view setNeedsDisplayInRect:totalRect];
}

- (CGRect)rectForCurrentSelection {
	return [self rectForRange:[self _selectedRange]];
}

- (CGRect)rectForRange:(CFRange)range {
	CTFrameRef textFrame = [self ctFrame];
	CGRect totalRect = CGRectNull;
	if(range.length > 0) {
		CFIndex rectCount = 100;
		CGRect rects[rectCount];
		AB_CTFrameGetRectsForRangeWithAggregationType(textFrame, range, AB_CTLineRectAggregationTypeBlock, rects, &rectCount);
		
		for(CFIndex i = 0; i < rectCount; ++i) {
			CGRect rect = rects[i];
			rect = CGRectIntegral(rect);
			
			if(CGRectEqualToRect(totalRect, CGRectNull)) {
				totalRect = rect;
			} else {
				totalRect = CGRectUnion(rect, totalRect);
			}
		}
	}
	
	return totalRect;
}

- (void)resetSelection
{
	_selectionStart = 0;
	_selectionEnd = 0;
	_selectionAffinity = TUITextSelectionAffinityCharacter;
	self.hitRange = nil;
	[view setNeedsDisplay];
}

- (void)selectAll:(id)sender
{
	_selectionStart = 0;
	_selectionEnd = [[attributedString string] length];
	_selectionAffinity = TUITextSelectionAffinityCharacter;
	[view setNeedsDisplay];
}

- (void)copy:(id)sender
{
	NSString *selectedString = [self selectedString];
	if ([selectedString length] > 0) {
		[[NSPasteboard generalPasteboard] clearContents];
		[[NSPasteboard generalPasteboard] writeObjects:[NSArray arrayWithObject:selectedString]];
	} else {
		[[self nextResponder] tryToPerform:@selector(copy:) with:sender];
	}
}

- (BOOL)acceptsFirstResponder
{
	return !self.shouldRefuseFirstResponder;
}

- (BOOL)becomeFirstResponder
{
	// TODO: obviously these shouldn't be called at exactly the same time...
	if(_flags.delegateWillBecomeFirstResponder) [delegate textRendererWillBecomeFirstResponder:self];
	if(_flags.delegateDidBecomeFirstResponder) [delegate textRendererDidBecomeFirstResponder:self];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:TUITextRendererDidBecomeFirstResponder
								object:self];
	
	return YES;
}

- (BOOL)resignFirstResponder
{
	// TODO: obviously these shouldn't be called at exactly the same time...
	if(_flags.delegateWillResignFirstResponder) [delegate textRendererWillResignFirstResponder:self];
	[self resetSelection];
	if(_flags.delegateDidResignFirstResponder) [delegate textRendererDidResignFirstResponder:self];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:TUITextRendererDidResignFirstResponder
														object:self];
	
	return YES;
}

- (NSMenu *)menuForEvent:(NSEvent *)event {
	if(self.selectedRange.length > 0) {
		NSMenu *menu = [[NSMenu alloc] init];
		
		NSString *copyString = NSLocalizedString(@"Copy", @"Copy action menu item for TUITextRenderer.");
		NSString *googleString = [NSString stringWithFormat:@"%@ '%@'",
								  NSLocalizedString(@"Search Google for", @"Google action menu item for TUITextRenderer."),
								  self.selectedString];
		
		NSMenuItem *copyItem = [[NSMenuItem alloc] initWithTitle:copyString
														  action:@selector(copy:)
												   keyEquivalent:@""];
		copyItem.target = self;
		[menu addItem:copyItem];
		
		NSMenuItem *googleItem = [[NSMenuItem alloc] initWithTitle:googleString
															action:@selector(searchGoogle:)
													 keyEquivalent:@""];
		googleItem.target = self;
		[menu addItem:googleItem];
		
		[menu addItem:[NSMenuItem separatorItem]];
		return menu;
	}
	
	return nil;
}

- (void)searchGoogle:(NSMenuItem *)menuItem {
	NSString *urlEscapes = @"!*'();:@&=+$,/?%#[]";
	NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self.selectedString,
																									NULL, (CFStringRef)urlEscapes,
																									kCFStringEncodingUTF8));
	
	NSString *googleString = [NSString stringWithFormat:@"http://www.google.com/search?q=%@", encodedString];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:googleString]];
}

// Services

- (id)validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType
{
	if([sendType isEqualToString:NSStringPboardType] && !returnType) {
		if([[self selectedString] length] > 0)
			return self;
	}
	return [super validRequestorForSendType:sendType returnType:returnType];
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard types:(NSArray *)types
{
	if(![types containsObject:NSStringPboardType])
		return NO;
	
	[pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
	return [pboard setString:[self selectedString] forType:NSStringPboardType];
}

@end
