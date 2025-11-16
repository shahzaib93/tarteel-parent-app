import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  final Future<Map<String, dynamic>> Function(String email, String password) onLogin;
  final String? error;

  const LoginScreen({super.key, required this.onLogin, this.error});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _statusMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.error;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    Future.delayed(const Duration(seconds: 10), () {
      if (_loading && mounted) {
        setState(() {
          _statusMessage = 'Login is taking longer than expected... Please check your internet connection.';
        });
      }
    });

    try {
      final result = await widget.onLogin(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        if (result['success'] != true) {
          setState(() {
            _errorMessage = result['error']?.toString() ?? 'Login failed';
            _statusMessage = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred';
          _statusMessage = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Widget _buildHeroSection({bool isMobile = false}) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isMobile ? 100 : 120,
              height: isMobile ? 100 : 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.white.withOpacity(0.2),
                      child: Icon(
                        Icons.family_restroom,
                        size: isMobile ? 50 : 60,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: isMobile ? 20 : 24),
            Text(
              'Tarteel-e-Quran',
              style: TextStyle(
                fontSize: isMobile ? 28 : 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Parent Portal',
              style: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            if (!isMobile) ...[
              const SizedBox(height: 16),
              Text(
                'Monitor your child\'s learning journey',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobileForm() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Email field with modern styling
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enabled: !_loading,
              style: const TextStyle(fontSize: 15),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'your@email.com',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.email_outlined, color: Color(0xFF667eea), size: 20),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Password field with modern styling
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              enabled: !_loading,
              style: const TextStyle(fontSize: 15),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lock_outline, color: Color(0xFF667eea), size: 20),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Modern gradient button
            Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: _loading
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                color: _loading ? Colors.grey.shade400 : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _loading
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _loading ? null : _handleSubmit,
                  borderRadius: BorderRadius.circular(14),
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Decorative divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Tarteel-e-Quran',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm({bool isDesktop = false}) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: isDesktop
              ? BorderRadius.circular(32)
              : const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: isDesktop ? MainAxisSize.min : MainAxisSize.max,
            children: [
              if (isDesktop) ...[
                const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome back! Please enter your credentials.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (_statusMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enabled: !_loading,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Colors.grey.shade600,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF76a6f6), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                enabled: !_loading,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Colors.grey.shade600,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF76a6f6), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF76a6f6),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    elevation: _loading ? 0 : 4,
                    shadowColor: const Color(0xFF76a6f6).withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;

              if (isDesktop) {
                // Desktop horizontal layout
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left side - Hero
                        Flexible(
                          flex: 1,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 500),
                            padding: const EdgeInsets.all(48),
                            child: _buildHeroSection(),
                          ),
                        ),
                        const SizedBox(width: 48),
                        // Right side - Form
                        Flexible(
                          flex: 1,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 450),
                            child: _buildLoginForm(isDesktop: true),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                // Mobile vertical layout
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        // Compact hero for mobile
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                          child: _buildHeroSection(isMobile: true),
                        ),
                        // Enhanced mobile form
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 20,
                                offset: Offset(0, -4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Welcome text for mobile
                                const Text(
                                  'Welcome Back',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Sign in to continue monitoring',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildMobileForm(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
