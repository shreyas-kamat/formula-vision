import 'package:flutter/material.dart';
import 'package:formulavision/data/services/app_settings_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isCustomApiEnabled = false;
  final TextEditingController _apiUrlController = TextEditingController();
  bool _isLoading = true;
  bool _isSaved = false;
  bool _isRaceControlSoundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final isEnabled = await AppSettings.isCustomApiUrlEnabled();
    final customUrl = await AppSettings.getCustomApiUrl();
    final soundEnabled = await AppSettings.isRaceControlSoundEnabled();

    setState(() {
      _isCustomApiEnabled = isEnabled;
      _apiUrlController.text = customUrl;
      _isRaceControlSoundEnabled = soundEnabled;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final url = _apiUrlController.text.trim();

    await AppSettings.setCustomApiUrlEnabled(_isCustomApiEnabled);
    await AppSettings.setCustomApiUrl(url);

    setState(() {
      _isSaved = true;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.withValues(alpha: 0.85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Settings saved',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'formula',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    // Reset saved state after a moment
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isSaved = false);
    });
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

                        // ── Section label ────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'API CONFIGURATION',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontFamily: 'formula',
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),

                        // ── Card ─────────────────────────────────────────────
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
                                // Toggle row
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _isCustomApiEnabled
                                            ? Colors.redAccent
                                                .withValues(alpha: 0.2)
                                            : Colors.white
                                                .withValues(alpha: 0.07),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.dns_outlined,
                                        color: _isCustomApiEnabled
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
                                            'Custom API URL',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontFamily: 'formula-bold',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _isCustomApiEnabled
                                                ? 'Using custom endpoint'
                                                : 'Using default from .env',
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
                                      value: _isCustomApiEnabled,
                                      onChanged: (val) {
                                        setState(() {
                                          _isCustomApiEnabled = val;
                                          _isSaved = false;
                                        });
                                      },
                                      activeColor: Colors.redAccent,
                                      activeTrackColor:
                                          Colors.redAccent.withValues(alpha: 0.3),
                                      inactiveThumbColor:
                                          Colors.white.withValues(alpha: 0.6),
                                      inactiveTrackColor:
                                          Colors.white.withValues(alpha: 0.1),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Custom URL field
                                AnimatedOpacity(
                                  opacity: _isCustomApiEnabled ? 1.0 : 0.4,
                                  duration: const Duration(milliseconds: 250),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Custom URL',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.5),
                                          fontSize: 11,
                                          fontFamily: 'formula',
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _apiUrlController,
                                        enabled: _isCustomApiEnabled,
                                        onChanged: (_) => setState(
                                            () => _isSaved = false),
                                        keyboardType: TextInputType.url,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontFamily: 'formula',
                                        ),
                                        decoration: InputDecoration(
                                          hintText:
                                              'e.g. http://192.168.1.100:3000',
                                          hintStyle: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.25),
                                            fontSize: 13,
                                            fontFamily: 'formula',
                                          ),
                                          filled: true,
                                          fillColor: Colors.black.withValues(
                                              alpha: _isCustomApiEnabled
                                                  ? 0.4
                                                  : 0.2),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 14, vertical: 12),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: BorderSide(
                                              color: Colors.white
                                                  .withValues(alpha: 0.12),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: BorderSide(
                                              color: Colors.white
                                                  .withValues(alpha: 0.12),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: const BorderSide(
                                              color: Colors.redAccent,
                                              width: 1.5,
                                            ),
                                          ),
                                          disabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: BorderSide(
                                              color: Colors.white
                                                  .withValues(alpha: 0.06),
                                            ),
                                          ),
                                          prefixIcon: Icon(
                                            Icons.link_rounded,
                                            color: Colors.white
                                                .withValues(alpha: 0.4),
                                            size: 20,
                                          ),
                                          suffixIcon: _isCustomApiEnabled &&
                                                  _apiUrlController
                                                      .text.isNotEmpty
                                              ? IconButton(
                                                  icon: Icon(
                                                    Icons.clear_rounded,
                                                    color: Colors.white
                                                        .withValues(alpha: 0.4),
                                                    size: 18,
                                                  ),
                                                  onPressed: () => setState(
                                                      () => _apiUrlController
                                                          .clear()),
                                                )
                                              : null,
                                        ),
                                      ),
                                      if (_isCustomApiEnabled &&
                                          _apiUrlController.text.isNotEmpty &&
                                          !_apiUrlController.text
                                              .startsWith('http'))
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.orange
                                                    .withValues(alpha: 0.8),
                                                size: 14,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'URL should start with http:// or https://',
                                                style: TextStyle(
                                                  color: Colors.orange
                                                      .withValues(alpha: 0.8),
                                                  fontSize: 11,
                                                  fontFamily: 'formula',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Active URL preview ───────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Colors.white.withValues(alpha: 0.4),
                                size: 16,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Active: ${_isCustomApiEnabled && _apiUrlController.text.trim().isNotEmpty ? _apiUrlController.text.trim() : 'Default (.env)'}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 11,
                                    fontFamily: 'formula',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Save button ──────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveSettings,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isSaved
                                  ? Colors.green.withValues(alpha: 0.8)
                                  : Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isSaved
                                      ? Icons.check_circle_outline
                                      : Icons.save_outlined,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _isSaved ? 'Saved!' : 'Save Settings',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontFamily: 'formula-bold',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Center(
                          child: Text(
                            'Changes take effect on the next data fetch.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 11,
                              fontFamily: 'formula',
                            ),
                          ),
                        ),

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
                                          color:
                                              Colors.white.withValues(alpha: 0.5),
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
                                  activeColor: Colors.redAccent,
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
                                final messenger =
                                    ScaffoldMessenger.of(context);
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
                                        color:
                                            Colors.white.withValues(alpha: 0.07),
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
                                      color: Colors.white.withValues(alpha: 0.4),
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
