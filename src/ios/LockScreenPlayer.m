/*

Add to MainViewController.h: 
@property (nonatomic, weak) CDVPlugin *remoteControlPlugin;

Add to MainViewController.m:
- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
	if ([self.remoteControlPlugin respondsToSelector:@selector(remoteControlReceivedWithEvent:)]) {
		[self.remoteControlPlugin performSelector:@selector(remoteControlReceivedWithEvent:) withObject:event];
	}
}

*/

#import "LockScreenPlayer.h"

@implementation LockScreenPlayer

- (void)pluginInitialize
{
	MainViewController* mainController = (MainViewController*)self.viewController;
	mainController.remoteControlPlugin = self;
	[mainController canBecomeFirstResponder];

	[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

-(void)onReset
{
	[[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

-(void)updateInfos:(CDVInvokedUrlCommand*)command
{
	CDVPluginResult* pluginResult = nil;
    
	NSDictionary* json = [command.arguments objectAtIndex : 0];
	NSString* title = [json objectForKey : @"title"];
	NSString* artistName = [json objectForKey : @"artistName"];
	NSString* albumName = [json objectForKey : @"albumName"];
	NSString* cover = [json objectForKey : @"cover"];
	NSNumber* duration = [json objectForKey : @"duration"];
	NSNumber* elapsedTime = [json objectForKey : @"currentDuration"];
    BOOL isPlaying = [[json objectForKey : @"isPlaying"] boolValue];
    
	if (NSClassFromString(@"MPNowPlayingInfoCenter")) {
		MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
		NSMutableDictionary* info = [NSMutableDictionary dictionaryWithCapacity : 6];
		[info setObject : artistName forKey : MPMediaItemPropertyArtist];
		[info setObject : title forKey : MPMediaItemPropertyTitle];
		[info setObject : albumName forKey : MPMediaItemPropertyAlbumTitle];
		[info setObject : duration forKey : MPMediaItemPropertyPlaybackDuration];
        [info setObject : elapsedTime forKey : MPNowPlayingInfoPropertyElapsedPlaybackTime];
        UIImage *image = [UIImage imageWithData:[[NSData alloc] initWithBase64EncodedString:cover options:NSDataBase64DecodingIgnoreUnknownCharacters]];
        if (image != nil) {
            CGImageRef cgref = [image CGImage];
            CIImage *cim = [image CIImage];
            if (cim != nil || cgref != NULL) {
                MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage: image];
                [info setValue : artwork forKey : MPMediaItemPropertyArtwork];
            }
        }
        [info setObject : [NSNumber numberWithDouble:isPlaying ? 1.0 : 0.0] forKey : MPNowPlayingInfoPropertyPlaybackRate];
        [center setNowPlayingInfo : info];
	}

	pluginResult = [CDVPluginResult resultWithStatus : CDVCommandStatus_OK messageAsString : @"Ok..."];
	//pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];

	[self.commandDelegate sendPluginResult : pluginResult callbackId : command.callbackId];
}

-(void)removePlayer:(CDVInvokedUrlCommand*)command
{
	CDVPluginResult* pluginResult = nil;

	[[UIApplication sharedApplication] endReceivingRemoteControlEvents];

	pluginResult = [CDVPluginResult resultWithStatus : CDVCommandStatus_OK messageAsString : @"Ok"];
	//pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];

	[self.commandDelegate sendPluginResult : pluginResult callbackId : command.callbackId];
}

-(void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent
{
	if (receivedEvent.type == UIEventTypeRemoteControl) {

		NSString *action = @"";

		switch (receivedEvent.subtype) {

		case UIEventSubtypeRemoteControlTogglePlayPause:
			action = @"playpause";//check current isPlaying
			break;
		case UIEventSubtypeRemoteControlPlay:
			action = @"ActionPlay";//check current isPlaying
			break;
		case UIEventSubtypeRemoteControlPause:
			action = @"ActionPause";//check current isPlaying
			break;
		case UIEventSubtypeRemoteControlPreviousTrack:
			action = @"ActionPrev";//check current isPlaying
			break;
		case UIEventSubtypeRemoteControlNextTrack:
			action = @"ActionNext";//check current isPlaying
			break;
		default:
			return;
		}

		NSDictionary *dict = @{@"type": action};
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject : dict options : 0 error : nil];
		NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding : NSUTF8StringEncoding];
		NSString *jsStatement = [NSString stringWithFormat : @"window.cordova.plugins.LockScreenPlayer._setEvent(%@)", jsonString];
		if ([self.webView isKindOfClass:[UIWebView class]]) {
			[(UIWebView*)self.webView stringByEvaluatingJavaScriptFromString : jsStatement];
		}
	}
}

@end
