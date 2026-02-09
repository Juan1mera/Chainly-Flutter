import 'package:flutter/material.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/core/constants/fonts.dart';
import 'package:chainly/core/utils/favicon_getter.dart';

class TestsPage extends StatefulWidget {
  const TestsPage({super.key});

  @override
  State<TestsPage> createState() => _TestsPageState();
}

class _TestsPageState extends State<TestsPage> {
  // Controlador para el input
  final TextEditingController _urlController = TextEditingController();
  // Variable para guardar la URL de la imagen a mostrar
  String? _faviconUrl;

  void _getFavicon() {
    FocusScope.of(context).unfocus();

    final String input = _urlController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _faviconUrl = FaviconGetter.getFaviconUrl(input);
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text("Favicon Tester"),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bug_report_outlined,
              size: 80,
              color: AppColors.purple,
            ),
            const SizedBox(height: 24),
            Text(
              'Tests Page',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                fontFamily: AppFonts.clashDisplay,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Enter a URL to fetch its favicon.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.greyDark,
              ),
            ),
            const SizedBox(height: 32),

            // --- INPUT AREA ---
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Website URL',
                hintText: 'example.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.link),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: AppColors.purple),
                  onPressed: _getFavicon,
                ),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _getFavicon(),
            ),
            
            const SizedBox(height: 40),

            // --- FAVICON DISPLAY AREA ---
            if (_faviconUrl != null) ...[
              Text(
                "Result:",
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: AppColors.black
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Image.network(
                      _faviconUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                      // Constructor de error por si la URL no devuelve imagen válida
                      errorBuilder: (context, error, stackTrace) {
                        return Column(
                          children: const [
                            Icon(Icons.broken_image, size: 40, color: Colors.red),
                            SizedBox(height: 8),
                            Text("No icon found", style: TextStyle(fontSize: 12)),
                          ],
                        );
                      },
                      // Loading builder para mejorar la UX
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          width: 64, 
                          height: 64, 
                          child: CircularProgressIndicator(strokeWidth: 2)
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      _urlController.text,
                      style: TextStyle(fontSize: 12, color: AppColors.greyDark),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}