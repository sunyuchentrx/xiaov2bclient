class AppConfig {
  final List<String> domains;
  final Map<String, String> versions;
  final String downloadUrl;
  final String updateNotes;
  final String apiPath;
  final String appDescription;
  final String inviteUrl;
  final UiControl uiControl;
  final ShopConfig? shopConfig;
  final List<String> shopIds;
  final String? imagebedApi;
  final List<String> emailSuffix;

  AppConfig({
    required this.domains,
    required this.versions,
    required this.downloadUrl,
    required this.updateNotes,
    required this.apiPath,
    required this.appDescription,
    required this.inviteUrl,
    required this.uiControl,
    this.shopConfig,
    this.shopIds = const [],
    this.imagebedApi,
    this.emailSuffix = const [],
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      domains: List<String>.from(json['domain'] ?? []),
      versions: Map<String, String>.from(json['version'] ?? {}),
      downloadUrl: json['download'] ?? '',
      updateNotes: json['notes'] ?? '',
      apiPath: json['api_path'] ?? '',
      appDescription: json['app_description'] ?? '',
      inviteUrl: json['invite_url'] ?? '',
      uiControl: UiControl.fromJson(json['ui_control'] ?? {}),
      shopConfig: json['shop_conf'] != null ? ShopConfig.fromJson(json['shop_conf']) : null,
      shopIds: List<String>.from(json['shop_id'] ?? []),
      imagebedApi: json['imagebed_api'],
      emailSuffix: List<String>.from(json['email_whitelist_suffix'] ?? []),
    );
  }
}

class UiControl {
  final bool goWebsite;
  final bool goGiftCard;
  final bool goTraffic;
  final bool onCelebrationOnConnection;

  UiControl({
    this.goWebsite = false,
    this.goGiftCard = false,
    this.goTraffic = false,
    this.onCelebrationOnConnection = false,
  });

  factory UiControl.fromJson(Map<String, dynamic> json) {
    return UiControl(
      goWebsite: json['go_website'] ?? false,
      goGiftCard: json['go_gift_card'] ?? false,
      goTraffic: json['go_traffic'] ?? false,
      onCelebrationOnConnection: json['on_celebration_on_connection'] ?? false,
    );
  }
}

class ShopConfig {
  final List<ShopTopTip> shopTopTips;

  ShopConfig({required this.shopTopTips});

  factory ShopConfig.fromJson(Map<String, dynamic> json) {
    var list = json['shopTopTip'] as List? ?? [];
    List<ShopTopTip> tips = list.map((i) => ShopTopTip.fromJson(i)).toList();
    return ShopConfig(shopTopTips: tips);
  }
}

class ShopTopTip {
  final String title;
  final String content;
  final String icon;

  ShopTopTip({
    required this.title,
    required this.content,
    required this.icon,
  });

  factory ShopTopTip.fromJson(Map<String, dynamic> json) {
    return ShopTopTip(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      icon: json['icon'] ?? '',
    );
  }
}
