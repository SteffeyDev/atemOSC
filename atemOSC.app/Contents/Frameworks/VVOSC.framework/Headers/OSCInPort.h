
#if IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#import <VVBasics/VVThreadLoop.h>
//#import <sys/types.h>
//#import <sys/socket.h>
#import <netinet/in.h>
#import <unistd.h>
#import <libkern/OSAtomic.h>
#import "OSCPacket.h"
#import "OSCBundle.h"
#import "OSCMessage.h"
#import "OSCOutPort.h"




///	OSCInPort handles everything needed to receive OSC data on a given port
/*!
You should never create or destroy an instance of this class manually.  OSCInPort instances should be created/destroyed by the OSCManager.

Each OSCInPort is running in its own separate thread- so make sure anything called as a result of received OSC input is thread-safe!  When OSCInPort receives data, it gets parsed and passed to the in port's delegate as a series of OSCMessages consisting of an address path and an OSCValue.  By default, the inport's delegate is the manager which created it- and by default, managers pass this data on to *their* delegates (your objects/app).

the documentation here only covers the basics, the header file for this class is small and heavily commented if you want to know more because you're heavily customizing OSCInPort.
*/
@interface OSCInPort : NSObject {
	BOOL					deleted;	//	whether or not i'm deleted- ensures that socket gets closed
	BOOL					bound;		//	whether or not the socket is bound
	OSSpinLock				socketLock;
	int						sock;		//	socket file descriptor.  remember, everything in unix is files!
	struct sockaddr_in		addr;		//	struct that describes *my* address (this is an in port)
	unsigned short			port;		//	the port number i'm receiving from
	unsigned char			buf[65506];	//	the socket gets data and dumps it here immediately
	
	OSSpinLock				scratchLock;
	NSThread				*thread;
	//VVThreadLoop			*threadLooper;
	
	NSString				*portLabel;		//!<the "name" of the port (added to distinguish multiple osc input ports for bonjour)
	NSNetService			*zeroConfDest;	//	bonjour service for publishing this input's address...only active if there's a portLabel!
	
	NSMutableArray			*scratchArray;	//	array of OSCMessage objects.  used for serial messaging.
	id						delegate;	//!<my delegate gets notified of incoming messages
}

//	Creates and returns an auto-released OSCInPort for the given port (or nil if the port's busy)
+ (id) createWithPort:(unsigned short)p;
//	Creates and returns an auto-released OSCInPort for the given port and label (or nil if the port's busy)
+ (id) createWithPort:(unsigned short)p labelled:(NSString *)n;
- (id) initWithPort:(unsigned short)p;
- (id) initWithPort:(unsigned short)p labelled:(NSString *)n;

- (void) prepareToBeDeleted;

///	returns an auto-released NSDictionary which describes this port (useful for restoring the state of the port later with OSCManager )
- (NSDictionary *) createSnapshot;

- (BOOL) createSocket;
- (void) start;
- (void) stop;
- (void) OSCThreadProc;
- (void) parseRawBuffer:(unsigned char *)b ofMaxLength:(int)l fromAddr:(unsigned int)txAddr port:(unsigned short)txPort;

///	called internally by this OSCInPort, passed an array of OSCMessage objects corresponding to the serially received data.  useful if you're subclassing OSCInPort.
- (void) handleScratchArray:(NSArray *)a;
///	called internally as messages are parsed.  useful if you're subclassing OSCInPort.
- (void) _addMessage:(OSCMessage *)val;
//	called internally by OSCManager when it's asked to dispatch a query.  you should never need to call this method manually.
- (void) _dispatchQuery:(OSCMessage *)m toOutPort:(OSCOutPort *)o;

- (unsigned short) port;
- (void) setPort:(unsigned short)n;
- (NSString *) portLabel;
- (void) setPortLabel:(NSString *)n;
- (NSNetService *) zeroConfDest;
- (BOOL) bound;
- (NSString *) ipAddressString;

///	returns the delegate (default is the OSCManager which created me).
- (id) delegate;
///	sets the delegate- the delegate is NOT retained!  if the delegate gets released before the port, make sure you set this to nil!
- (void) setDelegate:(id)n;
///	sets the frequency of the callback which checks for OSC input
- (void) setInterval:(double)n;

@end
