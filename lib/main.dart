import 'package:flutter/material.dart';
import 'utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(title: Text(
          'Home',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          )
        ),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child:
                      TextField(
                        controller: ipController,
                        decoration: InputDecoration(
                        hintText: 'xxx.xxx.xxx:xxxx'
                        )
                      )
                  ),
                  Expanded(child: ElevatedButton(onPressed: conectar,
                    child: Text('Conectar!!!')
                  )
                  )
                ]
              ),
              TextField(
                decoration: InputDecoration(
                  hintText: 'tap to search songs'
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: urlController,
                      decoration: InputDecoration(
                        hintText: 'Pega aquí la URL de YouTube'
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => addSong(urlController.text),
                    child: Text('Agregar')
                  )
                ],
              )
            ],
          ),
        )
      ),
    );
  }
}