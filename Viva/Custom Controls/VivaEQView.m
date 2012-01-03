//
//  VivaEQView.m
//  Viva
//
//  Created by Daniel Kennett on 03/01/2012.
//  Copyright (c) 2012 Spotify. All rights reserved.
//

#import "VivaEQView.h"

static NSUInteger const kEQBandCount = 10;
static NSUInteger const kEQDBRange = 24;
static NSUInteger const kEQHorizontalGuidelineDBSpan = 3; // Draw a guideline every x dB
static CGFloat const kEQKnobPlaneLength = 14.0;
static CGFloat const kEQVerticalPadding = 20.0;
static CGFloat const kEQHorizontalPadding = 2.0;

@interface VivaEQView ()

-(NSRect)rectForKnobAtIndex:(NSUInteger)index;
-(double)dbAtIndex:(NSUInteger)index;
-(void)setDB:(double)db atIndex:(NSUInteger)index;
-(NSRect)drawableBounds;
-(void)drawKnobInRect:(NSRect)knobRect pushed:(BOOL)pushed;

@property (readwrite, nonatomic) NSInteger draggingIndex;

@end

@implementation VivaEQView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		[self addObserver:self forKeyPath:@"currentEQSettings" options:0 context:nil];
		self.draggingIndex = -1;
		self.currentEQSettings = [EQBands new];
    }
    
    return self;
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"currentEQSettings"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"currentEQSettings"]) {
        [self setNeedsDisplay:YES];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@synthesize currentEQSettings;
@synthesize draggingIndex;

#pragma mark -
#pragma mark Mouse

-(void)mouseDown:(NSEvent *)theEvent {
	
	NSPoint mousePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	for (NSUInteger currentIndex = 0; currentIndex < kEQBandCount; currentIndex++) {
		if (NSPointInRect(mousePoint, [self rectForKnobAtIndex:currentIndex])) {
			self.draggingIndex = currentIndex;
			break;
		}
	}
	
	if (self.draggingIndex == -1)
		return;
	
	[self setNeedsDisplay:YES];
	
}

-(void)mouseDragged:(NSEvent *)theEvent {
	
	if (self.draggingIndex == -1) return;
	
	NSPoint mousePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	CGFloat dbHeight = ([self drawableBounds].size.height / kEQDBRange);
	CGFloat unmodifiedDB = ((mousePoint.y - NSMinY([self drawableBounds])) / dbHeight);
	unmodifiedDB = MIN(kEQDBRange, MAX(0, unmodifiedDB));
	
	[self setDB:unmodifiedDB - (kEQDBRange / 2) atIndex:self.draggingIndex];
	[self setNeedsDisplay:YES];
}

-(void)mouseUp:(NSEvent *)theEvent {
	
	if (self.draggingIndex == -1) return;
	
	self.draggingIndex = -1;
	[self setNeedsDisplay:YES];
}

-(BOOL)mouseDownCanMoveWindow {
	return NO;
}

#pragma mark -
#pragma mark Drawing

-(void)drawRect:(NSRect)dirtyRect {
	
	// Useful numbers
	CGFloat dbHeight = ([self drawableBounds].size.height / kEQDBRange); 
	
	// Background
	NSGradient *backgroundGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.209 alpha:1.000]
															   endingColor:[NSColor colorWithCalibratedWhite:0.071 alpha:1.000]];
	
	[backgroundGradient drawInRect:self.bounds angle:90.0];
	
	[[NSGraphicsContext currentContext] saveGraphicsState];
	
	NSRect borderRect = NSMakeRect(0.5, 0.5, NSWidth(self.bounds) - 1, NSHeight(self.bounds) - 1);
	[[NSBezierPath bezierPathWithRect:NSInsetRect(borderRect, 0.5, 0.5)] setClip];
	
	// Horizontal lines
	
	[[NSGraphicsContext currentContext] saveGraphicsState];
	
	NSShadow *lineShadow = [[NSShadow alloc] init];
	lineShadow.shadowColor = [[NSColor whiteColor] colorWithAlphaComponent:0.05];
	lineShadow.shadowBlurRadius = 0.0;
	lineShadow.shadowOffset = NSMakeSize(0.0, -1.0);
	
	[lineShadow set];
	
	for (NSUInteger currentDb = 0; currentDb <= kEQDBRange; currentDb += kEQHorizontalGuidelineDBSpan) {
		CGFloat currentY = NSMinY([self drawableBounds]) + (currentDb * dbHeight);
		currentY = floor(currentY) + 0.5;
		[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(self.bounds), currentY) toPoint:NSMakePoint(NSMaxX(self.bounds), currentY)];
	}
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	
    // Dots
	
	NSBezierPath *eqPointPath = [[NSBezierPath alloc] init];
	
	NSMutableArray *rects = [NSMutableArray arrayWithCapacity:kEQBandCount];
	NSMutableArray *points = [NSMutableArray arrayWithCapacity:kEQBandCount];
	
	for (NSUInteger currentIndex = 0; currentIndex < kEQBandCount; currentIndex++) {
		
		NSRect knobRect = [self rectForKnobAtIndex:currentIndex];
		[rects addObject:[NSValue valueWithRect:knobRect]];
		
		NSPoint center = NSMakePoint(NSMidX(knobRect), NSMidY(knobRect));
		
		[points addObject:[NSValue valueWithPoint:center]];
		
		if (currentIndex == 0) {
			[eqPointPath moveToPoint:center];
		} else {
			[eqPointPath lineToPoint:center];
		}
	}
	
	NSPoint firstPoint = [[points objectAtIndex:0] pointValue];
	NSPoint lastPoint = [[points lastObject] pointValue];
	
	// Filler
	
	[eqPointPath lineToPoint:NSMakePoint(NSMaxX(self.bounds) + 2.0, lastPoint.y)];
	[eqPointPath lineToPoint:NSMakePoint(NSMaxX(self.bounds) + 2.0, NSMinY(self.bounds) - 2.0)]; // BR
	[eqPointPath lineToPoint:NSMakePoint(NSMinX(self.bounds) - 2.0, NSMinY(self.bounds) - 2.0)]; // BL
	[eqPointPath lineToPoint:NSMakePoint(NSMinX(self.bounds) - 2.0, firstPoint.y)];
	[eqPointPath closePath];
	
	[[NSGraphicsContext currentContext] saveGraphicsState];
	
	[eqPointPath addClip];
	[[NSColor blackColor] set];
	
	for (NSValue *pointValue in points) {
		NSPoint point = [pointValue pointValue];
		
		[NSBezierPath strokeLineFromPoint:point
								  toPoint:NSMakePoint(point.x, NSMinY(self.bounds))];
		
	}
	
	NSGradient *fillerGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.160 green:0.351 blue:0.037 alpha:0.9]
															 endingColor:[NSColor colorWithCalibratedRed:0.668 green:0.888 blue:0.266 alpha:0.9]];
	
	[fillerGradient drawInRect:self.bounds angle:90.0];
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	
	[[NSColor whiteColor] set];
	[eqPointPath setLineWidth:2.0];
	[eqPointPath stroke];
	
	for (NSValue *value in rects) {
		[[NSGraphicsContext currentContext] saveGraphicsState];
		[self drawKnobInRect:[value rectValue] pushed:[rects indexOfObject:value] == self.draggingIndex];
		[[NSGraphicsContext currentContext] restoreGraphicsState];
	}
	
	// Border
	
	// Top Line
	
	[[[NSColor blackColor] colorWithAlphaComponent:0.15] set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(1.0, NSMaxY(self.bounds) - 1.5)
							  toPoint:NSMakePoint(NSMaxX(self.bounds) - 1.0, NSMaxY(self.bounds) - 1.5)];
	
	[[[NSColor blackColor] colorWithAlphaComponent:0.05] set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(1.0, NSMaxY(self.bounds) - 2.5)
							  toPoint:NSMakePoint(NSMaxX(self.bounds) - 1.0, NSMaxY(self.bounds) - 2.5)];
	
	// Bottom line
	[[NSColor blackColor] set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(1.0, 1.5)
							  toPoint:NSMakePoint(NSMaxX(self.bounds) - 1.0, 1.5)];
	
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	
	
	// Border
	[[[NSColor blackColor] colorWithAlphaComponent:0.2] set];
	[NSBezierPath strokeRect:borderRect];

}

