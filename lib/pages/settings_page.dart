import 'package:flutter/material.dart';
import 'package:formulavision/data/services/app_settings_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = true;
  bool _isRaceControlSoundEnabled = true;
  bool _isTrackMapEnabled = true;
  String _trackMapDisplayMode = AppSettings.trackMapModeCard;
  String _feedSource = AppSettings.feedSourceOnDevice;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final soundEnabled = await AppSettings.isRaceControlSoundEnabled();
    final trackMapEnabled = await AppSettings.isTrackMapEnabled();
    final trackMapMode = await AppSettings.getTrackMapDisplayMode();
    final feedSource = await AppSettings.getFeedSource();

    setState(() {
      _isRaceControlSoundEnabled = soundEnabled;
      _isTrackMapEnabled = trackMapEnabled;
      _trackMapDisplayMode = trackMapMode;
      _feedSource = feedSource;
      _isLoading = false;
    });
  }

  /// Live data source: direct on-device F1 connection (default) vs the backend
  /// relay. On-device uses the phone's residential IP and bypasses F1's
  /// datacenter-IP blocking; the change takes effect next time the live page
  /// reconnects.
  Widget _buildFeedSourceCard() {
    final bool onDevice = _feedSource == AppSettings.feedSourceOnDevice;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.black.withValues(alpha: 0.35),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: onDevice
                    ? Colors.redAccent.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                onDevice ? Icons.smartphone : Icons.cloud_outlined,
                color: onDevice
                    ? Colors.redAccent
                    : Colors.white.withValues(alpha: 0.6),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'On-device feed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: 'formula-bold',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    onDevice
                        ? 'Connecting directly to F1 from this device'
                        : 'Using backend relay',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontFamily: 'formula',
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: onDevice,
              onChanged: (val) async {
                final source = val
                    ? AppSettings.feedSourceOnDevice
                    : AppSettings.feedSourceBackend;
                await AppSettings.setFeedSource(source);
                if (mounted) setState(() => _feedSource = source);
              },
              activeThumbColor: Colors.redAccent,
              activeTrackColor: Colors.redAccent.withValues(alpha: 0.3),
              inactiveThumbColor: Colors.white.withValues(alpha: 0.6),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackMapModeOption({
    required String label,
    required IconData icon,
    required String mode,
  }) {
    final bool isSelected = _trackMapDisplayMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: _isTrackMapEnabled
            ? () async {
                setState(() {
                  _trackMapDisplayMode = mode;
                });
                await AppSettings.setTrackMapDisplayMode(mode);
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.redAccent.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.redAccent
                  : Colors.white.withValues(alpha: 0.12),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.redAccent
                    : Colors.white.withValues(alpha: 0.6),
                size: 22,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontFamily: 'formula',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Color.fromARGB(255, 87, 0, 0),
            Color.fromARGB(190, 244, 67, 54),
            Color.fromARGB(255, 80, 0, 0),
            Color.fromARGB(255, 36, 16, 16),
          ],
        ),
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ──────────────────────────────────────────
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.pop(context),
                                  customBorder: const CircleBorder(),
                                  child: const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Icon(
                                      Icons.arrow_back_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'Settings',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontFamily: 'formula-bold',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(width: 44),
                          ],
                        ),

                        const SizedBox(height: 36),

                        // ── Live data source ─────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'LIVE DATA SOURCE',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontFamily: 'formula',
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                        _buildFeedSourceCard(),

                        const SizedBox(height: 32),

                        // ── Notifications ────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'NOTIFICATIONS',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontFamily: 'formula',
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.08),
                                Colors.black.withValues(alpha: 0.35),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _isRaceControlSoundEnabled
                                        ? Colors.redAccent
                                            .withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _isRaceControlSoundEnabled
                                        ? Icons.notifications_active_outlined
                                        : Icons.notifications_off_outlined,
                                    color: _isRaceControlSoundEnabled
                                        ? Colors.redAccent
                                        : Colors.white.withValues(alpha: 0.6),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Race Control Sound',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontFamily: 'formula-bold',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _isRaceControlSoundEnabled
                                            ? 'Plays on flags, safety car & penalties'
                                            : 'Muted — toasts still show',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.5),
                                          fontSize: 11,
                                          fontFamily: 'formula',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _isRaceControlSoundEnabled,
                                  onChanged: (val) async {
                                    setState(() {
                                      _isRaceControlSoundEnabled = val;
                                    });
                                    await AppSettings
                                        .setRaceControlSoundEnabled(val);
                                  },
                                  activeThumbColor: Colors.redAccent,
                                  activeTrackColor:
                                      Colors.redAccent.withValues(alpha: 0.3),
                                  inactiveThumbColor:
                                      Colors.white.withValues(alpha: 0.6),
                                  inactiveTrackColor:
                                      Colors.white.withValues(alpha: 0.1),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Track Map ────────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'TRACK MAP',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontFamily: 'formula',
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.08),
                                Colors.black.withValues(alpha: 0.35),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Show/hide toggle
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _isTrackMapEnabled
                                            ? Colors.redAccent
                                                .withValues(alpha: 0.2)
                                            : Colors.white
                                                .withValues(alpha: 0.07),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.map_outlined,
                                        color: _isTrackMapEnabled
                                            ? Colors.redAccent
                                            : Colors.white
                                                .withValues(alpha: 0.6),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Live Track Map',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontFamily: 'formula-bold',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _isTrackMapEnabled
                                                ? 'Shows cars moving on track'
                                                : 'Hidden',
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.5),
                                              fontSize: 11,
                                              fontFamily: 'formula',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: _isTrackMapEnabled,
                                      onChanged: (val) async {
                                        setState(() {
                                          _isTrackMapEnabled = val;
                                        });
                                        await AppSettings.setTrackMapEnabled(
                                            val);
                                      },
                                      activeThumbColor: Colors.redAccent,
                                      activeTrackColor: Colors.redAccent
                                          .withValues(alpha: 0.3),
                                      inactiveThumbColor:
                                          Colors.white.withValues(alpha: 0.6),
                                      inactiveTrackColor:
                                          Colors.white.withValues(alpha: 0.1),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Display-mode selector
                                AnimatedOpacity(
                                  opacity: _isTrackMapEnabled ? 1.0 : 0.4,
                                  duration: const Duration(milliseconds: 250),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Display Mode',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.5),
                                          fontSize: 11,
                                          fontFamily: 'formula',
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _buildTrackMapModeOption(
                                            label: 'Collapsible Card',
                                            icon: Icons.view_agenda_outlined,
                                            mode: AppSettings.trackMapModeCard,
                                          ),
                                          const SizedBox(width: 10),
                                          _buildTrackMapModeOption(
                                            label: 'Full View',
                                            icon: Icons.fullscreen_rounded,
                                            mode:
                                                AppSettings.trackMapModeFullView,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── GitHub ───────────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'ABOUT',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontFamily: 'formula',
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.08),
                                Colors.black.withValues(alpha: 0.35),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                final uri = Uri.parse(
                                    'https://github.com/skat9234/formula-vision');
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                } catch (e) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Could not open GitHub link')),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.07),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Image.asset(
                                        'assets/logo/GitHub_Invertocat_White.png',
                                        width: 22,
                                        height: 22,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'GitHub',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontFamily: 'formula-bold',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'skat9234/formula-vision',
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.5),
                                              fontSize: 11,
                                              fontFamily: 'formula',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.open_in_new_rounded,
                                      color:
                                          Colors.white.withValues(alpha: 0.4),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
