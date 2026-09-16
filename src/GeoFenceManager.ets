/**
 * 地理围栏管理器
 * 处理停车位置记忆和围栏判断
 */
export class GeoFenceManager {
  private parkingLocation: ParkingLocation | null = null;
  private fenceRadius: number = 100; // 默认围栏半径：100米
  private isInsideFence: boolean = false;
  private lastKnownLocation: Location | null = null;
  private movementThreshold: number = 5; // 移动判断阈值：5米
  private movementCallback: (moved: boolean) => void = () => {};

  /**
   * 设置停车位置
   */
  setParkingLocation(latitude: number, longitude: number, altitude?: number): void {
    this.parkingLocation = {
      latitude,
      longitude,
      altitude: altitude || 0,
      timestamp: Date.now(),
      accuracy: 5.0 // 默认精度5米
    };
    this.isInsideFence = true;
    console.log(`停车位置已记录: [${latitude}, ${longitude}]`);
  }

  /**
   * 获取停车位置
   */
  getParkingLocation(): ParkingLocation | null {
    return this.parkingLocation;
  }

  /**
   * 设置围栏半径
   */
  setFenceRadius(radius: number): void {
    this.fenceRadius = radius;
    console.log(`围栏半径已设置为: ${radius}米`);
  }

  /**
   * 获取围栏半径
   */
  getFenceRadius(): number {
    return this.fenceRadius;
  }

  /**
   * 检查当前位置是否在围栏内
   */
  isInsideGeofence(latitude: number, longitude: number): boolean {
    if (!this.parkingLocation) {
      return false;
    }

    const distance = this.calculateDistance(
      this.parkingLocation.latitude,
      this.parkingLocation.longitude,
      latitude,
      longitude
    );

    this.isInsideFence = distance <= this.fenceRadius;
    return this.isInsideFence;
  }

  /**
   * 检测是否移动
   * 返回true表示在围栏内且移动超过阈值
   */
  checkMovement(latitude: number, longitude: number): boolean {
    if (!this.isInsideGeofence(latitude, longitude)) {
      return false; // 已超出围栏
    }

    if (!this.lastKnownLocation) {
      this.lastKnownLocation = { latitude, longitude };
      return false;
    }

    const distance = this.calculateDistance(
      this.lastKnownLocation.latitude,
      this.lastKnownLocation.longitude,
      latitude,
      longitude
    );

    const moved = distance >= this.movementThreshold;

    if (moved) {
      console.log(`检测到移动: ${distance.toFixed(2)}米`);
      this.lastKnownLocation = { latitude, longitude };
      this.movementCallback(true);
    }

    return moved;
  }

  /**
   * 设置移动回调
   */
  setMovementCallback(callback: (moved: boolean) => void): void {
    this.movementCallback = callback;
  }

  /**
   * 计算两点之间的距离（米）
   * 使用Haversine公式
   */
  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371000; // 地球半径（米）
    const φ1 = (lat1 * Math.PI) / 180;
    const φ2 = (lat2 * Math.PI) / 180;
    const Δφ = ((lat2 - lat1) * Math.PI) / 180;
    const Δλ = ((lon2 - lon1) * Math.PI) / 180;

    const a =
      Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
      Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c;
  }

  /**
   * 获取当前围栏状态
   */
  getFenceStatus(): FenceStatus {
    return {
      isInsideFence: this.isInsideFence,
      parkingLocation: this.parkingLocation,
      fenceRadius: this.fenceRadius,
      distanceToParkingLocation: this.parkingLocation && this.lastKnownLocation
        ? this.calculateDistance(
            this.parkingLocation.latitude,
            this.parkingLocation.longitude,
            this.lastKnownLocation.latitude,
            this.lastKnownLocation.longitude
          )
        : 0
    };
  }

  /**
   * 清空停车位置
   */
  clearParkingLocation(): void {
    this.parkingLocation = null;
    this.lastKnownLocation = null;
    this.isInsideFence = false;
    console.log('停车位置已清空');
  }
}

/**
 * 停车位置信息
 */
export interface ParkingLocation {
  latitude: number;
  longitude: number;
  altitude: number;
  timestamp: number;
  accuracy: number;
}

/**
 * 位置信息
 */
export interface Location {
  latitude: number;
  longitude: number;
}

/**
 * 围栏状态
 */
export interface FenceStatus {
  isInsideFence: boolean;
  parkingLocation: ParkingLocation | null;
  fenceRadius: number;
  distanceToParkingLocation: number;
}
