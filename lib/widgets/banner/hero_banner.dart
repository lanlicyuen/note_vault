import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/colors.dart';

class HeroBanner extends StatefulWidget {
  final VoidCallback? onSettingsTap;

  const HeroBanner({super.key, this.onSettingsTap});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<BannerItem> _banners = [
    BannerItem(
      title: 'Note Vault',
      subtitle: '便携式私密备忘录',
      description: '安全存储 API Keys、Tokens、命令和技术备忘',
      icon: Icons.lock_outline,
      gradient: LinearGradient(
        colors: [AppColors.primary, AppColors.primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    BannerItem(
      title: '安全存储',
      subtitle: 'Secrets & Keys',
      description: 'API Keys、Tokens、密码安全存储，默认隐藏显示',
      icon: Icons.key_outlined,
      gradient: LinearGradient(
        colors: [AppColors.secretType, Color(0xFFF472B6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    BannerItem(
      title: '命令管理',
      subtitle: 'Commands',
      description: '常用命令一键复制，支持启动/停止/重启等分组',
      icon: Icons.terminal_outlined,
      gradient: LinearGradient(
        colors: [AppColors.commandType, Color(0xFF06B6D4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    BannerItem(
      title: 'Markdown 支持',
      subtitle: 'Notes',
      description: '支持 Markdown 格式的技术备忘，代码高亮',
      icon: Icons.note_alt_outlined,
      gradient: LinearGradient(
        colors: [AppColors.noteType, Color(0xFF818CF8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Stack(
        children: [
          // PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              return _buildBannerPage(_banners[index]);
            },
          ),

          // 指示器
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: _buildIndicators(),
          ),

          // 设置按钮
          if (widget.onSettingsTap != null)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                onPressed: widget.onSettingsTap,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBannerPage(BannerItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        children: [
          // 图标
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: item.gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (item.gradient.colors.first).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              item.icon,
              size: 40,
              color: Colors.white,
            ),
          ).animate().fadeIn().scale(delay: 100.ms),

          const SizedBox(width: 24),

          // 文字内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.2, end: 0),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: item.gradient.colors.first,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2, end: 0),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.2, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_banners.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class BannerItem {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final LinearGradient gradient;

  BannerItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}