import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Díky za feedback!')), 
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _message,
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Popiš svůj nápad nebo problém...',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Napiš prosím zprávu' : null,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submit,
                child: const Text('Odeslat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


