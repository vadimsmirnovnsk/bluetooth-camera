#import "BTRCameraDevice.h"

@import UIKit;
@import Photos;

static void * SessionRunningContext = &SessionRunningContext;

@interface BTRCameraDevice () <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, strong) AVCaptureDeviceDiscoverySession *videoDeviceDiscoverySession;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic, strong, readwrite) AVCaptureSession *captureSession;
@property (nonatomic) AVCamSetupResult setupResult;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;

@end

@implementation BTRCameraDevice

- (instancetype)init
{
	self = [super init];
	if (self == nil) return nil;

	[self setupCaptureSession];

	return self;
}

#pragma mark Public

- (void)toggleMovieRecordingWithOrientation:(AVCaptureVideoOrientation)orientation {
	dispatch_async( self.sessionQueue, ^{
		if ( ! self.movieFileOutput.isRecording ) {
			if ( [UIDevice currentDevice].isMultitaskingSupported ) {
				/*
					Setup background task.
					This is needed because the -[captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:]
					callback is not received until AVCam returns to the foreground unless you request background execution time.
					This also ensures that there will be time to write the file to the photo library when AVCam is backgrounded.
					To conclude this background execution, -[endBackgroundTask:] is called in
					-[captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:] after the recorded file has been saved.
				 */
				self.backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
			}

			// Update the orientation on the movie file output video connection before starting recording.
			AVCaptureConnection *movieFileOutputConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
			movieFileOutputConnection.videoOrientation = orientation;

			// Start recording to a temporary file.
			NSString *outputFileName = [NSUUID UUID].UUIDString;
			NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mov"]];
			[self.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
		}
		else {
			[self.movieFileOutput stopRecording];
		}
	} );
}

- (void)setupWithResultBlock:(void (^)(AVCamSetupResult))block {
	dispatch_async( self.sessionQueue, ^{
		switch ( self.setupResult )
		{
			case AVCamSetupResultSuccess:
			{
				// Only setup observers and start the session running if setup succeeded.
				[self addObservers];
				[self.captureSession startRunning];
				break;
			}
			default: {

			} break;
		}

		dispatch_async( dispatch_get_main_queue(), ^{
			block(self.setupResult);
		} );
	} );
}

- (void)requestPermission {
	switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] ) {
		case AVAuthorizationStatusAuthorized: {
			// The user has previously granted access to the camera.
			break;
		}
		case AVAuthorizationStatusNotDetermined: {
			dispatch_suspend( self.sessionQueue );
			[AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
				if ( ! granted ) {
					self.setupResult = AVCamSetupResultCameraNotAuthorized;
				}
				dispatch_resume( self.sessionQueue );
			}];
			break;
		}
		default: {
			self.setupResult = AVCamSetupResultCameraNotAuthorized;
			break;
		}
	}
}

- (void)setTemperature:(double)temperature {
	_temperature = temperature;
	AVCaptureDevice *device = self.videoDeviceInput.device;

	AVCaptureWhiteBalanceTemperatureAndTintValues tint;
	tint.temperature = temperature;
	if ([device lockForConfiguration:nil]) {
		AVCaptureWhiteBalanceGains gains = [device deviceWhiteBalanceGainsForTemperatureAndTintValues:tint];
		gains.redGain = MIN([device maxWhiteBalanceGain], MAX(1, gains.redGain));
		gains.greenGain = MIN([device maxWhiteBalanceGain], MAX(1, gains.greenGain));
		gains.blueGain = MIN([device maxWhiteBalanceGain], MAX(1, gains.blueGain));
		NSLog(@">>>%f %f %f", gains.redGain, gains.greenGain, gains.blueGain);
		[self.videoDeviceInput.device setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains:gains completionHandler:^(CMTime syncTime) {
		}];
		[device unlockForConfiguration];
	}

}

- (void)setZoom:(double)zoom {
	_zoom = zoom;
	if ([self.videoDeviceInput.device lockForConfiguration:nil]) {
		self.videoDeviceInput.device.videoZoomFactor = zoom;
		[self.videoDeviceInput.device unlockForConfiguration];
	}
}

