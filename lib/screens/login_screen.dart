import 'package:flutter/material.dart';
// Импорт модели сообщения
import '../services/auth_service.dart';
import 'chat_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService auth;

  const LoginScreen({Key? key, required this.auth}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum LoginMode { mainMenu, pinLogin, register, deleteUser }

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _pinController = TextEditingController();

  String _outputMessage = "";
  LoginMode _mode = LoginMode.mainMenu;

  void _setMode(LoginMode mode) {
    setState(() {
      _mode = mode;
      _outputMessage = "";
    });
  }

  Future<void> _loginUser() async {
    final pin = _pinController.text.trim();
    if (await widget.auth.login(pin)) {
      _openChat();
    } else {
      setState(() => _outputMessage = "Неверный PIN");
    }
  }

  Future<void> _registerUser() async {
    final username = _usernameController.text.trim();
    final key = _apiKeyController.text.trim();
    final result = await widget.auth.register(username, key);

    if (result["code"] == 200) {
      setState(() {
        _outputMessage =
            "Регистрация пройдена.\nВаш PIN-код: ${result['content']['pin']}";
      });
    } else {
      setState(() => _outputMessage = result["message"]);
    }
  }

  Future<void> _deleteUser() async {
    final username = _usernameController.text.trim();
    await widget.auth.delUser(username);
    setState(() {
      _outputMessage = "Пользователь удалён.";
    });
  }

  void _openChat() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    switch (_mode) {
      case LoginMode.mainMenu:
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Выберите действие:"),
            ElevatedButton(
                onPressed: () => _setMode(LoginMode.pinLogin),
                child: const Text("Войти по PIN")),
            ElevatedButton(
                onPressed: () => _setMode(LoginMode.register),
                child: const Text("Зарегистрироваться")),
          ],
        );
        break;

      case LoginMode.pinLogin:
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Вход по PIN"),
            TextField(
              controller: _pinController,
              decoration: const InputDecoration(labelText: "PIN-код"),
              keyboardType: TextInputType.number,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: _loginUser, child: const Text("Войти")),
                const SizedBox(width: 8),
                ElevatedButton(
                    onPressed: () => _setMode(LoginMode.deleteUser),
                    child: const Text("Сбросить пароль")),
              ],
            ),
            TextButton(
                onPressed: () => _setMode(LoginMode.mainMenu),
                child: const Text("Назад")),
            Text(_outputMessage),
          ],
        );
        break;

      case LoginMode.register:
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Регистрация"),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "Имя пользователя"),
            ),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(labelText: "API-ключ (OpenRouter или VSEGPT)"),
            ),
            ElevatedButton(
                onPressed: _registerUser,
                child: const Text("Зарегистрироваться")),
            TextButton(
                onPressed: () => _setMode(LoginMode.mainMenu),
                child: const Text("Назад")),
            Text(_outputMessage),
          ],
        );
        break;

      case LoginMode.deleteUser:
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Введите имя пользователя для сброса"),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "Имя пользователя"),
            ),
            ElevatedButton(
                onPressed: _deleteUser, child: const Text("Сбросить PIN")),
            TextButton(
                onPressed: () => _setMode(LoginMode.pinLogin),
                child: const Text("Назад")),
            Text(_outputMessage),
          ],
        );
        break;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Авторизация")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: SingleChildScrollView(child: content)),
      ),
    );
  }
}