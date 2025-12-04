# XiaoV2B Client - V2Board 客户端

一个基于 Flutter 开发的跨平台 V2Board VPN 客户端，已对接完整 API。

![动画](https://github.com/user-attachments/assets/d3711d6b-e5a8-463a-afe3-8385de55f536)

## ⚠️ 重要说明

- ✅ **全部代码由 AI 代写**
- ⚠️ **节点列表目前根据订阅连接获取，二开之前记得修改为读取本地配置文件**

## 📱 支持平台

- ✅ Windows
- ✅ macOS  
- ✅ Linux
- ✅ Android
- ✅ iOS

## 🚀 主要功能

### 核心功能
- 用户登录/注册
- 订阅管理
- 节点选择与切换
- 流量记录
- 订阅套餐购买
- 邀请码系统
- 工单系统
- 公告通知

### OSS 动态配置
OSS 配置见另一个仓库：[APIOSS](https://github.com/sunyuchentrx/APIOSS)

OSS 预设了以下功能：
- 邀请连接单独 URL
- 轮询 API 地址
- 动态加载商品 ID
- 应用版本检测与更新

## 🔧 技术栈

- **框架**: Flutter 3.x
- **状态管理**: Provider
- **网络请求**: Dio
- **本地存储**: SharedPreferences
- **UI设计**: Glassmorphism 风格
- **图标生成**: flutter_launcher_icons

## 📦 配置说明

### OSS 配置

在 `lib/services/config_service.dart` 中配置 OSS URL：

```dart
final List<String> _ossUrls = [
  'https://raw.githubusercontent.com/sunyuchentrx/APIOSS/refs/heads/main/api.txt',
  'https://your-backup-url.com/config.txt'  // 备用地址
];
```

### 应用信息配置

在 `build_config.yaml` 中修改应用信息：

```yaml
app_name: "学习强国"              # 应用显示名称
process_name: "xuexi"            # 进程名称（exe文件名）
package_name: "com.xuexi.app"    # 包名
```

### Logo 替换

将您的 logo.png 放置在以下位置：
- 主 Logo: `assets/images/logo.png`
- macOS Logo (可选): `assets/images/logo/logo_mac.png`

然后运行：
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

## 🛠️ 编译指南

### 环境要求
- Flutter SDK >= 3.10.1
- Dart SDK >= 3.10.1

### Windows
```bash
flutter build windows --release
```

### Android
```bash
flutter build apk --release
```

### macOS
```bash
flutter build macos --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 📁 项目结构

```
lib/
├── main.dart                    # 应用入口
├── models/                      # 数据模型
│   └── app_config.dart         # 应用配置模型
├── pages/                       # 页面
│   ├── welcome_page.dart       # 欢迎页
│   ├── login_page.dart         # 登录页
│   ├── register_page.dart      # 注册页
│   ├── home_page.dart          # 主页
│   ├── premium_page.dart       # 套餐购买页
│   └── ...
├── providers/                   # 状态管理
│   └── language_provider.dart  # 语言切换
├── services/                    # 服务层
│   ├── api_service.dart        # API 服务
│   └── config_service.dart     # 配置服务（OSS）
├── theme/                       # 主题
│   └── app_theme.dart          # 应用主题配置
└── widgets/                     # 通用组件
    ├── connect_button.dart     # 连接按钮
    ├── server_card.dart        # 服务器卡片
    └── ...
```

## 🔐 API 对接

项目已完整对接 V2Board API，包括：

- ✅ 用户认证（登录/注册/重置密码）
- ✅ 订阅管理（获取订阅信息/流量统计）
- ✅ 节点获取
- ✅ 套餐购买
- ✅ 订单管理
- ✅ 工单系统
- ✅ 公告系统
- ✅ 邀请码系统

具体 API 实现见 `lib/services/api_service.dart`

## 📝 待优化项

- [ ] 修复订阅获取方式
- [ ] 改为读取本地配置文件获取节点列表
- [ ] 实现节点延迟测试（Ping）
- [ ] 实现真实的 VPN 连接功能
- [ ] 优化错误处理
- [ ] 添加自动重连机制

## 🤝 贡献

本项目由[Antigravity操盘手孙宇晨开发](https://t.me/sunyuchentrx)

感谢[胖~](https://t.me/panghu_code) 的开源项目提供的API

🚀项目交流群： [胖虎妙妙屋](https://t.me/panghu_dev)

🚀机场主都在看的频道：[机场观察](https://t.me/jichangguancha)


## 📄 许可证

本项目仅供学习交流使用

## 🔗 相关项目

- OSS 配置仓库: [APIOSS](https://github.com/sunyuchentrx/APIOSS)
- V2Board 后端: [xiaov2board](https://github.com/wyx2685/v2board)

---

**注意**: 本项目全部代码由 AI 生成，使用前请仔细测试并根据实际需求调整（README也是AI写的）。