- (void)changeCamera {
	dispatch_async( self.sessionQueue, ^{
		AVCaptureDevice *currentVideoDevice = self.videoDeviceInput.device;
		AVCaptureDevicePosition currentPosition = currentVideoDevice.position;

		AVCaptureDevicePosition preferredPosition;
		AVCaptureDeviceType preferredDeviceType;

		switch ( currentPosition )
		{
			case AVCaptureDevicePositionUnspecified:
			case AVCaptureDevicePositionFront:
				preferredPosition = AVCaptureDevicePositionBack;
				preferredDeviceType = AVCaptureDeviceTypeBuiltInDuoCamera;
				break;
			case AVCaptureDevicePositionBack:
				preferredPosition = AVCaptureDevicePositionFront;
				preferredDeviceType = AVCaptureDeviceTypeBuiltInWideAngleCamera;
				break;
		}

		NSArray<AVCaptureDevice *> *devices = self.videoDeviceDiscoverySession.devices;
		AVCaptureDevice *newVideoDevice = nil;

		// First, look for a device with both the preferred position and device type.
		for ( AVCaptureDevice *device in devices ) {
			if ( device.position == preferredPosition && [device.deviceType isEqualToString:preferredDeviceType] ) {
				newVideoDevice = device;
				break;
			}
		}

		// Otherwise, look for a device with only the preferred position.
		if ( ! newVideoDevice ) {
			for ( AVCaptureDevice *device in devices ) {
				if ( device.position == preferredPosition ) {
					newVideoDevice = device;
					break;
				}
			}
		}

		if ( newVideoDevice ) {
			AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:newVideoDevice error:NULL];

			[self.captureSession beginConfiguration];

			// Remove the existing device input first, since using the front and back camera simultaneously is not supported.
			[self.captureSession removeInput:self.videoDeviceInput];

			if ( [self.captureSession canAddInput:videoDeviceInput] ) {
				[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];

				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:newVideoDevice];

				[self.captureSession addInput:videoDeviceInput];
				self.videoDeviceInput = videoDeviceInput;
			}
			else {
				[self.captureSession addInput:self.videoDeviceInput];
			}

			AVCaptureConnection *movieFileOutputConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
			if ( movieFileOutputConnection.isVideoStabilizationSupported ) {
				movieFileOutputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
			}

			/*
				Set Live Photo capture enabled if it is supported. When changing cameras, the
				`livePhotoCaptureEnabled` property of the AVCapturePhotoOutput gets set to NO when
				a video device is disconnected from the session. After the new video device is
				added to the session, re-enable Live Photo capture on the AVCapturePhotoOutput if it is supported.
			 */
			//self.photoOutput.livePhotoCaptureEnabled = self.photoOutput.livePhotoCaptureSupported;

			[self.captureSession commitConfiguration];
		}
	} );
}

#pragma mark Private

- (void)setupCaptureSession {
	self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );

	self.captureSession = [[AVCaptureSession alloc] init];
	NSArray<AVCaptureDeviceType> *deviceTypes = @[
												  AVCaptureDeviceTypeBuiltInWideAngleCamera,
												  AVCaptureDeviceTypeBuiltInDuoCamera
												  ];
	self.videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes
																							  mediaType:AVMediaTypeVideo
																							   position:AVCaptureDevicePositionUnspecified];

	dispatch_async( self.sessionQueue, ^{
		[self configureSession];
	} );
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
	CGPoint devicePoint = CGPointMake( 0.5, 0.5 );
	[self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange {
	dispatch_async( self.sessionQueue, ^{
		AVCaptureDevice *device = self.videoDeviceInput.device;
		NSError *error = nil;
		if ( [device lockForConfiguration:&error] ) {
			/*
				Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
				Call set(Focus/Exposure)Mode() to apply the new point of interest.
			 */
			if ( device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode] ) {
				device.focusPointOfInterest = point;
				device.focusMode = focusMode;
			}

			if ( device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode] ) {
				device.exposurePointOfInterest = point;
				device.exposureMode = exposureMode;
			}

			device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
			[device unlockForConfiguration];
		}
		else {
			NSLog( @"Could not lock device for configuration: %@", error );
		}
	} );
}

