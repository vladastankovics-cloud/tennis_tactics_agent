import 'package:flutter/material.dart';
import 'package:tennis_tactics_agent/config/app_config.dart';
import 'package:tennis_tactics_agent/config/constants.dart';
import 'package:tennis_tactics_agent/main.dart';

/// Screen for initial API key setup
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final AppConfig _config = AppConfig();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscureText = true;
  String _selectedModel = GeminiModels.flash20;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  /// Save API key and navigate to home screen
  Future<void> _saveAndContinue() async {
    final apiKey = _apiKeyController.text.trim();

    // Validate API key format
    if (apiKey.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your API key';
      });
      return;
    }

    if (!_config.isValidGeminiApiKeyFormat(apiKey)) {
      setState(() {
        _errorMessage =
            'Invalid API key format. Key should start with "AIza"';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Save API key and model preference
      await _config.setGeminiApiKey(apiKey);
      await _config.setGeminiModel(_selectedModel);

      if (!mounted) return;

      // Navigate to home screen (Plan section)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save API key: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App icon/logo
                Icon(
                  Icons.sports_tennis,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Tennis Tactics App',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'AI-powered tennis strategy and coaching',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // API Key input
                TextField(
                  controller: _apiKeyController,
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key',
                    hintText: 'AIza...',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.key),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                    errorText: _errorMessage,
                  ),
                  obscureText: _obscureText,
                  autocorrect: false,
                  enableSuggestions: false,
                  onSubmitted: (_) => _saveAndContinue(),
                ),
                const SizedBox(height: 16),

                // Model selection
                DropdownButtonFormField<String>(
                  initialValue: _selectedModel,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.psychology),
                  ),
                  items: GeminiModels.all.map((model) {
                    return DropdownMenuItem(
                      value: model,
                      child: Text(GeminiModels.getDisplayName(model)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedModel = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),

                // Model description
                Padding(
                  padding: const EdgeInsets.only(left: 48.0),
                  child: Text(
                    GeminiModels.getDescription(_selectedModel),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Continue button
                FilledButton.icon(
                  onPressed: _isLoading ? null : _saveAndContinue,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: Text(_isLoading ? 'Setting up...' : 'Continue'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 32),

                // Help text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Getting Started',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '1. Get your API key from aistudio.google.com\n'
                        '2. Enter the key above (starts with AIza)\n'
                        '3. Choose your preferred model\n'
                        '4. Start getting tennis coaching advice!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
