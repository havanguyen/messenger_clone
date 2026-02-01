import 'package:flutter/material.dart';
import 'package:messenger_clone/core/utils/custom_theme_extension.dart';
import 'package:provider/provider.dart';

import 'package:messenger_clone/theme/theme_provider.dart';
import 'package:messenger_clone/core/widgets/custom_text_style.dart';

class SystemThemeSettingsPage extends StatefulWidget {
  const SystemThemeSettingsPage({super.key});

  @override
  State<SystemThemeSettingsPage> createState() =>
      _SystemThemeSettingsPageState();
}

class _SystemThemeSettingsPageState extends State<SystemThemeSettingsPage> {
  ThemeMode? _selectedThemeMode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    setState(() {
      _selectedThemeMode = themeProvider.themeNotifier.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: context.theme.textColor,
          onPressed: () => Navigator.pop(context),
        ),
        title: const TitleText(
          "Dark mode",
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: context.theme.bg,
      ),
      body: Container(
        decoration: BoxDecoration(color: context.theme.bg),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioListTile<ThemeMode>(
                title: const TitleText(
                  "Off",
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                value: ThemeMode.light,
                groupValue: _selectedThemeMode,
                onChanged: (value) {
                  setState(() {
                    _selectedThemeMode = value;
                  });
                  themeProvider.setTheme(ThemeMode.light);
                },
                activeColor: context.theme.blue,
                tileColor: context.theme.grey,
              ),
              RadioListTile<ThemeMode>(
                title: const TitleText(
                  "On",
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                value: ThemeMode.dark,
                groupValue: _selectedThemeMode,
                onChanged: (value) {
                  setState(() {
                    _selectedThemeMode = value;
                  });
                  themeProvider.setTheme(ThemeMode.dark);
                },
                activeColor: context.theme.blue,
                tileColor: context.theme.grey,
              ),
              RadioListTile<ThemeMode>(
                title: const TitleText(
                  "System",
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                value: ThemeMode.system,
                groupValue: _selectedThemeMode,
                onChanged: (value) {
                  setState(() {
                    _selectedThemeMode = value;
                  });
                  themeProvider.setTheme(ThemeMode.system);
                },
                activeColor: context.theme.blue,
                tileColor: context.theme.grey,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