-(void)drawKnobInRect:(NSRect)knobRect pushed:(BOOL)pushed {
	
	NSShadow *knobShadow = [[NSShadow alloc] init];
	knobShadow.shadowColor = [[NSColor blackColor] colorWithAlphaComponent:1.0];
	knobShadow.shadowBlurRadius = 3.0;
	knobShadow.shadowOffset = NSMakeSize(0.0, 0.0);
	//[knobShadow set];
	
	NSGradient *knobGradient = nil;
	
	if (!pushed)
		knobGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.625 alpha:1.000]
													 endingColor:[NSColor colorWithCalibratedWhite:0.902 alpha:1.000]];
	else
		knobGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.902 alpha:1.000]
													 endingColor:[NSColor colorWithCalibratedWhite:0.625 alpha:1.000]];
		
	NSBezierPath *shadowCircle = [NSBezierPath bezierPathWithOvalInRect:knobRect];
	[[NSColor colorWithCalibratedWhite:0.0 alpha:0.4] set];
	[shadowCircle fill];
	
	NSBezierPath *smallCircle = [NSBezierPath bezierPathWithOvalInRect:NSInsetRect(knobRect, 1.0, 1.0)];
	[knobGradient drawInBezierPath:smallCircle angle:90.0];
	
}

-(NSRect)drawableBounds {
	return NSInsetRect(self.bounds, kEQHorizontalPadding, kEQVerticalPadding);
}

