# Flutter VPN UI Demo

这是一个基于 Flutter 的 VPN 用户界面演示项目，实现了完整的用户流程和高级功能页面，采用现代极简风格。

## 功能特性

### 核心流程
- **欢迎页**: 品牌展示与引导。
- **登录/注册**: 完整的表单交互。
- **主页**: 核心连接功能、计时器、服务器选择。

### 高级功能
- **侧边栏菜单 (Drawer)**: 统一的导航入口，包含用户信息。
- **设置页面**: 
    - 协议选择 (IKEv2, WireGuard 等)。
    - Kill Switch 和 Split Tunneling 开关。
    - 深色模式和通知设置。
- **会员订阅页**:
    - 权益展示 (无广告、更快速)。
    - 套餐选择 (月付/年付) 卡片交互。

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── theme/
│   └── app_theme.dart        # 主题配置
├── pages/
│   ├── welcome_page.dart     # 欢迎页
│   ├── login_page.dart       # 登录页
│   ├── register_page.dart    # 注册页
│   ├── home_page.dart        # 主页
│   ├── settings_page.dart    # 设置页
│   └── premium_page.dart     # 会员订阅页
└── widgets/
    ├── connect_button.dart   # 连接按钮
    ├── server_card.dart      # 服务器卡片
    ├── custom_text_field.dart # 输入框
    └── navigation_drawer.dart # 侧边栏
```

## 运行方式

```bash
flutter run
```
