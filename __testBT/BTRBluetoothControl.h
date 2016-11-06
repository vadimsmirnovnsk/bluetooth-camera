#import <Foundation/Foundation.h>

@protocol BTRBluetoothControlDelegate;

@interface BTRBluetoothControl : NSObject

@property (nonatomic, assign, readonly) double currentZoom;
@property (nonatomic, assign, readonly) double temperatureZoom;
@property (nonatomic, weak) id<BTRBluetoothControlDelegate> delegate;

@end

@protocol BTRBluetoothControlDelegate <NSObject>

- (void)bluetoothControlDidToggleCamera:(BTRBluetoothControl *)control;
- (void)bluetoothControl:(BTRBluetoothControl *)control didChangeZoomValue:(double)zoomValue;
- (void)bluetoothControl:(BTRBluetoothControl *)control didChangeTemperature:(double)temperature;
- (void)bluetoothControl:(BTRBluetoothControl *)control startRecord:(BOOL)start;

@end
