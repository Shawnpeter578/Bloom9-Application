// import 'dart:async';
// import 'package:appwrite/appwrite.dart';
// import 'package:bloom9/screens/health_profile_creation.dart';
// import 'package:bloom9/services/appwrite_service.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// class OtpScreen extends StatelessWidget {
//   const OtpScreen({super.key, required this.userId, required this.username, required this.email, required this.phone,  required this.password});
// final String userId;
// final String username;
// final String email;
// final String password;
// final String phone;
   

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         useMaterial3: true,
//         colorSchemeSeed: const Color(0xFF378ADD),
//       ),
//       home: OtpVerificationScreen(
//   userId: userId,
//   username: username,
//   email: email,
//   password: password,
//   phone: phone,
//   maskedDestination: phone,
//   onVerified: () {},
//   onResend: () async => Future.delayed(const Duration(seconds: 1)),
// ),
//     );
//   }
// }

// class OtpVerificationScreen extends StatefulWidget {
//   const OtpVerificationScreen({
//     super.key,
//     required this.userId,
//     required this.username,
//     required this.email,
//     required this.password,
//     required this.phone,
//     required this.maskedDestination,
//     required this.onVerified,
//     required this.onResend,
//     this.codeLength = 6,
//     this.resendCooldown = const Duration(seconds: 30),
//   });
//   final String userId;
//   final String username;
//   final String email;
//   final String password;
//   final String phone;
//   final String maskedDestination;
//   final VoidCallback onVerified;
//   final Future<void> Function() onResend;
//   final int codeLength;
//   final Duration resendCooldown;

//   @override
//   State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
// }

// class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
//   late final List<TextEditingController> _controllers;
//   late final List<FocusNode> _focusNodes;

//   Timer? _timer;
//   int _secondsLeft = 0;
//   String? _errorText;
//   bool _isVerifying = false;
//   bool _isVerified = false;


