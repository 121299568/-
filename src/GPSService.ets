import geoLocationManager from '@ohos.geoLocationManager';

/**
 * GPS定位服务
 * 实时获取设备位置信息
 */
export class GPSService {
  private static instance: GPSService;
  private locationCallback: (location: LocationInfo) => void = () => {};
  private isLocationEnabled: boolean = false;
  private locationTimer: number | null = null;

  private constructor() {
    this.initLocationService();
  }

  /**
   * 获取单例
   */
  static getInstance(): GPSService {
    if (!GPSService.instance) {
      GPSService.instance = new GPSService();
    }
    return GPSService.instance;
  }

  /**
   * 初始化定位服务
   */
  private initLocationService(): void {
    try {
      geoLocationManager.isLocationEnabled().then((enabled: boolean) => {
        this.isLocationEnabled = enabled;
        console.log(`定位服务状态: ${enabled ? '已启用' : '已禁用'}`);
      });
    } catch (err) {
      console.error('初始化定位服务失败:', err);
    }
  }

  /**
   * 启动位置监���
   */
  startLocationListener(callback: (location: LocationInfo) => void): void {
    this.locationCallback = callback;

    try {
      const requestInfo: geoLocationManager.CurrentLocationRequest = {
        priority: geoLocationManager.LocationRequestPriority.ACCURACY,
        scenario: geoLocationManager.LocationRequestScenario.UNSET,
        maxAccuracy: 100,
        timeoutMs: 10000
      };

      this.locationTimer = setInterval(() => {
        geoLocationManager.getCurrentLocation(requestInfo, (err: any, location: any) => {
          if (err) {
            console.error('获取位置失败:', err);
            return;
          }

          const locationInfo: LocationInfo = {
            latitude: location.latitude,
            longitude: location.longitude,
            altitude: location.altitude || 0,
            accuracy: location.accuracy || 0,
            speed: location.speed || 0,
            direction: location.direction || 0,
            timestamp: location.time || Date.now()
          };

          this.locationCallback(locationInfo);
          console.log(`位置更新: [${locationInfo.latitude}, ${locationInfo.longitude}]`);
        });
      }, 5000);
    } catch (err) {
      console.error('启动位置监听失败:', err);
    }
  }

  /**
   * 停止位置监听
   */
  stopLocationListener(): void {
    if (this.locationTimer !== null) {
      clearInterval(this.locationTimer);
      this.locationTimer = null;
    }
    console.log('位置监听已停止');
  }

  /**
   * 获取一次位置
   */
  getLocation(): Promise<LocationInfo> {
    return new Promise((resolve, reject) => {
      try {
        const requestInfo: geoLocationManager.CurrentLocationRequest = {
          priority: geoLocationManager.LocationRequestPriority.ACCURACY,
          scenario: geoLocationManager.LocationRequestScenario.UNSET,
          maxAccuracy: 100,
          timeoutMs: 10000
        };

        geoLocationManager.getCurrentLocation(requestInfo, (err: any, location: any) => {
          if (err) {
            reject(err);
            return;
          }

          const locationInfo: LocationInfo = {
            latitude: location.latitude,
            longitude: location.longitude,
            altitude: location.altitude || 0,
            accuracy: location.accuracy || 0,
            speed: location.speed || 0,
            direction: location.direction || 0,
            timestamp: location.time || Date.now()
          };

          resolve(locationInfo);
        });
      } catch (err) {
        reject(err);
      }
    });
  }

  /**
   * 检查定位服务是否启用
   */
  isEnabled(): boolean {
    return this.isLocationEnabled;
  }
}

/**
 * 位置信息接口
 */
export interface LocationInfo {
  latitude: number;
  longitude: number;
  altitude: number;
  accuracy: number;
  speed: number;
  direction: number;
  timestamp: number;
}
