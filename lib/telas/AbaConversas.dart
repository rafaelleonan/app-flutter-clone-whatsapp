import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_whatsapp/model/Usuario.dart';

class AbaConversas extends StatefulWidget {
  @override
  _AbaConversasState createState() => _AbaConversasState();
}

class _AbaConversasState extends State<AbaConversas> {
  final _controller = StreamController<QuerySnapshot>.broadcast();
  FirebaseFirestore db = FirebaseFirestore.instance;
  late String _idUsuarioLogado, _emailUsuarioLogado;
  List<Usuario> listaUsuarios = [];
  final String _imgDefault = "https://firebasestorage.googleapis.com/v0/b/appwhatsapp-f5c17.appspot.com/o/perfil%2Fdefault_profile.png?alt=media&token=15b14474-c374-4e8a-a38f-2de475b79924";

  Future<void> _recuperarContatos() async {
    FirebaseFirestore db = FirebaseFirestore.instance;

    QuerySnapshot querySnapshot = await db.collection("usuarios").get();

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
  }

  @override
  void initState() {
    super.initState();
    _recuperarDadosUsuario();
  }

  Stream<QuerySnapshot> _adicionarListenerConversas(){

    final stream = db.collection("conversas")
        .doc( _idUsuarioLogado )
        .collection("ultima_conversa")
        .snapshots();

    stream.listen((dados){
      _controller.add( dados );
    });
    return stream;
  }

  _recuperarDadosUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? usuarioLogado = auth.currentUser;
    _idUsuarioLogado = usuarioLogado!.uid;
    _emailUsuarioLogado = usuarioLogado.email ?? "";

    await _recuperarContatos();
    _adicionarListenerConversas();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.close();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _controller.stream,
      builder: (context, snapshot){
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return const Center(
              child: Column(
                children: <Widget>[
                  Text("Carregando conversas"),
                  CircularProgressIndicator()
                ],
              ),
            );
          case ConnectionState.active:
          case ConnectionState.done:
            if (snapshot.hasError) {
              return const Center(
                child: Text("Erro ao carregar os dados!"),
              );
            }else{
              QuerySnapshot? querySnapshot = snapshot.data;

              if( querySnapshot!.docs.isEmpty ){
                return const Center(
                  child: Text(
                    "Você não tem nenhuma mensagem ainda :( ",
                  ),
                );
              }
              return ListView.builder(
                  itemCount: querySnapshot.docs.length,
                  itemBuilder: (context, indice){
                    List<DocumentSnapshot> conversas = querySnapshot.docs.toList();
                    DocumentSnapshot item = conversas[indice];

                    String urlImagem;
                    String tipo;
                    String mensagem;
                    String nome;
                    String idDestinatario;

                    if (item["idRemetente"] == _idUsuarioLogado) {
                      Usuario user = listaUsuarios.firstWhere((Usuario user) => user.idUsuario == item["idDestinatario"]);
                      urlImagem  = user.urlImagem;
                      tipo       = item["tipoMensagem"];
                      mensagem   = item["mensagem"];
                      nome       = user.nome;
                      idDestinatario = user.idUsuario;
                    } else {
                      urlImagem  = item["caminhoFoto"];
                      tipo       = item["tipoMensagem"];
                      mensagem   = item["mensagem"];
                      nome       = item["nome"];
                      idDestinatario = item["idRemetente"];
                    }

                    Usuario usuario = Usuario();
                    usuario.nome = nome;
                    usuario.urlImagem = urlImagem;
                    usuario.idUsuario = idDestinatario;

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
                        backgroundImage: urlImagem!=null
                            ? NetworkImage( urlImagem )
                            : null,
                      ),
                      title: Text(
                        nome,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16
                        ),
                      ),
                      subtitle: Text(
                          tipo=="texto"
                              ? mensagem
                              : "Imagem...",
                          style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14
                          )
                      ),
                    );
                  }
              );
            }
        }
      },
    );
  }
}
