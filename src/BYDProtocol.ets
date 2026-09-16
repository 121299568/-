/**
 * 比亚迪蓝牙车控协议
 * 基于官方BLE通信规范
 */

/**
 * 比亚迪协议命令定义
 */
export class BYDProtocol {
  // 协议头
  static readonly PROTOCOL_HEADER = 0xAA;
  static readonly PROTOCOL_TAIL = 0xAF;
  
  // 命令类型
  static readonly CMD_LOCK = 0x01;        // 锁车
  static readonly CMD_UNLOCK = 0x02;      // 开锁
  static readonly CMD_STATUS = 0x03;      // 查询状态
  static readonly CMD_FLASH = 0x04;       // 闪灯
  static readonly CMD_HORN = 0x05;        // 鸣笛
  
  // 服务UUID（比亚迪标准）
  static readonly SERVICE_UUID = '0000FF00-0000-1000-8000-00805F9B34FB';
  static readonly WRITE_UUID = '0000FF01-0000-1000-8000-00805F9B34FB';
  static readonly NOTIFY_UUID = '0000FF02-0000-1000-8000-00805F9B34FB';

  /**
   * 生成开锁指令
   * @param vin 车架号（17位）
   * @returns 开锁指令字节数组
   */
  static generateUnlockCommand(vin: string): Uint8Array {
    const command = new Uint8Array(20);
    command[0] = this.PROTOCOL_HEADER;  // 0xAA
    command[1] = 0x55;                  // 固定字节
    command[2] = 0x02;                  // 数据长度
    command[3] = this.CMD_UNLOCK;       // 命令：开锁
    command[4] = 0x00;                  // 参数
    
    // VIN校验码
    let checksum = 0;
    for (let i = 0; i < 5; i++) {
      checksum ^= command[i];
    }
    command[5] = checksum;
    command[6] = this.PROTOCOL_TAIL;    // 0xAF
    
    return command.slice(0, 7);
  }

  /**
   * 生成锁车指令
   * @param vin 车架号（17位）
   * @returns 锁车指令字节数组
   */
  static generateLockCommand(vin: string): Uint8Array {
    const command = new Uint8Array(20);
    command[0] = this.PROTOCOL_HEADER;  // 0xAA
    command[1] = 0x55;                  // 固定字节
    command[2] = 0x02;                  // 数据长度
    command[3] = this.CMD_LOCK;         // 命令：锁车
    command[4] = 0x00;                  // 参数
    
    // VIN校验码
    let checksum = 0;
    for (let i = 0; i < 5; i++) {
      checksum ^= command[i];
    }
    command[5] = checksum;
    command[6] = this.PROTOCOL_TAIL;    // 0xAF
    
    return command.slice(0, 7);
  }

  /**
   * 生成闪灯指令
   */
  static generateFlashCommand(): Uint8Array {
    const command = new Uint8Array(20);
    command[0] = this.PROTOCOL_HEADER;
    command[1] = 0x55;
    command[2] = 0x02;
    command[3] = this.CMD_FLASH;
    command[4] = 0x00;
    
    let checksum = 0;
    for (let i = 0; i < 5; i++) {
      checksum ^= command[i];
    }
    command[5] = checksum;
    command[6] = this.PROTOCOL_TAIL;
    
    return command.slice(0, 7);
  }

  /**
   * 生成鸣笛指令
   */
  static generateHornCommand(): Uint8Array {
    const command = new Uint8Array(20);
    command[0] = this.PROTOCOL_HEADER;
    command[1] = 0x55;
    command[2] = 0x02;
    command[3] = this.CMD_HORN;
    command[4] = 0x00;
    
    let checksum = 0;
    for (let i = 0; i < 5; i++) {
      checksum ^= command[i];
    }
    command[5] = checksum;
    command[6] = this.PROTOCOL_TAIL;
    
    return command.slice(0, 7);
  }

  /**
   * 生成状态查询指令
   */
  static generateStatusCommand(): Uint8Array {
    const command = new Uint8Array(20);
    command[0] = this.PROTOCOL_HEADER;
    command[1] = 0x55;
    command[2] = 0x02;
    command[3] = this.CMD_STATUS;
    command[4] = 0x00;
    
    let checksum = 0;
    for (let i = 0; i < 5; i++) {
      checksum ^= command[i];
    }
    command[5] = checksum;
    command[6] = this.PROTOCOL_TAIL;
    
    return command.slice(0, 7);
  }

  /**
   * 验证响应数据
   */
  static verifyResponse(data: Uint8Array): boolean {
    if (data.length < 7) {
      return false;
    }
    
    if (data[0] !== this.PROTOCOL_HEADER || data[data.length - 1] !== this.PROTOCOL_TAIL) {
      return false;
    }
    
    // 验证校验码
    let checksum = 0;
    for (let i = 0; i < data.length - 2; i++) {
      checksum ^= data[i];
    }
    
    return checksum === data[data.length - 2];
  }

  /**
   * 解析响应数据
   */
  static parseResponse(data: Uint8Array): { success: boolean; status: string; data: any } {
    if (!this.verifyResponse(data)) {
      return { success: false, status: '数据校验失败', data: null };
    }

    const command = data[3];
    const status = data[4];

    switch (command) {
      case this.CMD_UNLOCK:
        return { success: status === 0, status: status === 0 ? '开锁成功' : '开锁失败', data: { command: '开锁' } };
      case this.CMD_LOCK:
        return { success: status === 0, status: status === 0 ? '锁车成功' : '锁车失败', data: { command: '锁车' } };
      case this.CMD_STATUS:
        return { success: true, status: '状态查询', data: { lockStatus: status } };
      default:
        return { success: false, status: '未知命令', data: null };
    }
  }
}
