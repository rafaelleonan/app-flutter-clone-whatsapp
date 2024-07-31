import 'package:flutter/material.dart';
import 'package:app_whatsapp/model/Usuario.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AbaContatos extends StatefulWidget {
  @override
  _AbaContatosState createState() => _AbaContatosState();
}

class _AbaContatosState extends State<AbaContatos> {
  late String _emailUsuarioLogado;
  List<Usuario> listaUsuarios = [];
  final String _imgDefault = "https://firebasestorage.googleapis.com/v0/b/appwhatsapp-f5c17.appspot.com/o/perfil%2Fdefault_profile.png?alt=media&token=15b14474-c374-4e8a-a38f-2de475b79924";

  Future<List<Usuario>> _recuperarContatos() async {
    FirebaseFirestore db = FirebaseFirestore.instance;

    QuerySnapshot querySnapshot =
        await db.collection("usuarios").get();

    for (DocumentSnapshot item in querySnapshot.docs) {
      var dados = item.data() as Map;
      if( dados["email"] == _emailUsuarioLogado ) continue;

      Usuario usuario = Usuario();
      usuario.idUsuario = item.id;
      usuario.email = dados["email"];
      usuario.nome = dados["nome"];
      usuario.urlImagem = dados["urlImagem"] ?? _imgDefault;

      listaUsuarios.add(usuario);
    }

    return listaUsuarios;
  }

  _recuperarDadosUsuario() {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? usuarioLogado = auth.currentUser;
    _emailUsuarioLogado = usuarioLogado!.email ?? "";
  }

  @override
  void initState() {
    super.initState();
    _recuperarDadosUsuario();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Usuario>>(
      future: _recuperarContatos(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return const Center(
              child: Column(
                children: <Widget>[
                  Text("Carregando contatos"),
                  CircularProgressIndicator()
                ],
              ),
            );
          case ConnectionState.active:
          case ConnectionState.done:

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text("Nenhum contato encontrado"),
              );
            }

            return ListView.builder(
                itemCount: snapshot.data?.length,
                itemBuilder: (_, indice) {

                  List<Usuario>? listaItens = snapshot.data;
                  Usuario usuario = listaItens![indice];

                  return ListTile(
                    onTap: (){
                      Navigator.pushNamed(
                          context,
                          "/mensagens",
                        arguments: usuario
                      );
                    },
                    contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    leading: CircleAvatar(
                        maxRadius: 30,
                        backgroundColor: Colors.grey,
                        backgroundImage: usuario.urlImagem != null
                            ? NetworkImage(usuario.urlImagem)
                            : null),
                    title: Text(
                      usuario.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  );
                });
        }
      },
    );
  }
}
