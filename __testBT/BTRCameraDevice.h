#import <Foundation/Foundation.h>

typedef NS_ENUM( NSInteger, AVCamSetupResult ) {
	AVCamSetupResultSuccess,
	AVCamSetupResultCameraNotAuthorized,
	AVCamSetupResultSessionConfigurationFailed
};

@import AVFoundation;

@protocol BTRCameraDeviceDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface BTRCameraDevice : NSObject

@property (nonatomic, assign) double zoom;
@property (nonatomic, assign) double temperature;
@property (nonatomic, assign, readonly, getter=isRecording) BOOL recording;

@property (nonatomic, weak) id<BTRCameraDeviceDelegate> delegate;
@property (nonatomic, strong, readonly) AVCaptureSession *captureSession;

- (void)toggleMovieRecordingWithOrientation:(AVCaptureVideoOrientation)orientation;
- (void)setupWithResultBlock:(void (^)(AVCamSetupResult))block;
- (void)requestPermission;
- (void)changeCamera;

@end

@protocol BTRCameraDeviceDelegate <NSObject>

- (void)cameraDevice:(BTRCameraDevice *)cameraDevice didChangeVideoOrientation:(AVCaptureVideoOrientation)videoOrientation;

@end

NS_ASSUME_NONNULL_END
