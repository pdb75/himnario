import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          width: double.infinity,
          child: Text('Acerca de', textAlign: TextAlign.center,),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: null,
            icon: Icon(Icons.search, size: 0.0,),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
            child: Text(
              'Himnos y cánticos del Evangelio',
              style: Theme.of(context).textTheme.title,
            ),
          ),
          Divider(color: Colors.grey, indent: 10.0, endIndent: 10.0, height: 0.0,),
          Container(
            height: 150.0,
            width: 150.0,
            padding: EdgeInsets.all(10.0),
            // decoration: BoxDecoration(
            //   border: Border.all(
            //     width: 5.0,
            //   ),
            //   borderRadius: BorderRadius.circular(20.0)
            // ),
            child: Image.asset('assets/logo.png')
          ),
          Padding(
            padding: EdgeInsets.only(left: 15.0, right: 15.0, top: 50.0, bottom: 10.0),
            child: Text(
              'Música y composición',
              style: Theme.of(context).textTheme.title,
            ),
          ),
          Divider(color: Colors.grey, indent: 10.0, endIndent: 10.0, height: 0.0,),
          Padding(
            padding: EdgeInsets.only(left: 30.0, right: 15.0, top: 10.0, bottom: 10.0),
            child: Text(
              'Francisco Cid Segovia\npxno.xd@gmail.com',
              style: Theme.of(context).textTheme.subtitle,
            ),
          ),
        ],
      ),
    );
  }
}