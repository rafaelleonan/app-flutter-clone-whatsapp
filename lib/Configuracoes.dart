import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class Configuracoes extends StatefulWidget {
  @override
  _ConfiguracoesState createState() => _ConfiguracoesState();
}

class _ConfiguracoesState extends State<Configuracoes> {

  final TextEditingController _controllerNome = TextEditingController();
  late File _imagem;
  late String _idUsuarioLogado;
  bool _subindoImagem = false;
  String? _urlImagemRecuperada;
  String _imageDefault = "https://firebasestorage.googleapis.com/v0/b/appwhatsapp-f5c17.appspot.com/o/perfil%2Fdefault_profile.png?alt=media&token=15b14474-c374-4e8a-a38f-2de475b79924";

  Future<void> _recuperarImagem(String origemImagem) async {
    final ImagePicker img = ImagePicker();
    XFile? imagemSelecionada;
    try {
      switch (origemImagem) {
        case "camera":
          imagemSelecionada = await img.pickImage(source: ImageSource.camera);
          break;
        case "galeria":
          imagemSelecionada = await img.pickImage(source: ImageSource.gallery);
          break;
      }

      if (imagemSelecionada != null) {
        setState(() {
          _imagem = File(imagemSelecionada!.path);
          if (_imagem.lengthSync() > 0) {
            _subindoImagem = true;
            _uploadImagem();
          }
        });
      }
    } catch (e) {
      print("Erro ao recuperar imagem: $e");
    }
  }

  Future _uploadImagem() async {

    FirebaseStorage storage = FirebaseStorage.instance;
    Reference pastaRaiz = storage.ref();
    Reference arquivo = pastaRaiz
      .child("perfil")
      .child("$_idUsuarioLogado.jpg");

    //Upload da imagem
    UploadTask task = arquivo.putFile(_imagem);

    task.snapshotEvents.listen((TaskSnapshot snapshot) {
      switch (snapshot.state) {
        case TaskState.running:
          setState(() {
            _subindoImagem = true;
          });
          break;
        case TaskState.paused:
          break;
        case TaskState.success:
          setState(() {
            _subindoImagem = false;
          });
          break;
        case TaskState.canceled:
          break;
        case TaskState.error:
          break;
      }
    });

    //Recuperar url da imagem
    TaskSnapshot snapshot = await task;
    _recuperarUrlImagem(snapshot);
  }

  Future _recuperarUrlImagem(TaskSnapshot snapshot) async {
    String url = await snapshot.ref.getDownloadURL();
    _atualizarUrlImagemFirestore( url );

    setState(() {
      _urlImagemRecuperada = url;
    });
  }

  _atualizarNomeFirestore(){
    String nome = _controllerNome.text;
    FirebaseFirestore db = FirebaseFirestore.instance;

    Map<String, dynamic> dadosAtualizar = {
      "nome" : nome
    };

    db.collection("usuarios")
        .doc(_idUsuarioLogado)
        .update( dadosAtualizar );
  }

  _atualizarUrlImagemFirestore(String url){
    FirebaseFirestore db = FirebaseFirestore.instance;

    Map<String, dynamic> dadosAtualizar = {
      "urlImagem" : url
    };
    
    db.collection("usuarios")
    .doc(_idUsuarioLogado)
    .update( dadosAtualizar );
  }

  _recuperarDadosUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? usuarioLogado = auth.currentUser;
    _idUsuarioLogado = usuarioLogado!.uid;

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot snapshot = await db.collection("usuarios")
      .doc( _idUsuarioLogado )
      .get();

    if (snapshot.exists && snapshot.data() != null) {
      Map<String, dynamic>? dados = snapshot.data() as Map<String, dynamic>?;

      if (dados != null) {
        _controllerNome.text = dados["nome"] ?? "";

        if (dados["urlImagem"] != null) {
          setState(() {
            if (dados["urlImagem"].length > 0) {
              _urlImagemRecuperada = dados["urlImagem"];
            }

            if (_urlImagemRecuperada == null || _urlImagemRecuperada!.isEmpty) {
              _urlImagemRecuperada = _imageDefault;
            }
          });
        } else {
          setState(() {
            _urlImagemRecuperada = _imageDefault;
          });
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _recuperarDadosUsuario();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configurações"),),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  child: _subindoImagem
                      ? const CircularProgressIndicator()
                      : Container(),
                ),
                _urlImagemRecuperada == null
                    ? const CircularProgressIndicator()
                    : CircleAvatar(
                  radius: 100,
                  backgroundColor: Colors.grey,
                  backgroundImage: NetworkImage(_urlImagemRecuperada!),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextButton(
                      child: const Text("Câmera"),
                      onPressed: (){
                        _recuperarImagem("camera");
                      },
                    ),
                    TextButton(
                      child: const Text("Galeria"),
                      onPressed: (){
                        _recuperarImagem("galeria");
                      },
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _controllerNome,
                    autofocus: true,
                    keyboardType: TextInputType.text,
                    style: const TextStyle(fontSize: 20),
                    /*onChanged: (texto){
                      _atualizarNomeFirestore(texto);
                    },*/
                    decoration: InputDecoration(
                        contentPadding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                        hintText: "Nome",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 10),
                  child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: const WidgetStatePropertyAll(Colors.green),
                        padding: const WidgetStatePropertyAll(EdgeInsets.fromLTRB(32, 16, 32, 16)),
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32))),
                      ),
                      onPressed: () {
                        _atualizarNomeFirestore();
                      },
                    child: const Text(
                      "Salvar",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
