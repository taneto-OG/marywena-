import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MariWena',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        brightness: Brightness.dark,
      ),
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class Effects
{
  List<dynamic> positive;
  List<dynamic> negative;
  List<dynamic> medical;

  Effects({this.positive, this.negative, this.medical});

  factory Effects.fromJson(dynamic json)
  {
   return Effects(
      positive: json['positive'],
      negative: json['negative'],
      medical: json['medical'],
    ); 
  }
}

class Flavors
{
  List<dynamic> f;

  Flavors({this.f});

  factory Flavors.fromJson(dynamic json)
  {
   return Flavors(
      f: json[0],
    ); 
  }
}

class WeedBreed{
  int id;
  String name;
  String race;
  String desc;
  Flavors f;
  Effects e;

  WeedBreed({this.id, this.name, this.race, this.desc, this.f, this.e});

  factory WeedBreed.fromJson(Map<String, dynamic> json)
  {
    return WeedBreed(
      id: json['id'] as int,
      name: json['name'] as String,
      race: json['race'] as String,
      desc: json['desc'] as String,
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  String _input = "";
  bool _details = false;
  int _id = 0;
  String _name;

  _launchSupportUrl() async {
    const url = 'https://www.instagram.com/jotalevi/';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  void _updateField(text, int id, String name) {
    setState(() {
      if (id != 0)
        _details = true;
      else
        _details = false;
      
      _id = id;
      _input = text;
      _name = name;
    });
  }

  //get general info from web
  List<WeedBreed> parseResult(String responseBody) {
    final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
    var returnable = parsed.map<WeedBreed>((json) => WeedBreed.fromJson(json)).toList();
    if (returnable == null)
      return [];
    else
      return returnable;
  }

  Future<List<WeedBreed>> _getInfoFromSearchResult(String input, http.Client client) async {
    if (input == "")
      return [];

    final response = await client.get('https://strainapi.evanbusse.com/3idwVwu/strains/search/name/' + input);
    if (parseResult(response.body) == null)
      return [];
    else
      return parseResult(response.body);
  }

  //get info ID BASED
  Effects parseResultNlEffects(String responseBody) {
    final e = json.decode(responseBody);
    print (e);
    if (Effects.fromJson(e) == null)
      return Effects();
    else
      return Effects.fromJson(e);
  }

  Flavors parseResultNlFlavors(String responseBody) {
    if (jsonDecode(responseBody).cast<Flavors, String>() == null)
      return Flavors();
    else
      return jsonDecode(responseBody).cast<Flavors, String>();
  }

  Future<WeedBreed> _getDetailsFromId(int id, String name, http.Client client) async {
    if (id == 0)
      return null;

    final jEffects = json.decode((await client.get('https://strainapi.evanbusse.com/3idwVwu/strains/data/effects/' + id.toString())).body);
    Effects efects = Effects(
      positive: jEffects['positive'],
      negative: jEffects['negative'],
      medical: jEffects['medical'],
    );

    final jFlavor = json.decode((await client.get('https://strainapi.evanbusse.com/3idwVwu/strains/data/flavors/' + id.toString())).body);
    Flavors flavors = Flavors(f: jFlavor);

    return WeedBreed(
      name: name,
      e: efects,
      f: flavors,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_details)
    {
      return Scaffold(
        body: Center(
          child: FutureBuilder<WeedBreed>(
            future: _getDetailsFromId(_id, _name, http.Client()),
            builder: (context, snapshot) {
              if (snapshot.hasError) print(snapshot.error);
              return snapshot.hasData
                ? BreedDetails(breed: snapshot.data, extracontext: this)
                : Center(child: CircularProgressIndicator());
            },
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Card(
          elevation: 1,
          margin: EdgeInsets.only(
            top: 5,
            right: 5,
            bottom: 5,
            left: 5,
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height / 20,
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Search...',
                    ),
                    onChanged: (text) {
                      _updateField(text, 0, "");
                    },
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<WeedBreed>>(
                    future: _getInfoFromSearchResult(_input, http.Client()),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) print(snapshot.error);
                      return snapshot.hasData
                        ? BreedList(breeds: snapshot.data, extracontext: this)
                        : Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
                Container(
                    height: 100.0,
                    width: MediaQuery.of(context).size.width,
                    child: Card(
                      color: Colors.green[900],
                      elevation: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center ,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.ios_share,
                            ), 
                            onPressed: (){
                              Share.share("Chek out this crazy app, you're going to like it http://3.129.42.20/");
                            }
                          ),
                          Container(
                            padding: EdgeInsets.only(
                              right: MediaQuery.of(context).size.width * .10,
                              left: MediaQuery.of(context).size.width * .10,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.favorite,
                            ), 
                            onPressed: (){
                              _launchSupportUrl();
                            }
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class BreedDetails extends StatelessWidget
{
  final WeedBreed breed;
  final _MyHomePageState extracontext;

  BreedDetails({Key key, this.breed, this.extracontext}) : super(key: key);

  @override
  Widget build(BuildContext context)
  {
    if (breed.id == 4126750000){
      return Column(
        children: [
          Container(
            height: 100,
            alignment: Alignment.center,
            child: Card(
              margin: EdgeInsets.only(
                top: 12,
                left: 20,
                right: 20,
              ),
              elevation: 15,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.error_outline),
                    title: Text(
                      ":("
                    ),
                    subtitle: Text(
                      "Oooops, It seems that this breed does not exists.",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    List<Widget> flavourChildren = [];
    List<Widget> positiveChildren = [];
    List<Widget> negativeChildren = [];
    List<Widget> medicalChildren = [];

    for (String s in breed.f.f)
    {
      flavourChildren.add(
        Card(
          elevation: 0,
          margin: EdgeInsets.only(
            top: 10,
            bottom: 10
          ),
          child: Title(
            color: Colors.grey,
            child: Text(
              s
            ),
          ),
        ),
      );
    }
    if (flavourChildren.isEmpty)
    {
      flavourChildren.add(
        Card(
          elevation: 0,
          margin: EdgeInsets.only(
            top: 10,
            bottom: 10
          ),
          child: Title(
            color: Colors.grey,
            child: Text(
              "None"
            ),
          ),
        ),
      );
    }

    
    for (String s in breed.e.positive)
    {
      positiveChildren.add(
        Card(
          elevation: 0,
          margin: EdgeInsets.only(
            top: 10,
            bottom: 10
          ),
          child: Title(
            color: Colors.grey,
            child: Text(
              s
            ),
          ),
        ),
      );
    }
    if (positiveChildren.isEmpty)
    {
      positiveChildren.add(
        Card(
          elevation: 0,
          margin: EdgeInsets.only(
            top: 10,
            bottom: 10
          ),
          child: Title(
            color: Colors.grey,
            child: Text(
              "None"
            ),
          ),
        ),
      );
    }

    
    for (String s in breed.e.negative)
    {
      negativeChildren.add(
        Card(
          elevation: 0,
          margin: EdgeInsets.only(
            top: 10,
            bottom: 10
          ),
          child: Title(
            color: Colors.grey,
            child: Text(
              s
            ),
          ),
        ),
      );
    }
    if (negativeChildren.isEmpty)
    {
      negativeChildren.add(
        Card(
          elevation: 0,
          margin: EdgeInsets.only(
            top: 10,
            bottom: 10
          ),
          child: Title(
            color: Colors.grey,
            child: Text(
              "None"
            ),
          ),
        ),
      );
    }

    
    for (String s in breed.e.medical)
    {
      medicalChildren.add(
        Card(
          elevation: 0,
          margin: EdgeInsets.only(
            top: 10,
            bottom: 10
          ),
          child: Title(
            color: Colors.grey,
            child: Text(
              s
            ),
          ),
        ),
      );
    }
    if (medicalChildren.isEmpty)
    {
      medicalChildren.add(
        Card(
          elevation: 0,
          margin: EdgeInsets.only(
            top: 10,
            bottom: 10
          ),
          child: Title(
            color: Colors.grey,
            child: Text(
              "None"
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child:ListView(
                  children: [
                    Card(
                      elevation: 2,
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.dry_outlined
                            ),
                            title: Text(
                              "Flavors"
                            ),
                          ),
                          Container(
                            width: 500,
                            child: Card(
                              margin: EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 12,
                              ),
                              elevation: 15,
                              child: Column(
                                children: flavourChildren,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Card(
                      elevation: 2,
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.download_done_outlined
                            ),
                            title: Text(
                              "Positive effects"
                            ),
                          ),
                          Container(
                            width: 500,
                            child: Card(
                              margin: EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 12,
                              ),
                              elevation: 15,
                              child: Column(
                                children: positiveChildren,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Card(
                      elevation: 2,
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.healing_outlined
                            ),
                            title: Text(
                              "Medicinal effects"
                            ),
                          ),
                          Container(
                            width: 500,
                            child: Card(
                              margin: EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 12,
                              ),
                              elevation: 15,
                              child: Column(
                                children: medicalChildren,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Card(
                      elevation: 2,
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.warning_sharp
                            ),
                            title: Text(
                              "Negative effects"
                            ),
                          ),
                          Container(
                            width: 500,
                            child: Card(
                              margin: EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 12,
                              ),
                              elevation: 15,
                              child: Column(
                                children: negativeChildren,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.black12,
                height: 150,
                alignment: Alignment.bottomCenter,
                padding: EdgeInsets.only(
                    right: 20.0,
                    left: 20.0
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        breed.name,
                      ),
                    ),
                    Container(
                      height: 100.0,
                      width: MediaQuery.of(context).size.width,
                      child: Card(
                        color: Colors.green[900],
                        elevation: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center ,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.ios_share,
                              ), 
                              onPressed: (){
                                Share.share('H');
                              }
                            ),
                            Container(
                              padding: EdgeInsets.only(
                                right: MediaQuery.of(context).size.width * .10,
                                left: MediaQuery.of(context).size.width * .10,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                              ), 
                              onPressed: (){
                                extracontext._updateField(extracontext._input, 0, "");
                              }
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),  
      ],
    );
  }
}

class BreedList extends StatelessWidget {
  final List<WeedBreed> breeds;
  final _MyHomePageState extracontext;

  BreedList({Key key, this.breeds, this.extracontext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> resultCards = [];

    for (WeedBreed b in breeds) {
      if (resultCards.length > 25)
        break;

      if (b.name == null)
        b.name = " ";

      if (b.id == null)
        b.id = 4126750000;

      if (b.desc == null)
        b.desc = " ";

      resultCards.add(
        InkWell(
          onTap: ()
          {
            extracontext._updateField(extracontext._input, b.id, b.name);
          },
          child: Container(
            alignment: Alignment.center,
            child: Card(
              margin: EdgeInsets.only(
                top: 12,
                left: 20,
                right: 20,
              ),
              elevation: 15,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.eco_outlined),
                    title: Text(
                      b.name + " ",
                    ),
                    subtitle: Text(
                      b.desc + " ",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (resultCards.isEmpty)
      return NoBreedsFoundCard(
        extracontext: extracontext,
      );

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: resultCards,
    );
  }
}

class NoBreedsFoundCard extends StatelessWidget {
  final _MyHomePageState extracontext;

  NoBreedsFoundCard({Key key, this.extracontext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 100,
          alignment: Alignment.center,
          child: Card(
            margin: EdgeInsets.only(
              top: 12,
              left: 20,
              right: 20,
            ),
            elevation: 15,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Icon((extracontext._input == "") ? Icons.help_outline : Icons.error_outline ),
                  title: Text(
                    (extracontext._input == "") ? "Hey" : ":(",
                  ),
                  subtitle: Text(
                    (extracontext._input == "") ? "Try searching for a breed you already know." : "Could't find anything with \"" + extracontext._input + "\".",
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
