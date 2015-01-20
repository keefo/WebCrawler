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

#import "TUIButton.h"
#import "TUIControl+Private.h"

@interface TUIButtonContent : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSColor *titleColor;
@property (nonatomic, strong) NSColor *shadowColor;
@property (nonatomic, strong) NSImage *image;
@property (nonatomic, strong) NSImage *backgroundImage;
@end

@implementation TUIButtonContent
@synthesize title = title;
@synthesize titleColor = titleColor;
@synthesize shadowColor = shadowColor;
@synthesize image = image;
@synthesize backgroundImage = backgroundImage;
@end


@implementation TUIButton (Content)

- (TUIButtonContent *)_contentForState:(TUIControlState)state
{
	id key = @(state);
	TUIButtonContent *c = [_contentLookup objectForKey:key];

	if (c == nil && (state & TUIControlStateNotKey)) {
		// Try matching without the NotKey state.
		c = [_contentLookup objectForKey:@(state & ~TUIControlStateNotKey)];
	}

	if (c == nil) {
		c = [[TUIButtonContent alloc] init];
		[_contentLookup setObject:c forKey:key];
	}

	return c;
}

- (void)setTitle:(NSString *)title forState:(TUIControlState)state
{
	[self _stateWillChange];
	[[self _contentForState:state] setTitle:title];
	[self setNeedsDisplay];
	[self _stateDidChange];
}

- (void)setTitleColor:(NSColor *)color forState:(TUIControlState)state
{
	[self _stateWillChange];
	[[self _contentForState:state] setTitleColor:color];
	[self setNeedsDisplay];
	[self _stateDidChange];
}

- (void)setTitleShadowColor:(NSColor *)color forState:(TUIControlState)state
{
	[self _stateWillChange];
	[[self _contentForState:state] setShadowColor:color];
	[self setNeedsDisplay];
	[self _stateDidChange];
}

- (void)setImage:(NSImage *)i forState:(TUIControlState)state
{
	[self _stateWillChange];
	[[self _contentForState:state] setImage:i];
	[self setNeedsDisplay];
	[self _stateDidChange];
}

- (void)setBackgroundImage:(NSImage *)i forState:(TUIControlState)state
{
	[self _stateWillChange];
	[[self _contentForState:state] setBackgroundImage:i];
	[self setNeedsDisplay];
	[self _stateDidChange];
}

- (NSString *)titleForState:(TUIControlState)state
{
	return [[self _contentForState:state] title];
}

- (NSColor *)titleColorForState:(TUIControlState)state
{
	return [[self _contentForState:state] titleColor];
}

- (NSColor *)titleShadowColorForState:(TUIControlState)state
{
	return [[self _contentForState:state] shadowColor];
}

- (NSImage *)imageForState:(TUIControlState)state
{
	return [[self _contentForState:state] image];
}

- (NSImage *)backgroundImageForState:(TUIControlState)state
{
	return [[self _contentForState:state] backgroundImage];
}

- (NSString *)currentTitle
{
	NSString *title = [self titleForState:self.state];
	if(title == nil) {
		title = [self titleForState:TUIControlStateNormal];
	}
	
	return title;
}

- (NSColor *)currentTitleColor
{
	NSColor *color = [self titleColorForState:self.state];
	if(color == nil) {
		color = [self titleColorForState:TUIControlStateNormal];
	}
	
	return color;
}

- (NSColor *)currentTitleShadowColor
{
	NSColor *color = [self titleShadowColorForState:self.state];
	if(color == nil) {
		color = [self titleShadowColorForState:TUIControlStateNormal];
	}
	
	return color;
}

- (NSImage *)currentImage
{
	NSImage *image = [self imageForState:self.state];
	if(image == nil) {
		image = [self imageForState:TUIControlStateNormal];
	}
	
	return image;
}

- (NSImage *)currentBackgroundImage
{
	NSImage *image = [self backgroundImageForState:self.state];
	if(image == nil) {
		image = [self backgroundImageForState:TUIControlStateNormal];
	}
	
	return image;
}

@end