//   @override
//   void initState() {
//     super.initState();
//     _controllers = List.generate(widget.codeLength, (_) => TextEditingController());
//     _focusNodes = List.generate(widget.codeLength, (_) => FocusNode());
//     _startCooldown();
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     for (final c in _controllers) {
//       c.dispose();
//     }
//     for (final f in _focusNodes) {
//       f.dispose();
//     }
//     super.dispose();
//   }

//   void _startCooldown() {
//     setState(() => _secondsLeft = widget.resendCooldown.inSeconds);
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (t) {
//       if (_secondsLeft <= 1) {
//         t.cancel();
//         setState(() => _secondsLeft = 0);
//       } else {
//         setState(() => _secondsLeft--);
//       }
//     });
//   }

//   String get _code => _controllers.map((c) => c.text).join();

//   void _onDigitChanged(int index, String value) {
//     setState(() => _errorText = null);
//     if (value.isNotEmpty && index < widget.codeLength - 1) {
//       _focusNodes[index + 1].requestFocus();
//     }
//     if (_code.length == widget.codeLength && !_code.contains('')) {
//       _verify();
//     }
//   }

//   void _onBackspace(int index) {
//     if (_controllers[index].text.isEmpty && index > 0) {
//       _controllers[index - 1].clear();
//       _focusNodes[index - 1].requestFocus();
//     }
//   }

//   Future<void> _verify() async {
//     if (_code.length < widget.codeLength) {
//       setState(() => _errorText = 'Enter all ${widget.codeLength} digits.');
//       return;
//     }
//     setState(() {
//       _isVerifying = true;
//       _errorText = null;
//     });

//     await Future.delayed(const Duration(milliseconds: 400)); // simulate network call

//     if (!mounted) return;

//     try {
//   await AppwriteService.account.createPhoneToken(
//     userId: ID.unique(),
//   phone: "+91${widget.phone}",
//   );
//   await AppwriteService.account.createSession(
//   userId: widget.userId,
//   secret: _code,
// );
//   await AppwriteService.account.create(
//     userId: ID.unique(),
//     email: widget.email,
//     password: widget.password,
//     name: widget.username,
//   );

//   await AppwriteService.account.createEmailPasswordSession(
//     email: widget.email,
//     password: widget.password,
//   );

//   final user = await AppwriteService.account.get();

//   await AppwriteService.tablesDB.createRow(
//     databaseId: AppwriteService.databaseId,
//     tableId: AppwriteService.userTableId,
//     rowId: ID.unique(),
//     data: {
//       "userId": user.$id,
//       "userName": widget.username,
//       "email": widget.email,
//       "phone": widget.phone,
//       "phoneVerified": true,
//     },
//   );

//   if (!mounted) return;

//   Navigator.pushReplacement(
//     context,
//     MaterialPageRoute(
//       builder: (_) => HealthProfileScreen(
//         name: widget.username,
//       ),
//     ),
//   );
// } on AppwriteException catch (e) {
//   setState(() {
//     _isVerifying = false;
//     _errorText = e.message;
//   });

//   for (final c in _controllers) {
//     c.clear();
//   }

//   _focusNodes.first.requestFocus();
// }
//   }

//   Future<void> _resend() async {
//     await widget.onResend();
//     if (!mounted) return;
//     _startCooldown();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;

//     return Scaffold(
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: ConstrainedBox(
//               constraints: const BoxConstraints(maxWidth: 360),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     width: 48,
//                     height: 48,
//                     decoration: BoxDecoration(
//                       color: scheme.primaryContainer,
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(Icons.lock_outline, color: scheme.primary),
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     'Enter verification code',
//                     style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                           fontWeight: FontWeight.w600,
//                         ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text.rich(
//                     TextSpan(
//                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                             color: Theme.of(context).hintColor,
//                           ),
//                       children: [
//                         const TextSpan(text: 'We sent a 6-digit code to '),
//                         TextSpan(
//                           text: widget.maskedDestination,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.w600,
//                             color: Colors.black87,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 28),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: List.generate(widget.codeLength, (i) => _digitBox(i, scheme)),
//                   ),
//                   const SizedBox(height: 8),
//                   SizedBox(
//                     height: 20,
//                     child: _errorText != null
//                         ? Text(
//                             _errorText!,
//                             style: TextStyle(color: scheme.error, fontSize: 13),
//                           )
//                         : _isVerified
//                             ? Text(
//                                 'Code verified.',
//                                 style: TextStyle(color: Colors.green.shade700, fontSize: 13),
//                               )
//                             : null,
//                   ),
//                   const SizedBox(height: 16),
//                   SizedBox(
//                     width: double.infinity,
//                     height: 44,
//                     child: FilledButton(
//                       onPressed: _isVerifying || _isVerified ? null : _verify,
//                       child: _isVerifying
//                           ? const SizedBox(
//                               width: 18,
//                               height: 18,
//                               child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//                             )
//                           : Text(_isVerified ? 'Verified' : 'Verify code'),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Center(
//                     child: _secondsLeft > 0
//                         ? Text(
//                             'Resend code in 0:${_secondsLeft.toString().padLeft(2, '0')}',
//                             style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
//                           )
//                         : TextButton(
//                             onPressed: _resend,
//                             child: const Text('Resend code'),
//                           ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _digitBox(int index, ColorScheme scheme) {
//     final hasError = _errorText != null;
//     return SizedBox(
//       width: 44,
//       height: 52,
//       child: KeyboardListener(
//         focusNode: FocusNode(skipTraversal: true),
//         onKeyEvent: (event) {
//           if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
//             _onBackspace(index);
//           }
//         },
//         child: TextField(
//           controller: _controllers[index],
//           focusNode: _focusNodes[index],
//           textAlign: TextAlign.center,
//           keyboardType: TextInputType.number,
//           maxLength: 1,
//           enabled: !_isVerified,
//           style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
//           inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//           decoration: InputDecoration(
//             counterText: '',
//             contentPadding: EdgeInsets.zero,
//             filled: true,
//             fillColor: scheme.surfaceContainerHighest.withOpacity(0.3),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(color: hasError ? scheme.error : Colors.transparent),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(color: hasError ? scheme.error : Colors.transparent),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(color: scheme.primary, width: 2),
//             ),
//           ),
//           onChanged: (value) => _onDigitChanged(index, value),
//         ),
//       ),
//     );
//   }
// }