- (void)configureSession
{
	if ( self.setupResult != AVCamSetupResultSuccess ) {
		return;
	}

	NSError *error = nil;

	[self.captureSession beginConfiguration];

	/*
		We do not create an AVCaptureMovieFileOutput when setting up the session because the
		AVCaptureMovieFileOutput does not support movie recording with AVCaptureSessionPresetPhoto.
	 */
	self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;

	// Add video input.

	// Choose the back dual camera if available, otherwise default to a wide angle camera.
	AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDuoCamera
																	  mediaType:AVMediaTypeVideo
																	   position:AVCaptureDevicePositionBack];
	if ( ! videoDevice ) {
		// If the back dual camera is not available, default to the back wide angle camera.
		videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
														 mediaType:AVMediaTypeVideo
														  position:AVCaptureDevicePositionBack];

		// In some cases where users break their phones, the back wide angle camera is not available. In this case, we should default to the front wide angle camera.
		if ( ! videoDevice ) {
			videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
		}
	}
	AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
	if ( ! videoDeviceInput ) {
		NSLog( @"Could not create video device input: %@", error );
		self.setupResult = AVCamSetupResultSessionConfigurationFailed;
		[self.captureSession commitConfiguration];
		return;
	}

	if ( [self.captureSession canAddInput:videoDeviceInput] ) {
		[self.captureSession addInput:videoDeviceInput];
		self.videoDeviceInput = videoDeviceInput;

		dispatch_async( dispatch_get_main_queue(), ^{
			/*
				Why are we dispatching this to the main queue?
				Because AVCaptureVideoPreviewLayer is the backing layer for AVCamPreviewView and UIView
				can only be manipulated on the main thread.
				Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
				on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.

				Use the status bar orientation as the initial video orientation. Subsequent orientation changes are
				handled by -[AVCamCameraViewController viewWillTransitionToSize:withTransitionCoordinator:].
			 */
			UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
			AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
			if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
				initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
			}

			[self.delegate cameraDevice:self didChangeVideoOrientation:initialVideoOrientation];
		} );
	}
	else {
		NSLog( @"Could not add video device input to the session" );
		self.setupResult = AVCamSetupResultSessionConfigurationFailed;
		[self.captureSession commitConfiguration];
		return;
	}

	// Add audio input.
	AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
	AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
	if ( ! audioDeviceInput ) {
		NSLog( @"Could not create audio device input: %@", error );
	}
	if ( [self.captureSession canAddInput:audioDeviceInput] ) {
		[self.captureSession addInput:audioDeviceInput];
	}
	else {
		NSLog( @"Could not add audio device input to the session" );
	}

	// Add photo output.
	AVCapturePhotoOutput *photoOutput = [[AVCapturePhotoOutput alloc] init];
	if ( [self.captureSession canAddOutput:photoOutput] ) {
		[self.captureSession addOutput:photoOutput];
		//	self.photoOutput = photoOutput;
		//self.photoOutput.highResolutionCaptureEnabled = YES;
		//self.photoOutput.livePhotoCaptureEnabled = self.photoOutput.livePhotoCaptureSupported;
		//self.livePhotoMode = self.photoOutput.livePhotoCaptureSupported ? AVCamLivePhotoModeOn : AVCamLivePhotoModeOff;

		//self.inProgressPhotoCaptureDelegates = [NSMutableDictionary dictionary];
		//self.inProgressLivePhotoCapturesCount = 0;
	}
	else {
		NSLog( @"Could not add photo output to the session" );
		self.setupResult = AVCamSetupResultSessionConfigurationFailed;
		[self.captureSession commitConfiguration];
		return;
	}

	self.backgroundRecordingID = UIBackgroundTaskInvalid;

	[self.captureSession commitConfiguration];

	dispatch_async( self.sessionQueue, ^{
		AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];

		if ( [self.captureSession canAddOutput:movieFileOutput] )
		{
			[self.captureSession beginConfiguration];
			[self.captureSession addOutput:movieFileOutput];
			self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
			AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
			if ( connection.isVideoStabilizationSupported ) {
				connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
			}
			[self.captureSession commitConfiguration];

			self.movieFileOutput = movieFileOutput;
		}
	} );
	
}

