import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(),
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
    return parsed.map<WeedBreed>((json) => WeedBreed.fromJson(json)).toList();
  }

  Future<List<WeedBreed>> _getInfoFromSearchResult(String input, http.Client client) async {
    if (input == "")
      return [];

    final response = await client.get('https://strainapi.evanbusse.com/3idwVwu/strains/search/name/' + input);
    return parseResult(response.body);
  }

  //get info ID BASED
  Effects parseResultNlEffects(String responseBody) {
    final e = json.decode(responseBody);
    print (e);
    return Effects.fromJson(e);
  }

  Flavors parseResultNlFlavors(String responseBody) {
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 20,
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Buscar',
                ),
                onChanged: (text) {
                  _updateField(text, 0, "");
                },
              ),
            ),
            Center(
              
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
          ],
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
    List<Widget> flavourChildren = [];
    List<Widget> positiveChildren = [];
    List<Widget> negativeChildren = [];
    List<Widget> medicalChildren = [];

    for (String s in breed.f.f)
    {
      flavourChildren.add(
        Text(
          s
        ),
      );
    }

    
    for (String s in breed.e.positive)
    {
      positiveChildren.add(
        Text(
          s
        ),
      );
    }

    
    for (String s in breed.e.negative)
    {
      negativeChildren.add(
        Text(
          s
        ),
      );
    }

    
    for (String s in breed.e.medical)
    {
      medicalChildren.add(
        Text(
          s
        ),
      );
    }

    return Expanded(
      child: InkWell(
        onTap: () {
          extracontext._updateField(extracontext._input, 0, "");
        }, 
        child: Column(
          children: [
            ListTile(
              title: Text(breed.name),
            ),
            Row(
              children: [
                Column(
                  children: [
                    Text("Flavors"),
                    Card(
                      child: Column(
                        children: flavourChildren,
                      ),
                    )
                  ],
                ),

                Column(
                  children: [
                    Text("Positive effects"),
                    Card(
                      child: Column(
                        children: positiveChildren,
                      ),
                    )
                  ],
                ),

                Column(
                  children: [
                    Text("Negative effects"),
                    Card(
                      child: Column(
                        children: negativeChildren,
                      ),
                    )
                  ],
                ),

                Column(
                  children: [
                    Text("Medicinal effects"),
                    Card(
                      child: Column(
                        children: medicalChildren,
                      ),
                    )
                  ],
                ),
              ],
            )
          ],
        ),
      ),  
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
      resultCards.add(
        InkWell(
          onTap: ()
          {
            extracontext._updateField(extracontext._input, b.id, b.name);
          },
          child: Container(
            height: 100,
            alignment: Alignment.center,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.eco_outlined),
                    title: Text(
                      b.name + " "
                    ),
                    subtitle: Text(
                      b.desc + " ",
                      style: TextStyle(color: Colors.black.withOpacity(0.6)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    resultCards.add(
      Container(
        height: 100,
        alignment: Alignment.center,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.eco_outlined),
                title: Text(
                  " That's the end of the list "
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Column(
      children: resultCards,
    );
  }
}
