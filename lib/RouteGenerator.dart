import 'package:flutter/material.dart';

import 'Cadastro.dart';
import 'Configuracoes.dart';
import 'Home.dart';
import 'Login.dart';
import 'Mensagens.dart';
import 'model/Usuario.dart';

class RouteGenerator {

  static Route<dynamic> generateRoute(RouteSettings settings){

    final args = settings.arguments;

    switch( settings.name ){
      case "/":
        return MaterialPageRoute(
          builder: (_) => Login()
        );
      case "/login":
        return MaterialPageRoute(
            builder: (_) => Login()
        );
      case "/cadastro":
        return MaterialPageRoute(
            builder: (_) => Cadastro()
        );
      case "/home":
        return MaterialPageRoute(
            builder: (_) => Home()
        );
      case "/configuracoes":
        return MaterialPageRoute(
            builder: (_) => Configuracoes()
        );
      case "/mensagens":
        Usuario user = Usuario();
        if (args != null) {
          user = args as Usuario;
        }

        return MaterialPageRoute(
            builder: (_) => Mensagens(user)
        );
      default:
        return _erroRota();
    }

  }

  static Route<dynamic> _erroRota(){
    return MaterialPageRoute(
      builder: (_){
        return Scaffold(
          appBar: AppBar(title: const Text("Tela não encontrada!"),),
          body: const Center(
            child: Text("Tela não encontrada!"),
          ),
        );
      }
    );
  }
}