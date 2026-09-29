import 'package:flutter/material.dart';
import 'package:form_dirty_state/form_dirty_state.dart';

void main() {
  runApp(const EditProfileApp());
}

class EditProfileApp extends StatelessWidget {
  const EditProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'form_dirty_state Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: FilledButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const EditProfileScreen(),
              ),
            );
          },
          child: const Text('Edit Profile'),
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Initial profile data loaded from server
  static const Map<String, dynamic> _initialProfileData = {
    'name': 'Raj Kumar Timalsina',
    'email': 'raj@example.com',
    'phone': '+977 9800000000',
    'city': 'Kathmandu',
  };

  late final DirtyFormController _formController;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // 1. Initialize DirtyFormController with baseline data
    _formController = DirtyFormController(
      initialValues: _initialProfileData,
      onChanged: (_) {
        // Triggers UI rebuild when dirty state or field values change
        if (mounted) setState(() {});
      },
    );

    // Initialize text editing controllers
    _nameController = TextEditingController(
      text: _formController.getValue('name') as String? ?? '',
    );
    _emailController = TextEditingController(
      text: _formController.getValue('email') as String? ?? '',
    );
    _phoneController = TextEditingController(
      text: _formController.getValue('phone') as String? ?? '',
    );
    _cityController = TextEditingController(
      text: _formController.getValue('city') as String? ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  // 6. Simulate API save request
  Future<void> _handleSave() async {
    if (!_formController.isDirty) return;

    setState(() => _isSaving = true);

    // Simulate 750ms network delay for HTTP PATCH /api/profile
    await Future<void>.delayed(const Duration(milliseconds: 750));

    if (!mounted) return;

    // 7. Commit active state as the new baseline
    _formController.markSaved();

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Profile saved successfully! Changes committed as new baseline.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // 8. Revert all inputs to the baseline state
  void _handleReset() {
    _formController.reset();

    // Update UI input text fields to match restored baseline
    _nameController.text = _formController.getValue('name') as String? ?? '';
    _emailController.text = _formController.getValue('email') as String? ?? '';
    _phoneController.text = _formController.getValue('phone') as String? ?? '';
    _cityController.text = _formController.getValue('city') as String? ?? '';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form reverted to original baseline.'),
      ),
    );
  }

  // 9. Prompt discard dialog if user attempts to leave with unsaved changes
  Future<bool> _onWillPop() async {
    if (!_formController.isDirty) {
      return true; // No unsaved changes, allow leave immediately
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Discard unsaved changes?'),
        content: Text(
          'You have unsaved changes in ${_formController.dirtyFields.join(", ")}. '
          'If you leave now, your modifications will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDirty = _formController.isDirty;
    final dirtyFields = _formController.dirtyFields;
    final changes = _formController.changes;

    return PopScope(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _onWillPop();
        if (shouldLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          actions: [
            // Status chip in App Bar
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Chip(
                avatar: Icon(
                  isDirty ? Icons.edit_note : Icons.check_circle_outline,
                  size: 16,
                  color:
                      isDirty ? Colors.amber.shade900 : Colors.green.shade800,
                ),
                label: Text(
                  isDirty ? 'Unsaved changes' : 'Saved',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        isDirty ? Colors.amber.shade900 : Colors.green.shade800,
                  ),
                ),
                backgroundColor:
                    isDirty ? Colors.amber.shade100 : Colors.green.shade100,
                side: BorderSide.none,
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Field 1: Name
            _buildField(
              keyName: 'name',
              label: 'Full Name',
              controller: _nameController,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),

            // Field 2: Email
            _buildField(
              keyName: 'email',
              label: 'Email Address',
              controller: _emailController,
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),

            // Field 3: Phone
            _buildField(
              keyName: 'phone',
              label: 'Phone Number',
              controller: _phoneController,
              icon: Icons.phone_outlined,
            ),
            const SizedBox(height: 16),

            // Field 4: City
            _buildField(
              keyName: 'city',
              label: 'City',
              controller: _cityController,
              icon: Icons.location_city_outlined,
            ),
            const SizedBox(height: 24),

            // Action Buttons: Save & Reset
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isDirty && !_isSaving ? _handleReset : null,
                    icon: const Icon(Icons.undo),
                    label: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isDirty && !_isSaving ? _handleSave : null,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 10. Developer / Inspection Panel
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bug_report_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'DirtyFormController Live Inspector',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text('• isDirty: $isDirty'),
                    const SizedBox(height: 4),
                    Text(
                        '• dirtyFields: ${dirtyFields.isEmpty ? 'none' : dirtyFields.join(", ")}'),
                    const SizedBox(height: 4),
                    Text('• pending changes (diff): $changes'),
                    const SizedBox(height: 4),
                    Text(
                        '• baseline initialValues: ${_formController.initialValues}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String keyName,
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    final isFieldDirty = _formController.isFieldDirty(keyName);

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: isFieldDirty
            ? const Tooltip(
                message: 'Field modified',
                child: Icon(Icons.circle, size: 10, color: Colors.amber),
              )
            : null,
        border: const OutlineInputBorder(),
        helperText: isFieldDirty
            ? 'Original: "${_formController.getInitialValue(keyName)}"'
            : null,
        helperStyle: TextStyle(
          color: Colors.amber.shade900,
          fontStyle: FontStyle.italic,
        ),
      ),
      onChanged: (text) {
        // 3. Update the DirtyFormController on each input change
        _formController.update(keyName, text.trim());
      },
    );
  }
}
