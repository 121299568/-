import bluetooth from '@ohos.bluetooth';
import { BusinessError } from '@ohos.base';

/**
 * 蓝牙管理器
 * 负责蓝牙设备的扫描、连接、通信
 */
export class BluetoothManager {
  private static instance: BluetoothManager;
  private bluetoothAdapter: bluetooth.BluetoothCentralManager | null = null;
  private connectedDevices: Map<string, DeviceInfo> = new Map();
  private scanCallback: (devices: DeviceInfo[]) => void = () => {};
  private connectionCallback: (device: DeviceInfo, connected: boolean) => void = () => {};

  private constructor() {
    this.initBluetooth();
  }

  /**
   * 获取单例
   */
  static getInstance(): BluetoothManager {
    if (!BluetoothManager.instance) {
      BluetoothManager.instance = new BluetoothManager();
    }
    return BluetoothManager.instance;
  }

  /**
   * 初始化蓝牙适配器
   */
  private initBluetooth(): void {
    try {
      this.bluetoothAdapter = bluetooth.createBLECentralManager();
      console.log('蓝牙适配器初始化成功');
    } catch (err) {
      console.error('蓝牙初始化失败:', err);
    }
  }

  /**
   * 开始扫描蓝牙设备
   */
  startScan(callback: (devices: DeviceInfo[]) => void): void {
    this.scanCallback = callback;
    
    if (!this.bluetoothAdapter) {
      console.error('蓝牙适配器未初始化');
      return;
    }

    try {
      // 设置扫描参数
      const scanOptions: bluetooth.ScanOptions = {
        interval: 100, // 扫描间隔(ms)
        window: 50,    // 扫描窗口(ms)
        dutyMode: bluetooth.ScanDuty.SCAN_MODE_LOW_POWER
      };

      this.bluetoothAdapter.on('BLEDeviceFind', (data: bluetooth.ScanResult[]) => {
        data.forEach(result => {
          const device: DeviceInfo = {
            deviceId: result.deviceId,
            deviceName: result.deviceName || '未知设备',
            rssi: result.rssi,
            distance: this.calculateDistance(result.rssi),
            services: result.serviceUuids || [],
            timestamp: Date.now()
          };
          
          callback([device]);
        });
      });

      this.bluetoothAdapter.startBLEScan([], scanOptions, (err: BusinessError) => {
        if (err) {
          console.error('扫描失败:', err);
        } else {
          console.log('蓝牙扫描已启动');
        }
      });
    } catch (err) {
      console.error('启动扫描异常:', err);
    }
  }

  /**
   * 停止扫描
   */
  stopScan(): void {
    if (this.bluetoothAdapter) {
      try {
        this.bluetoothAdapter.stopBLEScan((err: BusinessError) => {
          if (err) {
            console.error('停止扫描失败:', err);
          } else {
            console.log('蓝牙扫描已停止');
          }
        });
        this.bluetoothAdapter.off('BLEDeviceFind');
      } catch (err) {
        console.error('停止扫描异常:', err);
      }
    }
  }

  /**
   * 连接蓝牙设备
   */
  connectDevice(deviceId: string): void {
    if (!this.bluetoothAdapter) {
      console.error('蓝牙适配器未初始化');
      return;
    }

    try {
      const options: bluetooth.BLEConnectOptions = {
        autoConnect: true,
        serviceUuids: []
      };

      this.bluetoothAdapter.on('BLEConnectionStateChange', (data: bluetooth.BLEConnectionChangeState) => {
        if (data.deviceId === deviceId) {
          const isConnected = data.state === bluetooth.ProfileConnectionState.STATE_CONNECTED;
          console.log(`设备 ${deviceId} 连接状态: ${isConnected}`);
          
          if (isConnected) {
            this.connectedDevices.set(deviceId, {
              deviceId: deviceId,
              deviceName: '已连接设备',
              rssi: 0,
              distance: 0,
              services: [],
              timestamp: Date.now()
            });
          } else {
            this.connectedDevices.delete(deviceId);
          }
          
          this.connectionCallback({ deviceId, deviceName: '', rssi: 0, distance: 0, services: [], timestamp: Date.now() }, isConnected);
        }
      });

      this.bluetoothAdapter.connect(deviceId, options, (err: BusinessError) => {
        if (err) {
          console.error('连接失败:', err);
        } else {
          console.log('设备连接请求已发送');
        }
      });
    } catch (err) {
      console.error('连接异常:', err);
    }
  }

  /**
   * 断开蓝牙连接
   */
  disconnectDevice(deviceId: string): void {
    if (!this.bluetoothAdapter) {
      return;
    }

    try {
      this.bluetoothAdapter.disconnect(deviceId, (err: BusinessError) => {
        if (err) {
          console.error('断开连接失败:', err);
        } else {
          console.log('设备已断开连接');
          this.connectedDevices.delete(deviceId);
        }
      });
      this.bluetoothAdapter.off('BLEConnectionStateChange');
    } catch (err) {
      console.error('断开连接异常:', err);
    }
  }

  /**
   * 根据RSSI计算距离（米）
   * 公式: distance = 10 ^ ((RSSI - txPower) / (10 * n))
   * txPower: 发射功率（通常-59dBm）
   * n: 传播常数（通常2.0-4.0，环境越复杂值越大）
   */
  private calculateDistance(rssi: number): number {
    const txPower = -59;  // 标准发射功率
    const n = 2.0;        // 传播常数
    
    if (rssi === 0) {
      return -1.0;
    }

    const ratio = rssi * 1.0 / txPower;
    if (ratio < 1.0) {
      return Math.pow(ratio, 10);
    } else {
      return 0.89976 * Math.pow(ratio, 7.7095) + 0.111;
    }
  }

  /**
   * 获取已连接设备列表
   */
  getConnectedDevices(): DeviceInfo[] {
    return Array.from(this.connectedDevices.values());
  }

  /**
   * 设置连接状态回调
   */
  setConnectionCallback(callback: (device: DeviceInfo, connected: boolean) => void): void {
    this.connectionCallback = callback;
  }

  /**
   * 发送数据到设备
   */
  sendData(deviceId: string, data: Uint8Array): void {
    // 后续实现特征值写入
    console.log(`发送数据到设备 ${deviceId}:`, data);
  }
}

/**
 * 设备信息接口
 */
export interface DeviceInfo {
  deviceId: string;
  deviceName: string;
  rssi: number;
  distance: number;
  services: string[];
  timestamp: number;
}
