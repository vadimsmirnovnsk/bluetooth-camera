#import "BTRBluetoothControl.h"

@import CoreBluetooth;

@interface BTRBluetoothControl () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, assign) double toZoom;
@property (nonatomic, assign, readwrite) double currentTemperature;
@property (nonatomic, assign, readwrite) double currentZoom;
@property (nonatomic, strong) NSTimer *zoomTimer;
@property (nonatomic, assign) NSTimeInterval previousTimestamp;
@property (nonatomic, strong) NSMutableSet *peripherals;
@property (nonatomic, strong) NSMutableSet *services;
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong, readonly) CBUUID *serviceUUID;
@property (nonatomic, strong, readonly) CBUUID *characteristicUUID;

@end

@implementation BTRBluetoothControl

- (instancetype)init
{
	self = [super init];
	if (self == nil) return nil;

	_serviceUUID = [CBUUID UUIDWithString:@"E20A39F4-73F5-4BC4-A12F-17D1AD666661"];
	_characteristicUUID = [CBUUID UUIDWithString:@"08590F7E-DB05-467E-8757-72F6F66666D4"];
	_currentZoom = 1.0;
	_services = [NSMutableSet set];
	_peripherals = [NSMutableSet set];
	_centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];

	return self;
}


- (void)processValue:(NSString *)value
{
	NSArray<NSString *> *components = [value componentsSeparatedByString:@" "];
	if ([components.firstObject isEqualToString:@"zoom"]) {
		double zoomValue = [components.lastObject doubleValue];
		self.toZoom = zoomValue;
		[self startZoom];
	}
	else if ([components.firstObject isEqualToString:@"whiteBalance"]) {
		self.currentTemperature = [components.lastObject doubleValue];
		[self.delegate bluetoothControl:self didChangeTemperature:self.currentTemperature];
	}
	else if ([components.firstObject isEqualToString:@"takeVideo"]) {

		NSString *action = components.lastObject;
		if ([action isEqualToString:@"didTap"]) {
			[self.delegate bluetoothControl:self startRecord:YES];
		}
		else if ([action isEqualToString:@"didRelease"]) {
			[self.delegate bluetoothControl:self startRecord:NO];
		}
	}
	else if ([components.firstObject isEqualToString:@"toggleCamera"]) {
		[self.delegate bluetoothControlDidToggleCamera:self];
	}
}

- (void)startZoom
{
	// Старый убиваем
	[self.zoomTimer invalidate];

	// Здесь считаем динамически время, за которое нам надо зазумиться.
	// Оно должно быть или 0,5 секунды, или время между моментом сейчас и предыдущим прилётом значения
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	double time = MIN(0.5, now - self.previousTimestamp);
	self.previousTimestamp = now;

	double delta = (self.toZoom - self.currentZoom) / 20.0;

	self.zoomTimer = [NSTimer scheduledTimerWithTimeInterval:time / 20.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
		double newZoom = self.currentZoom + delta;
		if (delta > 0) {
			newZoom = newZoom > self.toZoom ? self.toZoom : newZoom;
		}
		else {
			newZoom = newZoom < self.toZoom ? self.toZoom : newZoom;
		}

		self.currentZoom = newZoom;
		[self.delegate bluetoothControl:self didChangeZoomValue:newZoom];

		if (newZoom == self.toZoom) {
			[timer invalidate];
		}

	}];
}

//39714B36-AA2F-46D8-B9DB-71446B343298
#pragma mark CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
	NSLog(@"didDiscoverServices>>%@", peripheral.services);

	if (peripheral.services.count > 0) {

		__block CBService *service = nil;
		[peripheral.services enumerateObjectsUsingBlock:^(CBService * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			if ([obj.UUID isEqual:self.serviceUUID]) {
				service = obj;
				*stop = YES;
			}
		}];

		if (service) {
			[self.services addObject:service];
			[peripheral discoverCharacteristics:@[ self.characteristicUUID ] forService:service];
		}

	}
}

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices {
	NSLog(@"didModifyServices>>%@", invalidatedServices);
	[invalidatedServices enumerateObjectsUsingBlock:^(CBService *invalidatedService, NSUInteger idx, BOOL *stop) {
		[self.services removeObject:invalidatedService];
	}];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
	NSLog(@"didDiscoverCharacteristicsForService>>%@, error>%@", service, error);
	CBCharacteristic *characteristic = service.characteristics.firstObject;
	if (characteristic) {
		[peripheral setNotifyValue:YES forCharacteristic:characteristic];
	}
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
	NSLog(@"didUpdateValueForCharacteristic>>%@", characteristic);
	NSString *value =  [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
	NSLog(@">>%@", value);
	[self processValue:value];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
	NSLog(@"didUpdateNotificationStateForCharacteristic>>%@, error>%@", characteristic, error);

	[peripheral readValueForCharacteristic:characteristic];
	NSLog(@">>%@", [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]);
	
}

#pragma mark CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
	if (central.state != CBManagerStatePoweredOn) return;

	[self.centralManager scanForPeripheralsWithServices:@[ self.serviceUUID ] options:nil];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {

	NSLog(@"didDiscoverPeripheral>>%@ %@", peripheral, advertisementData);
	if ([advertisementData[CBAdvertisementDataLocalNameKey] isEqualToString:@"Remote Control"]) {
		[self.peripherals addObject:peripheral];
		peripheral.delegate = self;
		[self.centralManager connectPeripheral:peripheral options:nil];
	}
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
	NSLog(@"didConnectPeripheral>>%@", peripheral);

	[peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
	NSLog(@"didFailToConnectPeripheral>>%@", peripheral);
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
	NSLog(@"didDisconnectPeripheral>>%@", peripheral);
	peripheral.delegate = nil;
	[self.peripherals removeObject:peripheral];
}

@end
