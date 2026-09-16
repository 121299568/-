import { BluetoothManager, DeviceInfo } from './BluetoothManager';
import { EnhancedUnlockController } from './EnhancedUnlockController';

@Entry
@Component
struct Index {
  @State message: string = '比亚迪接近解锁系统';
  @State bluetoothEnabled: boolean = false;
  @State isScanning: boolean = false;
  @State isMonitoring: boolean = false;
  @State devices: DeviceInfo[] = [];
  @State selectedDevice: DeviceInfo | null = null;
  @State statusMessage: string = '就绪';
  @State distanceThreshold: number = 3.0;
  @State rssiThreshold: number = -60;
  @State fenceRadius: number = 100;
  @State isLocked: boolean = true;
  @State parkingLocation: string = '未记录';
  @State fenceStatus: string = '围栏外';

  private bluetoothManager: BluetoothManager = BluetoothManager.getInstance();
  private unlockController: EnhancedUnlockController = EnhancedUnlockController.getInstance();

  build() {
    Column({ space: 15 }) {
      // 标题
      Text(this.message)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding(20)
        .backgroundColor('#E63946')
        .fontColor(Color.White)

      // 车辆状态卡片
      Column({ space: 10 }) {
        Row({ space: 15 }) {
          Column({ space: 5 }) {
            Text('车辆锁定状态')
              .fontSize(12)
              .fontColor('#999')
            Text(this.isLocked ? '已锁定' : '已解锁')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isLocked ? '#F44336' : '#4CAF50')
          }
          .width('33%')

          Column({ space: 5 }) {
            Text('围栏状态')
              .fontSize(12)
              .fontColor('#999')
            Text(this.fenceStatus)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2196F3')
          }
          .width('33%')

          Column({ space: 5 }) {
            Text('监控状态')
              .fontSize(12)
              .fontColor('#999')
            Text(this.isMonitoring ? '监控中' : '已停止')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isMonitoring ? '#4CAF50' : '#999')
          }
          .width('34%')
        }
        .width('100%')
        .height(90)
      }
      .width('100%')
      .padding(15)
      .backgroundColor('#F5F5F5')
      .borderRadius(8)

      // 停车位置信息
      Column({ space: 5 }) {
        Text('停车位置')
          .fontSize(12)
          .fontColor('#999')
        Text(this.parkingLocation)
          .fontSize(14)
          .fontColor('#333')
          .width('100%')
          .padding(10)
          .backgroundColor('#E3F2FD')
          .borderRadius(5)
      }
      .width('100%')

      // 主要控制按钮
      Row({ space: 10 }) {
        Button(this.isLocked ? '开锁' : '锁车')
          .onClick(() => this.toggleLock())
          .backgroundColor(this.isLocked ? '#4CAF50' : '#FF9800')
          .width('50%')
          .height(45)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)