- (void)addObservers {
	
//	[self.captureSession addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:SessionRunningContext];

	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDeviceInput.device];
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:self.captureSession];

	/*
		A session can only run when the app is full screen. It will be interrupted
		in a multi-app layout, introduced in iOS 9, see also the documentation of
		AVCaptureSessionInterruptionReason. Add observers to handle these session
		interruptions and show a preview is paused message. See the documentation
		of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
	 */
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:self.session];
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:self.session];
}

- (void)removeObservers {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self.captureSession removeObserver:self forKeyPath:@"running" context:SessionRunningContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ( context == SessionRunningContext ) {
//		BOOL isSessionRunning = [change[NSKeyValueChangeNewKey] boolValue];
		/*
		 BOOL livePhotoCaptureSupported = self.photoOutput.livePhotoCaptureSupported;
		 BOOL livePhotoCaptureEnabled = self.photoOutput.livePhotoCaptureEnabled;

		 dispatch_async( dispatch_get_main_queue(), ^{
			// Only enable the ability to change camera if the device has more than one camera.
			self.cameraButton.enabled = isSessionRunning && ( self.videoDeviceDiscoverySession.uniqueDevicePositionsCount > 1 );
			self.recordButton.enabled = isSessionRunning && ( self.captureModeControl.selectedSegmentIndex == AVCamCaptureModeMovie );
			self.photoButton.enabled = isSessionRunning;
			self.captureModeControl.enabled = isSessionRunning;
			self.livePhotoModeButton.enabled = isSessionRunning && livePhotoCaptureEnabled;
			self.livePhotoModeButton.hidden = ! ( isSessionRunning && livePhotoCaptureSupported );
		 } ); */
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
	/*
		Note that currentBackgroundRecordingID is used to end the background task
		associated with this recording. This allows a new recording to be started,
		associated with a new UIBackgroundTaskIdentifier, once the movie file output's
		`recording` property is back to NO — which happens sometime after this method
		returns.

		Note: Since we use a unique file path for each recording, a new recording will
		not overwrite a recording currently being saved.
	 */
	UIBackgroundTaskIdentifier currentBackgroundRecordingID = self.backgroundRecordingID;
	self.backgroundRecordingID = UIBackgroundTaskInvalid;

	dispatch_block_t cleanup = ^{
		if ( [[NSFileManager defaultManager] fileExistsAtPath:outputFileURL.path] ) {
			[[NSFileManager defaultManager] removeItemAtPath:outputFileURL.path error:NULL];
		}

		if ( currentBackgroundRecordingID != UIBackgroundTaskInvalid ) {
			[[UIApplication sharedApplication] endBackgroundTask:currentBackgroundRecordingID];
		}
	};

	BOOL success = YES;

	if ( error ) {
		NSLog( @"Movie file finishing error: %@", error );
		success = [error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] boolValue];
	}

	if (!success) {
		cleanup();
		return;
	}

	// Check authorization status.
	[PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
		if ( status == PHAuthorizationStatusAuthorized ) {
			// Save the movie file to the photo library and cleanup.
			[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
				PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
				options.shouldMoveFile = YES;
				PHAssetCreationRequest *creationRequest = [PHAssetCreationRequest creationRequestForAsset];
				[creationRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:outputFileURL options:options];
			} completionHandler:^( BOOL success, NSError *error ) {
				if ( ! success ) {
					NSLog( @"Could not save movie to photo library: %@", error );
				}
				cleanup();
			}];
		}
		else {
			cleanup();
		}
	}];
}

@end
