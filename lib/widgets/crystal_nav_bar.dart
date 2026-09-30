import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import '../theme.dart';

class VoyagoCrystalNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;
  final VoidCallback? onPlusTap;

  const VoyagoCrystalNavBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
    this.onPlusTap,
  });

  @override
  Widget build(BuildContext context) {
    // Largeur et marges réactives pour Mobile, Tablette, Desktop et Web
    final isTabletOrWeb = Device.screenType == ScreenType.tablet || Device.screenType == ScreenType.desktop;
    final horizontalPadding = isTabletOrWeb ? 0.0 : 4.5.w.clamp(14.0, 24.0);
    final navBarHeight = isTabletOrWeb ? 76.0 : 72.0;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 1.5.h.clamp(10.0, 16.0),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 480, // Garde un dock élégant centré sur grand écran
            ),
            child: Container(
              height: navBarHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 28,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: VoyagoColors.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xE8141724),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1.2,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 3.w.clamp(10.0, 18.0)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tab 0: Accueil
                        _NavItem(
                          icon: Icons.home_rounded,
                          unselectedIcon: Icons.home_outlined,
                          label: 'Accueil',
                          isSelected: currentIndex == 0,
                          onTap: () {
                            if (currentIndex != 0) {
                              onTap?.call(0);
                              context.go('/');
                            }
                          },
                        ),

                        // Tab 1: Carte & Itinéraire
                        _NavItem(
                          icon: Icons.map_rounded,
                          unselectedIcon: Icons.map_outlined,
                          label: 'Carte',
                          isSelected: currentIndex == 1,
                          onTap: () {
                            onTap?.call(1);
                            context.go('/itinerary');
                          },
                        ),

                        // Center (+) Action Button
                        _CenterPlusButton(
                          onTap: () {
                            if (onPlusTap != null) {
                              onPlusTap!();
                            } else {
                              context.go('/swipe');
                            }
                          },
                        ),

                        // Tab 2: Communauté
                        _NavItem(
                          icon: Icons.public_rounded,
                          unselectedIcon: Icons.public_outlined,
                          label: 'Social',
                          isSelected: currentIndex == 2,
                          onTap: () {
                            onTap?.call(2);
                            context.go('/community');
                          },
                        ),

                        // Tab 3: Profil
                        _NavItem(
                          icon: Icons.person_rounded,
                          unselectedIcon: Icons.person_outline_rounded,
                          label: 'Profil',
                          isSelected: currentIndex == 3,
                          onTap: () {
                            onTap?.call(3);
                            context.go('/profile');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData unselectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.unselectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = 6.w.clamp(22.0, 26.0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: 2.5.w.clamp(8.0, 14.0),
          vertical: 1.h.clamp(6.0, 10.0),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? VoyagoColors.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? icon : unselectedIcon,
              size: iconSize,
              color: isSelected ? VoyagoColors.primary : Colors.white60,
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: isSelected ? 4 : 0,
              height: 4,
              decoration: BoxDecoration(
                color: VoyagoColors.primary,
                borderRadius: BorderRadius.circular(2),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: VoyagoColors.primary.withValues(alpha: 0.8),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterPlusButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CenterPlusButton({required this.onTap});

  @override
  State<_CenterPlusButton> createState() => _CenterPlusButtonState();
}

class _CenterPlusButtonState extends State<_CenterPlusButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final buttonSize = 13.w.clamp(48.0, 54.0);
    final iconSize = (buttonSize * 0.58).clamp(26.0, 32.0);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeInOut,
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                VoyagoColors.primaryLight,
                VoyagoColors.primary,
                VoyagoColors.primaryDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: VoyagoColors.primary.withValues(alpha: 0.55),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
