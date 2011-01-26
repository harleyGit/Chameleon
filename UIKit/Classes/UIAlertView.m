//  Created by Sean Heber on 6/25/10.
#import "UIAlertView.h"
#import "UIApplication.h"

#import <AppKit/NSAlert.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSButton.h>

@interface UIAlertView ()
@property (nonatomic, retain) NSMutableArray *buttonTitles;
@end

@implementation UIAlertView
@synthesize title=_title, message=_message, delegate=_delegate, cancelButtonIndex=_cancelButtonIndex, buttonTitles=_buttonTitles;

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...
{
	if ((self=[super initWithFrame:CGRectZero])) {
		self.title = title;
		self.message = message;
		self.delegate = delegate;
		self.buttonTitles = [NSMutableArray arrayWithCapacity:1];

		if (cancelButtonTitle) {
			self.cancelButtonIndex = [self addButtonWithTitle:cancelButtonTitle];
		}
		
		if (otherButtonTitles) {
			[self addButtonWithTitle:otherButtonTitles];

			id buttonTitle = nil;
			va_list argumentList;
			va_start(argumentList, otherButtonTitles);

			while ((buttonTitle=va_arg(argumentList, NSString *))) {
				
				[self addButtonWithTitle:buttonTitle];
			}
			
			va_end(argumentList);
		}
	}
	return self;
}

- (void)dealloc
{
	[_title release];
	[_message release];
	[_buttonTitles release];
	[super dealloc];
}

- (void)setDelegate:(id<UIAlertViewDelegate>)newDelegate
{
	_delegate = newDelegate;
	_delegateHas.clickedButtonAtIndex = [_delegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)];
	_delegateHas.alertViewCancel = [_delegate respondsToSelector:@selector(alertViewCancel:)];
	_delegateHas.willPresentAlertView = [_delegate respondsToSelector:@selector(willPresentAlertView:)];
	_delegateHas.didPresentAlertView = [_delegate respondsToSelector:@selector(didPresentAlertView:)];
	_delegateHas.willDismissWithButtonIndex = [_delegate respondsToSelector:@selector(alertView:willDismissWithButtonIndex:)];
	_delegateHas.didDismissWithButtonIndex = [_delegate respondsToSelector:@selector(alertView:didDismissWithButtonIndex:)];
}

- (NSInteger)addButtonWithTitle:(NSString *)title
{
	[self.buttonTitles addObject:title];
	return ([self.buttonTitles count] - 1);
}

- (NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex
{
	return [self.buttonTitles objectAtIndex:buttonIndex];
}


- (NSInteger)numberOfButtons
{
	return [self.buttonTitles count];
}

- (void)show
{
	// capture the current button configuration and build an NSAlert
	// we show it after letting the runloop finish because UIKit stuff is often written with the assumption
	// that showing an alert doesn't block the runloop. Kinda icky, but the same pattern is used for UIActionSheet
	// and the UIMenuController and I don't know there's a lot that I can do about it.
	// NSAlert does have a mode that doesn't block the runloop, but it has other drawbacks that I didn't like
	// so opting to do it this way here. :/

	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	NSMutableArray *buttonOrder = [[[NSMutableArray alloc] initWithCapacity:self.numberOfButtons] autorelease];
	
	if (self.title) {
		[alert setMessageText:self.title];
	}
	
	if (self.message) {
		[alert setInformativeText:self.message];
	}
	
	for (NSInteger buttonIndex=0; buttonIndex<self.numberOfButtons; buttonIndex++) {
		if (buttonIndex != self.cancelButtonIndex) {
			[alert addButtonWithTitle:[self.buttonTitles objectAtIndex:buttonIndex]];
			[buttonOrder addObject:[NSNumber numberWithInt:buttonIndex]];
		}
	}
	
	if (self.cancelButtonIndex >= 0) {
		NSButton *btn = [alert addButtonWithTitle:[self.buttonTitles objectAtIndex:self.cancelButtonIndex]];

		// only change the key equivelent if there's more than one button, otherwise we lose the "Return" key for triggering the default action
		if (self.numberOfButtons > 1) {
			[btn setKeyEquivalent:@"\033"];		// this should make the escape key trigger the cancel option
		}

		[buttonOrder addObject:[NSNumber numberWithInt:self.cancelButtonIndex]];
	}
	
	if (_delegateHas.willPresentAlertView) {
		[_delegate willPresentAlertView:self];
	}
	
	[self performSelector:@selector(_showAlertWithOptions:)
			   withObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   alert,		@"alert",
						   buttonOrder, @"buttonOrder",
						   nil]
			   afterDelay:0];
}

- (void)_showAlertWithOptions:(NSDictionary *)options
{
	NSAlert *alert = [options objectForKey:@"alert"];
	NSMutableArray *buttonOrder = [options objectForKey:@"buttonOrder"];
	
	if (_delegateHas.didPresentAlertView) {
		[_delegate didPresentAlertView:self];
	}
	
	NSInteger result = [alert runModal];
	NSInteger buttonIndex = -1;
	
	switch (result) {
		case NSAlertFirstButtonReturn:
			buttonIndex = [[buttonOrder objectAtIndex:0] intValue];
			break;
		case NSAlertSecondButtonReturn:
			buttonIndex = [[buttonOrder objectAtIndex:1] intValue];
			break;
		case NSAlertThirdButtonReturn:
			buttonIndex = [[buttonOrder objectAtIndex:2] intValue];
			break;
		default:
			buttonIndex = [[buttonOrder objectAtIndex:2+(result-NSAlertThirdButtonReturn)] intValue];
			break;
	}
	
	if (_delegateHas.clickedButtonAtIndex) {
		[_delegate alertView:self clickedButtonAtIndex:buttonIndex];
	}

	if (_delegateHas.willDismissWithButtonIndex) {
		[_delegate alertView:self willDismissWithButtonIndex:buttonIndex];
	}
	
	if (_delegateHas.didDismissWithButtonIndex) {
		[_delegate alertView:self didDismissWithButtonIndex:buttonIndex];
	}
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated
{
}

@end
