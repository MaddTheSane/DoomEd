#import <AppKit/AppKit.h>

void		StartPath (int path) DEPRECATED_MSG_ATTRIBUTE("Use NSBezierPath instead") UNAVAILABLE_ATTRIBUTE;
void		AddLine (int path, float x1, float y1, float x2, float y2) DEPRECATED_MSG_ATTRIBUTE("Use NSBezierPath instead") UNAVAILABLE_ATTRIBUTE;
void		FinishPath (int path) DEPRECATED_MSG_ATTRIBUTE("Use NSBezierPath instead") UNAVAILABLE_ATTRIBUTE;
BOOL	LineInRect (NSPoint *p1, NSPoint *p2, NSRect *r) DEPRECATED_MSG_ATTRIBUTE("Use EDLineInRect instead") UNAVAILABLE_ATTRIBUTE;
BOOL	EDLineInRect(NSPoint p1, NSPoint p2, NSRect r);