        Column({ space: 5 }) {
          Button('闪灯')
            .onClick(() => this.flashLights())
            .backgroundColor('#2196F3')
            .width('100%')
            .height(20)
            .fontSize(12)

          Button('鸣笛')
            .onClick(() => this.soundHorn())
            .backgroundColor('#9C27B0')
            .width('100%')
            .height(20)
            .fontSize(12)
        }
        .width('48%')
      }
      .width('100%')

      // 参数设置
      Column({ space: 10 }) {
        Text('系统设置')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)

        Row({ space: 10 }) {
          Text('距离阈值:')
            .width('30%')
          Slider({ value: this.distanceThreshold, min: 1, max: 10, step: 0.5 })
            .width('55%')
            .onChange((value: number) => {
              this.distanceThreshold = value;
              this.unlockController.updateSettings({ distanceThreshold: value });
            })
          Text(`${this.distanceThreshold.toFixed(1)}m`)
            .width('15%')
            .fontSize(12)
        }

        Row({ space: 10 }) {
          Text('围栏半径:')
            .width('30%')
          Slider({ value: this.fenceRadius, min: 50, max: 500, step: 10 })
            .width('55%')
            .onChange((value: number) => {
              this.fenceRadius = value;
              this.unlockController.updateSettings({ fenceRadius: value });
            })
          Text(`${this.fenceRadius.toFixed(0)}m`)
            .width('15%')
            .fontSize(12)
        }

        Row({ space: 10 }) {
          Text('RSSI阈值:')
            .width('30%')
          Slider({ value: this.rssiThreshold + 100, min: 40, max: 100, step: 1 })
            .width('55%')
            .onChange((value: number) => {
              this.rssiThreshold = value - 100;
              this.unlockController.updateSettings({ rssiThreshold: this.rssiThreshold });
            })
          Text(`${this.rssiThreshold}dBm`)
            .width('15%')
            .fontSize(12)
        }
      }
      .width('100%')
      .padding(10)
      .border({ width: 1, color: '#DDD' })
      .borderRadius(5)

      // 设备列表
      Row({ space: 10 }) {
        Text(`蓝牙设备 (${this.devices.length})`)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .flexGrow(1)

        Button(this.isScanning ? '停止扫描' : '开始扫描')
          .onClick(() => this.toggleScan())
          .backgroundColor(this.isScanning ? '#F44336' : '#2196F3')
          .width('30%')
          .height(30)
          .fontSize(12)
      }
      .width('100%')

      List({ space: 6 }) {
        ForEach(this.devices, (device: DeviceInfo) => {
          ListItem() {
            Column({ space: 5 }) {
              Row({ space: 10 }) {
                Column({ space: 3 }) {
                  Text(device.deviceName)
                    .fontSize(13)
                    .fontWeight(FontWeight.Bold)
                  Text(`ID: ${device.deviceId.substring(0, 10)}...`)
                    .fontSize(10)
                    .fontColor('#999')
                }
                .flexGrow(1)

                Column({ space: 3 }) {
                  Text(`${device.distance.toFixed(2)}m`)
                    .fontSize(12)
                    .fontColor(device.distance <= this.distanceThreshold ? '#4CAF50' : '#FF9800')
                    .fontWeight(FontWeight.Bold)
                  Text(`${device.rssi}dBm`)
                    .fontSize(10)
                    .fontColor('#2196F3')
                }
              }
              .width('100%')

              if (this.selectedDevice?.deviceId === device.deviceId) {
                Text('✓ 已连接')
                  .fontSize(11)
                  .fontColor('#4CAF50')
                  .fontWeight(FontWeight.Bold)
              } else {
                Button('连接')
                  .width('100%')
                  .height(30)
                  .fontSize(12)
                  .onClick(() => this.connectDevice(device))
              }
            }
            .width('100%')
            .padding(10)
            .backgroundColor(this.selectedDevice?.deviceId === device.deviceId ? '#E8F5E9' : '#F9F9F9')
            .borderRadius(5)
          }
        }, (device: DeviceInfo) => device.deviceId)
      }
      .width('100%')
      .height('auto')
      .layoutWeight(1)

      // 状态提示
      Text(this.statusMessage)
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
        .padding(10)
        .textAlign(TextAlign.Center)
        .backgroundColor('#E3F2FD')
        .borderRadius(5)
    }
    .width('100%')
    .height('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .scroll(ScrollDirection.Vertical)
  }

  /**
   * 切换锁定状态
   */
  toggleLock(): void {
    if (this.isLocked) {
      this.unlockController.unlockCar(false);
      this.isLocked = false;
      this.statusMessage = '已开锁';
    } else {
      // 获取当前位置并锁车
      this.unlockController.lockCar(39.9042, 116.4074); // 示例坐标
      this.isLocked = true;
      this.parkingLocation = '[39.9042, 116.4074]';
      this.statusMessage = '已锁车，停车位置已记录';
    }
  }

  /**
   * 切换扫描状态
   */
  toggleScan(): void {
    if (this.isScanning) {
      this.bluetoothManager.stopScan();
      this.isScanning = false;
      this.statusMessage = '扫描已停止';
    } else {
      this.isScanning = true;
      this.statusMessage = '正在扫描周围设备...';
      this.bluetoothManager.startScan((device: DeviceInfo) => {
        const index = this.devices.findIndex(d => d.deviceId === device.deviceId);
        if (index >= 0) {
          this.devices[index] = device;
        } else {
          this.devices.push(device);
        }
      });
    }
  }

  /**
   * 连接设备
   */
  connectDevice(device: DeviceInfo): void {
    this.selectedDevice = device;
    this.unlockController.addWhitelistDevice(device.deviceId);
    this.unlockController.initialize(device.deviceId, 'LSVEB50A1D1234567');
    this.bluetoothManager.connectDevice(device.deviceId);
    this.statusMessage = `已连接到 ${device.deviceName}`;
  }

  /**
   * 闪灯
   */
  flashLights(): void {
    this.unlockController.flashLights();
    this.statusMessage = '闪灯指令已发送';
  }

  /**
   * 鸣笛
   */
  soundHorn(): void {
    this.unlockController.soundHorn();
    this.statusMessage = '鸣笛指令已发送';
  }
}
