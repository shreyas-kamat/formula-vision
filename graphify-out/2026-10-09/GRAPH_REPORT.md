# Graph Report - formulavision  (2026-10-09)

## Corpus Check
- 167 files · ~310,088 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 66 file(s) not represented in the graph (top: .xml 13, (none) 8, .xcconfig 8)

## Summary
- 2290 nodes · 2773 edges · 137 communities (97 shown, 40 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 58 edges (avg confidence: 0.9)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `c020ed2e`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- dashboard_page.dart
- live_data.model.dart
- my_application.cc
- track_map_service.dart
- settings_page.dart
- lap.model.dart
- win32_window.cpp
- Win32Window
- meeting.model.dart
- 🤝 Contributing to Formula-Vision
- Review Focus
- utils.cpp
- track_from_archive.py
- position.model.dart
- FlutterWindow
- interval.model.dart
- DateTime
- MessageHandler
- race_timer_bar.dart
- FormulaVision
- windows/flutter/generated_plugin_registrant.cc
- package:shared_preferences/shared_preferences.dart
- flutter_window.cpp
- fetchDriverDetails
- Point
- Size
- MainActivity.kt
- AGENTS.md
- CLAUDE.md
- LaunchImage.imageset/README.md
- test_page_alt.dart
- Maps Registry (maps.json)
- MaterialPageRoute
- speedometer.dart
- racedriver.model.dart
- schedule_page.dart
- live_homepage.dart
- nav_page.dart
- LiveData Model
- standings.function.dart
- circuit_list.dart
- contructors_standings_page.dart
- drivers_standings_page.dart
- driver_row_card.dart
- login_page.dart
- register_page.dart
- circuit_viewer.dart
- speedometer_page.dart
- animated_driver_tile.dart
- auth_service.dart
- email_verification.dart
- track_status_card.dart
- auth.function.dart
- racedriver.function.dart
- test_page.dart
- drivers.model.dart
- standings_page.dart
- forgotpw_page.dart
- resetpw_page.dart
- race.function.dart
- schedule.model.dart
- dash_auth_page.dart
- race_info_card.dart
- car_data.model.dart
- session_info_card.dart
- weather_info_card.dart
- constructors.model.dart
- home_page.dart
- main.dart
- dash_auth.dart
- driver_tile.dart
- lap_count_card.dart
- info_page.dart
- live_details_page.dart
- package:flutter/material.dart
- driver.model.dart
- user.function.dart
- StandingsWithYear Model
- cardata.function.dart
- live_data.function.dart
- Hard Tyre Icon (white/H)
- _AuthClient (HTTP Auth Interceptor)
- session.model.dart
- user.model.dart
- Circuit Model (Schedule)
- CarDataChannels (LiveData)
- Splash Screen (FV branding)
- StatelessWidget
- Sakhir (Bahrain International Circuit)
- State
- DriverInfoCardTest
- LiveHomePage
- TrackMap Widget
- decompressCarData Function
- F1ScheduleResponse Model
- F1 API Service (empty)
- Shanghai International Circuit
- Silverstone Circuit
- Marina Bay Street Circuit (Singapore)
- Sochi Autodrom
- Circuit de Spa-Francorchamps
- Red Bull Ring (Spielberg)
- Suzuka International Racing Course
- Yas Marina Circuit
- Circuit Zandvoort
- GitHub Invertocat White Logo
- Unknown Tyre Icon (grey/?)
- mini_sector_bar.dart
- GeneratedPluginRegistrant.swift
- manifest.json
- race_control_toast.dart
- app_settings_service.dart
- test_schedule.dart
- live_track_map_widget_test.dart
- package:formulavision/data/models/live_data.model.dart
- driver_row_card_test.dart
- telemetry_hud.dart
- f1_live_client.dart
- f1_clock_extrapolator.dart
- dart:convert
- f1_decompress.function.dart
- connecting_indicator.dart
- live_data_service.dart

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 24 edges
2. `Maps Registry (maps.json)` - 21 edges
3. `Track Corners Schema (x/y coordinates, angle, length, number)` - 21 edges
4. `LiveData` - 14 edges
5. `MessageHandler` - 12 edges
6. `FlutterWindow` - 10 edges
7. `Create` - 10 edges
8. `WndProc` - 10 edges
9. `MessageHandler` - 9 edges
10. `FormulaVision` - 8 edges

## Surprising Connections (you probably didn't know these)
- `DriversStandingsPage` --semantically_similar_to--> `ContructorsStandingsPage`  [INFERRED] [semantically similar]
  lib/pages/drivers_standings_page.dart → lib/pages/contructors_standings_page.dart
- `LoginPage` --calls--> `EmailVerification Page`  [EXTRACTED]
  lib/auth/login_page.dart → lib/auth/email_verification.dart
- `DriverInfoCard` --semantically_similar_to--> `DriverInfoCardFixed`  [INFERRED] [semantically similar]
  lib/components/driver_tile.dart → lib/components/driver_tile_fixed.dart
- `RaceTimerBar` --semantically_similar_to--> `SessionInfoCard`  [INFERRED] [semantically similar]
  lib/components/race_timer_bar.dart → lib/components/session_info_card.dart
- `Meeting Model (OpenF1)` --semantically_similar_to--> `SessionInfo`  [INFERRED] [semantically similar]
  lib/data/models/openf1/meeting.model.dart → lib/data/models/live_data.model.dart

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Auth Flow Pages** — lib_auth_dash_auth_page_dashauthpage, lib_auth_login_page_loginpage, lib_auth_register_page_registerpage, lib_auth_forgotpw_page_forgotpasswordpage, lib_auth_email_verification_emailverification, lib_auth_resetpw_page_resetpasswordpage, lib_auth_verification_page_verificationpage [EXTRACTED 1.00]
- **Circuit Viewer Flow** — lib_pages_circuit_list_circuitlist, lib_pages_circuit_list_circuitviewerpage, lib_pages_circuit_viewer_circuitviewer, lib_pages_circuit_viewer_circuitpainter [EXTRACTED 1.00]
- **F1 Tyre Compound Icons** — tyre_hard, tyre_medium, tyre_soft, tyre_intermediate, tyre_unknown [EXTRACTED 1.00]
- **NavPage Tab Pages (Home, Dashboard, Schedule, Standings)** — lib_pages_nav_page_navpage, lib_pages_home_page_homepage, lib_pages_dashboard_page_dashboardpage, lib_pages_schedule_page_schedulepage, lib_pages_standings_page_standingspage [EXTRACTED 1.00]
- **Race Driver Data Aggregation Pipeline** — lib_data_functions_racedriver_function_fetchracedriverinfo, lib_data_functions_race_function_fetchdriverdetails, lib_data_functions_racedriver_function_fetchlaps, lib_data_functions_racedriver_function_fetchintervals, lib_data_functions_racedriver_function_fetchpits [EXTRACTED 1.00]
- **Standings API Caching Pattern** — lib_data_functions_standings_function_fetchconstructorstandings, lib_data_functions_standings_function_fetchdriverstandings, lib_data_functions_standings_function_clearstandingscache [EXTRACTED 1.00]
- **Shared Track Coordinate Schema** — schema_trackcorners, schema_marshallights, schema_marshalsectors, schema_candidatelap [EXTRACTED 1.00]
- **Live Data WebSocket Update Pipeline** — lib_data_models_live_data_model_f1datamodel, lib_data_models_live_data_model_livedata, lib_data_functions_live_data_function_fetchlivedata [INFERRED 0.85]
- **F1 Circuit Track Maps (Chunk 4)** — assets_trackmaps_algarve, assets_trackmaps_austin, assets_trackmaps_baku, assets_trackmaps_catalunya, assets_trackmaps_hockenheim, assets_trackmaps_hungaroring, assets_trackmaps_imola, assets_trackmaps_interlagos, assets_trackmaps_istanbul, assets_trackmaps_jeddah, trackmaps_lasvegas, assets_trackmaps_losail, assets_trackmaps_melbourne, assets_trackmaps_mexico, assets_trackmaps_miami, trackmaps_montecarlo, assets_trackmaps_montreal, assets_trackmaps_monza, assets_trackmaps_mugello, assets_trackmaps_nurburgring, trackmaps_paulriccard [INFERRED 0.95]
- **F1 Circuit Track Maps (Chunk 5)** — assets_trackmaps_sakhir_outer, assets_trackmaps_sakhir, assets_trackmaps_shanghai, assets_trackmaps_silverstone, assets_trackmaps_singapore, assets_trackmaps_sochi, trackmaps_spa, assets_trackmaps_spielberg, assets_trackmaps_suzuka, trackmaps_yasmarina, assets_trackmaps_zandvoort [INFERRED 0.95]

## Communities (137 total, 40 thin omitted)

### Community 0 - "dashboard_page.dart"
Cohesion: 0.01
Nodes (142): AlertDialog, applySector, applySegment, applyStint, Card, Center, CircularProgressIndicator, Column (+134 more)

### Community 1 - "live_data.model.dart"
Cohesion: 0.01
Nodes (156): airTemp, ArchiveStatus, _asInt, bestLapTime, bestSectors, bestSpeeds, brake, broadcastName (+148 more)

### Community 2 - "my_application.cc"
Cohesion: 0.08
Nodes (13): fl_register_plugins(), main(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line(), my_application_new() (+5 more)

### Community 3 - "track_map_service.dart"
Cohesion: 0.08
Nodes (20): apiBase, _bundle, bundledFiles, circuitKey, circuitKeysByName, _client, _fetch, fromJson (+12 more)

### Community 4 - "settings_page.dart"
Cohesion: 0.08
Nodes (23): Container, dispose, Expanded, launchUrl, SizedBox, SnackBar, Spacer, Text (+15 more)

### Community 5 - "lap.model.dart"
Cohesion: 0.09
Nodes (21): dateStart, driverNumber, durationSector1, durationSector2, durationSector3, formatLapDuration, fromJson, getLapTimeFormatted (+13 more)

### Community 6 - "win32_window.cpp"
Cohesion: 0.16
Nodes (12): Scale(), Create, Destroy, SetQuitOnClose, Show, UpdateTheme, Win32Window::Win32Window(), WindowClassRegistrar (+4 more)

### Community 7 - "Win32Window"
Cohesion: 0.29
Nodes (8): OnCreate, Win32Window, child_content_, GetClientArea, OnCreate, quit_on_close_, SetChildContent, window_handle_

### Community 8 - "meeting.model.dart"
Cohesion: 0.12
Nodes (15): circuitKey, circuitShortName, countryCode, countryKey, countryName, dateStart, fromJson, gmtOffset (+7 more)

### Community 9 - "🤝 Contributing to Formula-Vision"
Cohesion: 0.13
Nodes (14): Branches, Commit & Branch Creation Format, Commits, 🤝 Contributing to Formula-Vision, Contributor License Agreement, Development Setup, Did you find a bug?, Did you have a solution for an Issue? (+6 more)

### Community 10 - "Review Focus"
Cohesion: 0.15
Nodes (12): Background: verified findings (read before starting), Global Constraints, Live Track Map Fixes Implementation Plan, Manual verification (for the user, after the agent finishes), Review Focus, Task 1: Parse the real `Position.z` shape and keep every frame, Task 2: Read F1's capitalised Meeting/Circuit keys, Task 3: Bundle a Madring (Madrid) outline generated from the F1 archive (+4 more)

### Community 11 - "utils.cpp"
Cohesion: 0.19
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 12 - "track_from_archive.py"
Cohesion: 0.21
Nodes (4): fastest_loop(), load_stream(), main(), resample()

### Community 13 - "position.model.dart"
Cohesion: 0.18
Nodes (10): date, driverNumber, fromJson, getFormattedPosition, isInPoints, isOnPodium, meetingKey, Position (+2 more)

### Community 15 - "FlutterWindow"
Cohesion: 0.17
Nodes (4): FlutterWindow, flutter_controller_, MessageHandler, project_

### Community 16 - "interval.model.dart"
Cohesion: 0.18
Nodes (10): date, driverNumber, formatGapToLeader, formatInterval, fromJson, gapToLeader, Interval, meetingKey (+2 more)

### Community 17 - "DateTime"
Cohesion: 0.17
Nodes (10): date, driverNumber, formatPitDuration, fromJson, lapNumber, meetingKey, Pit, pitDuration (+2 more)

### Community 18 - "MessageHandler"
Cohesion: 0.36
Nodes (5): EnableFullDpiSupportIfAvailable(), GetHandle, GetThisFromHandle, MessageHandler, WndProc

### Community 19 - "race_timer_bar.dart"
Cohesion: 0.15
Nodes (11): Container, SizedBox, build, CompactRaceTimerBar, currentLap, package:flutter/material.dart, _formatTime, _isRaceOrSprintSession (+3 more)

### Community 20 - "FormulaVision"
Cohesion: 0.22
Nodes (8): Contributing Guidelines, Credits, Downloads, Features, FormulaVision, License, NOTICE, Planned Features

### Community 22 - "package:shared_preferences/shared_preferences.dart"
Cohesion: 0.29
Nodes (3): currentYear, _driverStandingsResponse, main

### Community 23 - "flutter_window.cpp"
Cohesion: 0.29
Nodes (3): FlutterWindow::FlutterWindow(), OnDestroy, OnDestroy

### Community 24 - "fetchDriverDetails"
Cohesion: 0.20
Nodes (10): Constructor Model (Jolpica), ConstructorStanding Model, Driver Model (Jolpica), DriverStanding Model, fetchCombinedRaceDetails, fetchDriverDetails, fetchPositions, fetchStints (+2 more)

### Community 25 - "Point"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 26 - "Size"
Cohesion: 0.50
Nodes (3): Size, height, width

### Community 34 - "test_page_alt.dart"
Cohesion: 0.06
Nodes (33): Card, CircularProgressIndicator, Padding, Scaffold, SizedBox, Text, build, _buildConnectionStatusCard (+25 more)

### Community 35 - "Maps Registry (maps.json)"
Cohesion: 0.14
Nodes (22): Maps Registry (maps.json), Algarve International Circuit, Austin (Circuit of the Americas), Baku City Circuit, Circuit de Barcelona-Catalunya, Hockenheimring, Hungaroring, Autodromo Enzo e Dino Ferrari (Imola) (+14 more)

### Community 36 - "MaterialPageRoute"
Cohesion: 0.40
Nodes (4): build, _openSpeedometer, build, _navigateToCircuitViewer

### Community 38 - "speedometer.dart"
Cohesion: 0.06
Nodes (36): CustomPaint, Positioned, Stack, ArcPainter, backgroundColor, brake, build, _buildBrakeIndicator (+28 more)

### Community 39 - "racedriver.model.dart"
Cohesion: 0.07
Nodes (25): currentStint, package:flutter/material.dart, package:formulavision/data/models/openf1/driver.model.dart, package:formulavision/data/models/openf1/interval.model.dart, package:formulavision/data/models/openf1/lap.model.dart, package:formulavision/data/models/openf1/pit.model.dart, package:formulavision/data/models/openf1/position.model.dart, package:formulavision/data/models/openf1/stint.model.dart (+17 more)

### Community 40 - "schedule_page.dart"
Cohesion: 0.05
Nodes (44): Formula 2025 Calendar (iCal JSON), Hungarian Grand Prix 2025, Italian Grand Prix 2025, VCALENDAR 2025 Structure, VEVENT 2025 (Race Session Event), Formula 2026 Calendar (iCal JSON), Australian Grand Prix 2026, Chinese Grand Prix 2026 (+36 more)

### Community 41 - "live_homepage.dart"
Cohesion: 0.06
Nodes (30): Center, Column, Container, fetchInitialData, launchUrl, SettingsPage, _applyImageFromData, createState (+22 more)

### Community 42 - "nav_page.dart"
Cohesion: 0.10
Nodes (12): Scaffold, build, createState, package:flutter/material.dart, package:formulavision/auth/email_verification.dart, package:formulavision/auth/forgotpw_page.dart, package:formulavision/auth/login_page.dart, package:formulavision/pages/dashboard_page.dart (+4 more)

### Community 43 - "LiveData Model"
Cohesion: 0.11
Nodes (18): TrackStatusCard, WeatherInfoCard, fetchLiveData, fetchLatestMeetings, ChampionshipPrediction, DriverList, F1DataModel, LapCount (+10 more)

### Community 44 - "standings.function.dart"
Cohesion: 0.05
Nodes (36): Color, Exception, _cacheDuration, cacheKey, clearStandingsCache, _constructorStandingsCacheKey, dart:convert, dart:ui (+28 more)

### Community 45 - "circuit_list.dart"
Cohesion: 0.07
Nodes (28): CircuitViewer, Container, build, _buildCircuitCard, CircuitInfo, circuitKey, CircuitList, _CircuitListState (+20 more)

### Community 46 - "contructors_standings_page.dart"
Cohesion: 0.09
Nodes (20): Center, Container, Function, Padding, Scaffold, SizedBox, Text, build (+12 more)

### Community 47 - "drivers_standings_page.dart"
Cohesion: 0.09
Nodes (20): Center, Container, Function, Padding, Scaffold, SizedBox, Text, build (+12 more)

### Community 48 - "driver_row_card.dart"
Cohesion: 0.04
Nodes (43): _buildStintHistory, Container, Divider, Padding, SafeArea, SizedBox, SlideTransition, Spacer (+35 more)

### Community 50 - "login_page.dart"
Cohesion: 0.11
Nodes (15): Scaffold, createState, package:flutter/material.dart, package:formulavision/auth/forgotpw_page.dart, package:formulavision/data/functions/auth.function.dart, package:formulavision/pages/nav_page.dart, package:google_fonts/google_fonts.dart, package:shared_preferences/shared_preferences.dart (+7 more)

### Community 51 - "register_page.dart"
Cohesion: 0.07
Nodes (28): Scaffold, build, buildPicker, confirmpassController, createState, _currentItemSelected, package:flutter/material.dart, package:formulavision/auth/login_page.dart (+20 more)

### Community 52 - "circuit_viewer.dart"
Cohesion: 0.04
Nodes (40): Container, clear, delay, _Fix, _fixes, ingest, isEmpty, _latest (+32 more)

### Community 53 - "speedometer_page.dart"
Cohesion: 0.11
Nodes (15): SafeArea, SizedBox, _accelerating, build, createState, _currentSpeed, dart:async, dart:math (+7 more)

### Community 54 - "animated_driver_tile.dart"
Cohesion: 0.08
Nodes (23): AnimatedBuilder, SizedBox, Stack, Text, AnimatedDriverInfoCard, _AnimatedDriverInfoCardState, bestLapTime, build (+15 more)

### Community 55 - "auth_service.dart"
Cohesion: 0.08
Nodes (21): _context, _copyRequest, createAuthClient, dart:async, dart:convert, package:flutter_dotenv/flutter_dotenv.dart, package:flutter/material.dart, package:formulavision/auth/login_page.dart (+13 more)

### Community 56 - "email_verification.dart"
Cohesion: 0.14
Nodes (14): Scaffold, build, createState, currentBalanceController, dailyLimitController, package:flutter/material.dart, package:formulavision/auth/login_page.dart, package:formulavision/data/functions/auth.function.dart (+6 more)

### Community 57 - "track_status_card.dart"
Cohesion: 0.17
Nodes (11): Container, SizedBox, Text, build, _buildMessageSection, _buildStatusBadge, package:flutter/material.dart, _getStatusIcon (+3 more)

### Community 58 - "auth.function.dart"
Cohesion: 0.07
Nodes (29): apiUrl, checkTokenValidity, dart:convert, package:flutter_dotenv/flutter_dotenv.dart, package:flutter/material.dart, package:formulavision/auth/email_verification.dart, package:formulavision/auth/login_page.dart, package:formulavision/data/services/app_settings_service.dart (+21 more)

### Community 59 - "racedriver.function.dart"
Cohesion: 0.09
Nodes (15): dart:convert, package:formulavision/data/models/openf1/driver.model.dart, package:formulavision/data/models/openf1/interval.model.dart, package:formulavision/data/models/openf1/lap.model.dart, package:formulavision/data/models/openf1/pit.model.dart, package:formulavision/data/models/openf1/position.model.dart, package:formulavision/data/models/openf1/stint.model.dart, package:http/http.dart (+7 more)

### Community 60 - "test_page.dart"
Cohesion: 0.18
Nodes (9): Container, SingleChildScrollView, SizedBox, Text, build, _buildDriverRow, createState, package:flutter/material.dart (+1 more)

### Community 61 - "drivers.model.dart"
Cohesion: 0.05
Nodes (36): code, Constructor, constructorId, constructors, dart:convert, dateOfBirth, Driver, driverId (+28 more)

### Community 62 - "standings_page.dart"
Cohesion: 0.17
Nodes (10): Container, SizedBox, build, createState, package:flutter/material.dart, _displayYear, _isPreviousYear, StandingsPage (+2 more)

### Community 63 - "forgotpw_page.dart"
Cohesion: 0.15
Nodes (10): Scaffold, build, createState, package:flutter/material.dart, package:formulavision/data/functions/auth.function.dart, package:google_fonts/google_fonts.dart, emailController, ForgotPasswordPage (+2 more)

### Community 64 - "resetpw_page.dart"
Cohesion: 0.12
Nodes (16): LoginPage, Scaffold, build, confirmNewPassword, createState, package:flutter/material.dart, package:formulavision/auth/login_page.dart, package:formulavision/data/functions/auth.function.dart (+8 more)

### Community 65 - "race.function.dart"
Cohesion: 0.10
Nodes (22): combinedDetails, dart:convert, package:formulavision/data/models/openf1/driver.model.dart, package:formulavision/data/models/openf1/position.model.dart, package:formulavision/data/models/openf1/stint.model.dart, package:http/http.dart, DriverNum, drivers (+14 more)

### Community 66 - "schedule.model.dart"
Cohesion: 0.05
Nodes (38): Circuit, circuitId, circuitName, country, dart:convert, date, F1ScheduleResponse, firstPractice (+30 more)

### Community 67 - "dash_auth_page.dart"
Cohesion: 0.20
Nodes (9): Scaffold, SizedBox, Text, build, createState, package:flutter/material.dart, package:formulavision/auth/login_page.dart, DashAuthPage (+1 more)

### Community 68 - "race_info_card.dart"
Cohesion: 0.15
Nodes (11): Container, SizedBox, Text, build, currentLap, package:flutter/material.dart, _getProgressColor, _getSessionIcon (+3 more)

### Community 69 - "car_data.model.dart"
Cohesion: 0.11
Nodes (18): brake, CarData, date, driverNumber, drs, fromJson, getBrakePercentage, getDrsStatus (+10 more)

### Community 70 - "session_info_card.dart"
Cohesion: 0.13
Nodes (14): Container, SizedBox, build, _buildInfoSection, circuit, country, package:flutter/material.dart, _getSessionIcon (+6 more)

### Community 71 - "weather_info_card.dart"
Cohesion: 0.15
Nodes (12): Container, SizedBox, Text, airTemp, build, _buildWeatherIcon, _buildWeatherMetric, package:flutter/material.dart (+4 more)

### Community 72 - "constructors.model.dart"
Cohesion: 0.06
Nodes (28): Constructor, constructorId, ConstructorStanding, constructorStandings, ConstructorStandingsResponse, dart:convert, fromJson, fromRawJson (+20 more)

### Community 73 - "home_page.dart"
Cohesion: 0.20
Nodes (8): LiveHomePage, build, createState, package:flutter/material.dart, package:formulavision/pages/nav_page.dart, package:google_fonts/google_fonts.dart, HomePage, _HomePageState

### Community 76 - "main.dart"
Cohesion: 0.17
Nodes (8): MaterialApp, build, package:flutter_dotenv/flutter_dotenv.dart, package:flutter/material.dart, package:formulavision/pages/nav_page.dart, load, main, MyApp

### Community 108 - "dash_auth.dart"
Cohesion: 0.25
Nodes (7): DashboardPage, build, createState, package:flutter/material.dart, package:formulavision/pages/dashboard_page.dart, DashAuth, _DashAuthState

### Community 109 - "driver_tile.dart"
Cohesion: 0.12
Nodes (15): Container, SizedBox, Text, bestLapTime, build, currentLapTime, package:flutter/material.dart, DriverInfoCard (+7 more)

### Community 110 - "lap_count_card.dart"
Cohesion: 0.15
Nodes (12): Container, SizedBox, build, CompactLapCountCard, currentLap, package:flutter/material.dart, extrapolatedClock, isClockExtrapolating (+4 more)

### Community 112 - "info_page.dart"
Cohesion: 0.25
Nodes (7): Container, Row, build, _buildFeatureItem, package:flutter/material.dart, InfoPage, _launchURL

### Community 113 - "live_details_page.dart"
Cohesion: 0.11
Nodes (17): Column, SafeArea, Scaffold, SizedBox, build, createState, package:flutter/material.dart, package:formulavision/components/speedometer.dart (+9 more)

### Community 115 - "package:flutter/material.dart"
Cohesion: 0.15
Nodes (10): Scaffold, EmailVerification Page, build, createState, package:flutter/material.dart, VerificationPage, _VerificationPageState, package:flutter/material.dart (+2 more)

### Community 117 - "driver.model.dart"
Cohesion: 0.12
Nodes (16): Color, broadcastName, package:flutter/material.dart, Driver, driverNumber, firstName, fromJson, fullName (+8 more)

### Community 118 - "user.function.dart"
Cohesion: 0.11
Nodes (16): apiUrl, bearer, dart:convert, package:flutter_dotenv/flutter_dotenv.dart, package:formulavision/data/services/app_settings_service.dart, package:http/http.dart, package:shared_preferences/shared_preferences.dart, fetchCurrentBalance (+8 more)

### Community 120 - "StandingsWithYear Model"
Cohesion: 0.40
Nodes (5): ConstructorStandingsResponse Model, DriverStandingsResponse Model, fetchConstructorStandings, fetchDriverStandings, StandingsWithYear

### Community 123 - "cardata.function.dart"
Cohesion: 0.50
Nodes (3): decompressCarData, dart:convert, package:archive/archive.dart

### Community 124 - "live_data.function.dart"
Cohesion: 0.18
Nodes (8): dart:convert, package:formulavision/data/models/live_data.model.dart, package:http/http.dart, entries, fetchedData, latestQualifyingPart, part, series

### Community 125 - "Hard Tyre Icon (white/H)"
Cohesion: 1.00
Nodes (4): Hard Tyre Icon (white/H), Intermediate Tyre Icon (green/I), Medium Tyre Icon (yellow/M), Soft Tyre Icon (red/S)

### Community 126 - "_AuthClient (HTTP Auth Interceptor)"
Cohesion: 0.50
Nodes (3): JWT Token Auth Flow, _AuthClient, AuthService

### Community 128 - "session.model.dart"
Cohesion: 0.05
Nodes (35): RaceDriverInfo, circuitKey, circuitShortName, countryCode, countryKey, countryName, dateEnd, dateStart (+27 more)

### Community 135 - "user.model.dart"
Cohesion: 0.22
Nodes (8): currentBalance, email, fromJson, id, lastTransactionAmount, name, toJson, User

### Community 141 - "StatelessWidget"
Cohesion: 0.20
Nodes (10): _Lamp, _LightPod, MiniSectorBar, RaceInfoCard, RaceTimerBar, SessionInfoCard, F1Speedometer, _AeroPill (+2 more)

### Community 153 - "State"
Cohesion: 0.12
Nodes (22): ConnectingIndicator, _ConnectingIndicatorState, DriverRowCard, _DriverRowCardState, TelemetryHud, _TelemetryHudState, DashboardPage, LiveTrackMapWidget (+14 more)

### Community 193 - "mini_sector_bar.dart"
Cohesion: 0.11
Nodes (18): _buildSector, Color, Column, Container, Row, SizedBox, build, _cell (+10 more)

### Community 196 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.06
Nodes (17): audioplayers_darwin, Cocoa, Flutter, FlutterMacOS, Foundation, AppDelegate, RunnerTests, RegisterGeneratedPlugins() (+9 more)

### Community 198 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 200 - "race_control_toast.dart"
Cohesion: 0.15
Nodes (11): SizedBox, SnackBar, _accentColor, buildSnackBar, package:flutter/material.dart, package:formulavision/data/models/live_data.model.dart, _icon, _importantCategories (+3 more)

### Community 204 - "app_settings_service.dart"
Cohesion: 0.05
Nodes (38): AppSettings, _customApiUrlEnabledKey, _customApiUrlKey, package:flutter_dotenv/flutter_dotenv.dart, package:shared_preferences/shared_preferences.dart, feedSourceBackend, _feedSourceKey, feedSourceOnDevice (+30 more)

### Community 206 - "test_schedule.dart"
Cohesion: 0.20
Nodes (8): dart:convert, dart:io, getCleanName, main, name, prefixes, testCases, testCleanName

### Community 229 - "live_track_map_widget_test.dart"
Cohesion: 0.10
Nodes (14): PositionData, build, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:formulavision/data/models/live_data.model.dart, package:formulavision/pages/dashboard_page.dart, drivers, main (+6 more)

### Community 231 - "package:formulavision/data/models/live_data.model.dart"
Cohesion: 0.10
Nodes (13): package:flutter_test/flutter_test.dart, package:formulavision/data/models/live_data.model.dart, main, _base, _data, main, _sample, _wall (+5 more)

### Community 232 - "driver_row_card_test.dart"
Cohesion: 0.15
Nodes (11): package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:formulavision/components/driver_row_card.dart, package:formulavision/data/models/live_data.model.dart, package:shared_preferences/shared_preferences.dart, _harness, main, _sector (+3 more)

### Community 233 - "telemetry_hud.dart"
Cohesion: 0.06
Nodes (27): Color, Column, Container, SizedBox, Text, active, build, color (+19 more)

### Community 235 - "f1_live_client.dart"
Cohesion: 0.05
Nodes (35): Exception, Function, _startKeepAlive, _stopKeepAlive, _baseHttp, _baseWs, _clock, _closing (+27 more)

### Community 236 - "f1_clock_extrapolator.dart"
Cohesion: 0.11
Nodes (16): Function, _baseRemainingSeconds, dart:async, dispose, _extrapolating, F1ClockExtrapolator, _format, _lastF1Update (+8 more)

### Community 237 - "dart:convert"
Cohesion: 0.13
Nodes (12): base64Encode, bytes, dart:convert, dart:io, package:flutter_test/flutter_test.dart, package:formulavision/data/functions/f1_decompress.function.dart, deflated, main (+4 more)

### Community 238 - "f1_decompress.function.dart"
Cohesion: 0.12
Nodes (14): 0, cars, _channel, dart:convert, dart:io, decodeCarDataZ, decodePositionZ, entries (+6 more)

### Community 239 - "connecting_indicator.dart"
Cohesion: 0.09
Nodes (18): AnimatedContainer, Center, Container, Padding, Row, SizedBox, build, _controller (+10 more)

### Community 241 - "live_data_service.dart"
Cohesion: 0.02
Nodes (78): applySector, applySegment, applyStint, buildSpeed, Duration, empty, Exception, I1 (+70 more)

## Knowledge Gaps
- **1681 isolated node(s):** `createState`, `build`, `createState`, `build`, `email` (+1676 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1833 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **40 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Win32Window` connect `Win32Window` to `win32_window.cpp`, `flutter_window.h`, `FlutterWindow`, `MessageHandler`, `flutter_window.cpp`, `Point`, `Size`?**
  _High betweenness centrality (0.033) - this node is a cross-community bridge._
- **Why does `OnCreate` connect `Win32Window` to `FlutterWindow`, `windows/flutter/generated_plugin_registrant.cc`, `flutter_window.cpp`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Why does `RegisterPlugins()` connect `windows/flutter/generated_plugin_registrant.cc` to `Win32Window`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **What connects `createState`, `build`, `createState` to the rest of the system?**
  _1681 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `dashboard_page.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.012987012987012988 - nodes in this community are weakly interconnected._
- **Should `live_data.model.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.012578616352201259 - nodes in this community are weakly interconnected._
- **Should `my_application.cc` be split into smaller, more focused modules?**
  _Cohesion score 0.08275862068965517 - nodes in this community are weakly interconnected._