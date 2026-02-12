import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_mate_app/presentation/auth/signup_screen.dart';
import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/core/services/auth_service.dart';

/// 로그인 화면. 이메일/비밀번호, Google 로그인 지원.
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final user = await authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (user != null) {
          context.go('/'); // Navigate to home on success
        } else {
          setState(() {
            _errorMessage = 'Login failed. Please check your credentials.';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().contains('firebase_auth')
              ? 'Invalid credentials. Please try again.'
              : 'An unexpected error occurred: ${e.toString()}';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.signInWithGoogle();

      if (user != null) {
        context.go('/'); // Navigate to home on success
      } else {
        setState(() {
          _errorMessage = 'Google Sign-In cancelled or failed.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google Sign-In failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingLarge),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.spacingMedium),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.spacingLarge),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      ),
                    ),
                    child: Text(
                      'Login',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingMedium),
                TextButton(
                  onPressed: () {
                    // TODO: Implement forgot password logic
                    print('Forgot Password?');
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(color: AppColors.accent),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingLarge),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
                      child: Text(
                        'OR',
                        style: TextStyle(color: AppColors.grey),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingLarge),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loginWithGoogle,
                    icon: Image.asset(
                      'images/google_logo.png',
                      height: 24.0,
                      width: 24.0,
                    ),
                    label: Text(
                      'Sign in with Google',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      ),
                      side: BorderSide(color: AppColors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingLarge),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        context.go('/signup'); // Navigate to signup screen
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(color: AppColors.accent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
