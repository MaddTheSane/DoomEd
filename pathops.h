#import <AppKit/AppKit.h>

void		StartPath (int path) DEPRECATED_MSG_ATTRIBUTE("Use NSBezierPath instead");
void		AddLine (int path, float x1, float y1, float x2, float y2) DEPRECATED_MSG_ATTRIBUTE("Use NSBezierPath instead");
void		FinishPath (int path) DEPRECATED_MSG_ATTRIBUTE("Use NSBezierPath instead");
BOOL	LineInRect (NSPoint *p1, NSPoint *p2, NSRect *r) DEPRECATED_MSG_ATTRIBUTE("Use NSBezierPath instead");
