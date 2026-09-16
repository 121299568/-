import { BluetoothManager, DeviceInfo } from './BluetoothManager';
import { GeoFenceManager, ParkingLocation } from './GeoFenceManager';
import { BYDProtocol } from './BYDProtocol';

/**
 * 增强版解锁控制器
 * 集成围栏判断、位置记忆、后台扫描
 */
export class EnhancedUnlockController {
  private static instance: EnhancedUnlockController;
  private bluetoothManager: BluetoothManager;
  private geoFenceManager: GeoFenceManager;
  private settings: UnlockSettings;
  private isMonitoring: boolean = false;
  private monitoringTimer: number | null = null;
  private backgroundScanTimer: number | null = null;
  private lastUnlockTime: number = 0;
  private whitelistDevices: Set<string> = new Set();
  private unlockCallback: (success: boolean, message: string) => void = () => {};
  private statusCallback: (status: string) => void = () => {};
  private vin: string = '';
  private deviceId: string = '';
  private isBackgroundScanActive: boolean = false;

  private constructor() {
    this.bluetoothManager = BluetoothManager.getInstance();
    this.geoFenceManager = new GeoFenceManager();
    this.settings = {
      distanceThreshold: 3.0,
      rssiThreshold: -60,
      unlockCooldown: 5000,
      enableSecurity: true,
      enableGeofence: true,
      fenceRadius: 100,
      backgroundScanInterval: 30000, // 30秒后台扫描一次
      enableBackgroundScan: true
    };
  }

  /**
   * 获取单例
   */
  static getInstance(): EnhancedUnlockController {
    if (!EnhancedUnlockController.instance) {
      EnhancedUnlockController.instance = new EnhancedUnlockController();
    }
    return EnhancedUnlockController.instance;
  }

  /**
   * 初始化控制器
   */
  initialize(deviceId: string, vin: string): void {
    this.deviceId = deviceId;
    this.vin = vin;
    console.log(`控制器已初始化，VIN: ${vin}, 设备ID: ${deviceId}`);
  }

  /**
   * 锁车（记录停车位置）
   */
  lockCar(latitude: number, longitude: number, altitude?: number): void {
    if (!this.deviceId) {
      this.statusCallback('设备未连接');
      return;
    }

    // 发送锁车指令
    const lockCommand = BYDProtocol.generateLockCommand(this.vin);
    this.bluetoothManager.sendData(this.deviceId, lockCommand);

    // 记录停车位置
    this.geoFenceManager.setParkingLocation(latitude, longitude, altitude);

    this.statusCallback(`已锁车，停车位置已记录: [${latitude.toFixed(6)}, ${longitude.toFixed(6)}]`);
    this.unlockCallback(true, '锁车成功，位置已保存');

    // 锁车后启动后台扫描
    if (this.settings.enableBackgroundScan) {
      this.startBackgroundScan();
    }
  }

  /**
   * 开锁（基于接近检测或手动）
   */
  unlockCar(automatic: boolean = false): void {
    if (!this.deviceId) {
      this.statusCallback('设备未连接');
      return;
    }

    const now = Date.now();
    if (now - this.lastUnlockTime < this.settings.unlockCooldown) {
      this.statusCallback('解锁冷却中');
      return;
    }

    // 发送开锁指令
    const unlockCommand = BYDProtocol.generateUnlockCommand(this.vin);
    this.bluetoothManager.sendData(this.deviceId, unlockCommand);

    this.lastUnlockTime = now;
    const mode = automatic ? '自动接近' : '手动';
    this.statusCallback(`已${mode}开锁`);
    this.unlockCallback(true, `${mode}开锁成功`);

    // 开锁后停止后台扫描
    if (this.isBackgroundScanActive) {
      this.stopBackgroundScan();
    }
  }

  /**
   * 开始接近监控
   */
  startMonitoring(callback: (success: boolean, message: string) => void): void {
    this.unlockCallback = callback;
    this.isMonitoring = true;

    console.log('开始接近监控...');

    this.monitoringTimer = setInterval(() => {
      this.checkProximity();
    }, 500);
  }

  /**
   * 停止监控
   */
  stopMonitoring(): void {
    this.isMonitoring = false;
    if (this.monitoringTimer !== null) {
      clearInterval(this.monitoringTimer);
      this.monitoringTimer = null;
    }
    console.log('监控已停止');
  }

  /**
   * 启动后台扫描（锁车后持续扫描）
   */
  private startBackgroundScan(): void {
    if (this.isBackgroundScanActive) {
      return;
    }

    this.isBackgroundScanActive = true;
    console.log('后台扫描已启动');
    this.statusCallback('已启动后台扫描');

    this.backgroundScanTimer = setInterval(() => {
      this.performBackgroundScan();
    }, this.settings.backgroundScanInterval);
  }

  /**
   * 停止后台扫描
   */
  private stopBackgroundScan(): void {
    if (this.backgroundScanTimer !== null) {
      clearInterval(this.backgroundScanTimer);
      this.backgroundScanTimer = null;
    }
    this.isBackgroundScanActive = false;
    console.log('后台扫描已停止');
    this.statusCallback('后台扫���已停止');
  }

