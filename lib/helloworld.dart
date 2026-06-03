import 'package:flutter/material.dart';



class hello_world extends StatefulWidget {
  @override
  State<hello_world> createState() => _hello_worldState();
}

class _hello_worldState extends State<hello_world> {
  @override
  int _counter = 0;

  void _increment() {
    setState(() {
      _counter++;
    });
  }
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF00D09E),
      appBar: AppBar(
        leading: const IconButton(
          icon: Icon(Icons.menu),
          tooltip: 'Navigation menu',
          onPressed: null,
        ),
        title: ElevatedButton(onPressed: _increment, child: Container(
          height : 30,
          width: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Colors.yellow,
          ),
        ),),
        actions: const [
          IconButton(
            icon: Icon(Icons.search),
            tooltip: 'Search',
            onPressed: null,
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            tooltip: 'More',
            onPressed: null,
          ),
        ],
      ),
      body: Text(
              'Hello World ' + _counter.toString(),
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                color: Colors.yellow,
              ),
      ),
    );
  }
}


 