-(NSRect)rectForKnobAtIndex:(NSUInteger)index {
	
	NSUInteger columns = kEQBandCount + 1;
	CGFloat columnWidth = ([self drawableBounds].size.width / columns);
	CGFloat dbHeight = ([self drawableBounds].size.height / kEQDBRange); 
	
	return NSOffsetRect(NSMakeRect(floor(NSMinX([self drawableBounds]) + ((index + 1) * columnWidth)),
								   floor(NSMinY([self drawableBounds]) + (dbHeight * ([self dbAtIndex:index] + (kEQDBRange / 2)))),
								   kEQKnobPlaneLength,
								   kEQKnobPlaneLength),
						-(kEQKnobPlaneLength / 2),
						-(kEQKnobPlaneLength / 2));
}

#pragma mark -

-(double)dbAtIndex:(NSUInteger)index {
	
	switch (index) {
		case 0:
			return self.currentEQSettings.band1;
			break;
		case 1:
			return self.currentEQSettings.band2;
			break;
		case 2:
			return self.currentEQSettings.band3;
			break;
		case 3:
			return self.currentEQSettings.band4;
			break;
		case 4:
			return self.currentEQSettings.band5;
			break;
		case 5:
			return self.currentEQSettings.band6;
			break;
		case 6:
			return self.currentEQSettings.band7;
			break;
		case 7:
			return self.currentEQSettings.band8;
			break;
		case 8:
			return self.currentEQSettings.band9;
			break;
		case 9:
			return self.currentEQSettings.band10;
			break;
		default:
			return 0.0;
			break;
	}
}

-(void)setDB:(double)db atIndex:(NSUInteger)index {
	
	EQBands *newBands = [self.currentEQSettings copy];
	
	switch (index) {
		case 0:
			newBands.band1 = db;
			break;
		case 1:
			newBands.band2 = db;
			break;
		case 2:
			newBands.band3 = db;
			break;
		case 3:
			newBands.band4 = db;
			break;
		case 4:
			newBands.band5 = db;
			break;
		case 5:
			newBands.band6 = db;
			break;
		case 6:
			newBands.band7 = db;
			break;
		case 7:
			newBands.band8 = db;
			break;
		case 8:
			newBands.band9 = db;
			break;
		case 9:
			newBands.band10 = db;
			break;
		default:
			break;
	}
	
	self.currentEQSettings = newBands;
}

@end