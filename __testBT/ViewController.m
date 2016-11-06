#import "ViewController.h"
#import "AVCamPreviewView.h"

#import "BTRBluetoothControl.h"
#import "BTRCameraDevice.h"

#import "__testBT-Swift.h"

@import AVFoundation;

#define DEBUG 1

static void * SessionRunningContext = &SessionRunningContext;

@interface ViewController () <BTRBluetoothControlDelegate, BTRCameraDeviceDelegate>

@property (nonatomic, strong) AVCamPreviewView *previewView;

@property (nonatomic, strong, readonly) BTRBluetoothControl *bluetoothControl;
@property (nonatomic, strong, readonly) BTRCameraDevice *cameraDevice;
@property (nonatomic, strong, readonly) RedCameraView *redCameraView;

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	_bluetoothControl = [[BTRBluetoothControl alloc] init];
	_bluetoothControl.delegate = self;

	_cameraDevice = [[BTRCameraDevice alloc] init];
	_cameraDevice.delegate = self;

	self.previewView = [[AVCamPreviewView alloc] initWithFrame:self.view.bounds];
	[self.view addSubview:self.previewView];

	_redCameraView = [[RedCameraView alloc] initWithFrame:self.view.bounds];
	_redCameraView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:_redCameraView];

	self.previewView.session = self.cameraDevice.captureSession;

	[self.cameraDevice requestPermission];


}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

#ifdef DEBUG
	[self.navigationController setNavigationBarHidden:YES animated:animated];
#endif

	[self.cameraDevice setupWithResultBlock:^(AVCamSetupResult result) {
		if (result == AVCamSetupResultCameraNotAuthorized) {
			NSString *message = NSLocalizedString( @"AVCam doesn't have permission to use the camera, please change privacy settings", @"Alert message when the user has denied access to the camera" );
			UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
			UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
			[alertController addAction:cancelAction];
			// Provide quick access to Settings.
			UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Settings", @"Alert button to open Settings" ) style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
			}];
			[alertController addAction:settingsAction];
			[self presentViewController:alertController animated:YES completion:nil];
		}
		else if (result == AVCamSetupResultSessionConfigurationFailed) {
			NSString *message = NSLocalizedString( @"Unable to capture media", @"Alert message when something goes wrong during capture session configuration" );
			UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
			UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
			[alertController addAction:cancelAction];
			[self presentViewController:alertController animated:YES completion:nil];
		}
	}];
}

#pragma mark BTRBluetoothControlDelegate

- (void)bluetoothControl:(BTRBluetoothControl *)control didChangeZoomValue:(double)zoomValue {
	self.cameraDevice.zoom = zoomValue;
	self.redCameraView.panelTop.zoom = zoomValue;
}

- (void)bluetoothControl:(BTRBluetoothControl *)control didChangeTemperature:(double)temperature {
	self.cameraDevice.temperature = temperature;
	self.redCameraView.panelTop.temperature = temperature;
}

- (void)bluetoothControl:(BTRBluetoothControl *)control startRecord:(BOOL)start {
	[self.cameraDevice toggleMovieRecordingWithOrientation:self.previewView.videoOrientation];
	[self.redCameraView.panelBottom recordWithRecord:start];
}

- (void)bluetoothControlDidToggleCamera:(BTRBluetoothControl *)control {
	[self.cameraDevice changeCamera];
}

#pragma mark BTRCameraDeviceDelegate

- (void)cameraDevice:(BTRCameraDevice *)cameraDevice didChangeVideoOrientation:(AVCaptureVideoOrientation)videoOrientation {
	self.previewView.videoOrientation = videoOrientation;
}

@end