  /**
   * 执行后台扫描
   */
  private performBackgroundScan(): void {
    const parkingLocation = this.geoFenceManager.getParkingLocation();
    if (!parkingLocation) {
      return;
    }

    console.log(`执行后台扫描，停车位置: [${parkingLocation.latitude}, ${parkingLocation.longitude}]`);

    // 这里集成GPS模块进行位置检测
    // 示例：假设获得当前位置
    // const currentLocation = await this.getCurrentLocation();
    
    // if (currentLocation && this.geoFenceManager.isInsideGeofence(currentLocation.latitude, currentLocation.longitude)) {
    //   const moved = this.geoFenceManager.checkMovement(currentLocation.latitude, currentLocation.longitude);
    //   if (moved) {
    //     console.log('在围栏内检测到移动，启动活跃监控');
    //     this.startActiveMonitoring();
    //   }
    // }
  }

  /**
   * 启动活跃监控（在围栏内移动后）
   */
  private startActiveMonitoring(): void {
    if (this.isMonitoring) {
      return;
    }

    console.log('启动活跃监控...');
    this.startMonitoring((success, message) => {
      this.statusCallback(message);
    });
  }

  /**
   * 检查接近情况
   */
  private checkProximity(): void {
    if (!this.isMonitoring) {
      return;
    }

    const connectedDevices = this.bluetoothManager.getConnectedDevices();

    for (const device of connectedDevices) {
      // 检查白名单
      if (!this.isWhitelisted(device.deviceId)) {
        continue;
      }

      // 检查距离和RSSI
      if (device.distance <= this.settings.distanceThreshold && device.rssi >= this.settings.rssiThreshold) {
        this.triggerUnlock(device);
        return;
      }
    }
  }

  /**
   * 触发自动解锁
   */
  private triggerUnlock(device: DeviceInfo): void {
    if (!this.verifyDevice(device)) {
      this.unlockCallback(false, '设备验证失败');
      return;
    }

    this.unlockCar(true);
  }

  /**
   * 验证设备
   */
  private verifyDevice(device: DeviceInfo): boolean {
    if (!device.deviceId || device.rssi === 0) {
      return false;
    }

    if (device.rssi < this.settings.rssiThreshold) {
      return false;
    }

    if (device.distance > this.settings.distanceThreshold) {
      return false;
    }

    return true;
  }

  /**
   * 添加白名单
   */
  addWhitelistDevice(deviceId: string): void {
    this.whitelistDevices.add(deviceId);
    console.log(`设备 ${deviceId} 已添加到白名单`);
  }

  /**
   * 检查白名单
   */
  private isWhitelisted(deviceId: string): boolean {
    if (!this.settings.enableSecurity) {
      return true;
    }
    return this.whitelistDevices.has(deviceId);
  }

  /**
   * 更新设置
   */
  updateSettings(settings: Partial<UnlockSettings>): void {
    this.settings = { ...this.settings, ...settings };
    
    if (settings.fenceRadius) {
      this.geoFenceManager.setFenceRadius(settings.fenceRadius);
    }
    
    console.log('设置已更新:', this.settings);
  }

  /**
   * 获取设置
   */
  getSettings(): UnlockSettings {
    return this.settings;
  }

  /**
   * 获取围栏状态
   */
  getFenceStatus() {
    return this.geoFenceManager.getFenceStatus();
  }

  /**
   * 获取监控状态
   */
  getStatus(): {
    isMonitoring: boolean;
    isBackgroundScanActive: boolean;
    fenceStatus: any;
    connectedDevices: number;
  } {
    return {
      isMonitoring: this.isMonitoring,
      isBackgroundScanActive: this.isBackgroundScanActive,
      fenceStatus: this.geoFenceManager.getFenceStatus(),
      connectedDevices: this.bluetoothManager.getConnectedDevices().length
    };
  }

  /**
   * 设置状态回调
   */
  setStatusCallback(callback: (status: string) => void): void {
    this.statusCallback = callback;
  }

  /**
   * 闪灯功能
   */
  flashLights(): void {
    const flashCommand = BYDProtocol.generateFlashCommand();
    this.bluetoothManager.sendData(this.deviceId, flashCommand);
    this.statusCallback('闪灯指令已发送');
  }

  /**
   * 鸣笛功能
   */
  soundHorn(): void {
    const hornCommand = BYDProtocol.generateHornCommand();
    this.bluetoothManager.sendData(this.deviceId, hornCommand);
    this.statusCallback('鸣笛指令已发送');
  }
}

/**
 * 解锁设置接口
 */
export interface UnlockSettings {
  distanceThreshold: number;
  rssiThreshold: number;
  unlockCooldown: number;
  enableSecurity: boolean;
  enableGeofence: boolean;
  fenceRadius: number;
  backgroundScanInterval: number;
  enableBackgroundScan: boolean;
}
