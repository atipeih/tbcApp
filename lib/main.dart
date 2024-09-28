import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:charts_flutter/flutter.dart' as charts;

void main() {
  runApp(SmokingTrackerApp());
}

class SmokingTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smoking Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SmokingTrackerHomePage(),
    );
  }
}

class SmokingTrackerHomePage extends StatefulWidget {
  @override
  _SmokingTrackerHomePageState createState() => _SmokingTrackerHomePageState();
}

class _SmokingTrackerHomePageState extends State<SmokingTrackerHomePage> {
  int _count = 0;
  String _today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    _prefs = await SharedPreferences.getInstance();
    String? lastSavedDate = _prefs!.getString('last_saved_date');
    if (lastSavedDate != _today) {
      // 0時を過ぎたらリセット
      _prefs!.setString('last_saved_date', _today);
      _prefs!.setInt('count', 0);
    }
    setState(() {
      _count = _prefs!.getInt('count') ?? 0;
    });
  }

  Future<void> _incrementCount() async {
    setState(() {
      _count++;
    });
    _prefs!.setInt('count', _count);

    // 毎日の本数を保存
    List<String> smokingHistory = _prefs!.getStringList('smoking_history') ?? [];
    smokingHistory.add('$_today: $_count');
    _prefs!.setStringList('smoking_history', smokingHistory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('タバコ本数カウンター'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '今日のタバコの本数:',
              style: Theme.of(context).textTheme.headline6,
            ),
            Text(
              '$_count',
              style: Theme.of(context).textTheme.headline4,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _incrementCount,
              child: Text('タバコを吸った'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SmokingHistoryPage()),
                );
              },
              child: Text('履歴を確認する'),
            ),
          ],
        ),
      ),
    );
  }
}

class SmokingHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('喫煙履歴'),
      ),
      body: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          List<String> smokingHistory = snapshot.data!.getStringList('smoking_history') ?? [];
          return ListView.builder(
            itemCount: smokingHistory.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(smokingHistory[index]),
              );
            },
          );
        },
      ),
    );
  }
}

class SmokingChartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('喫煙グラフ'),
      ),
      body: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          List<String> smokingHistory = snapshot.data!.getStringList('smoking_history') ?? [];
          List<SmokingData> data = [];

          for (var entry in smokingHistory) {
            List<String> parts = entry.split(': ');
            String date = parts[0];
            int count = int.parse(parts[1]);
            data.add(SmokingData(date, count));
          }

          List<charts.Series<SmokingData, String>> series = [
            charts.Series(
              id: 'Smoking',
              data: data,
              domainFn: (SmokingData smoking, _) => smoking.date,
              measureFn: (SmokingData smoking, _) => smoking.count,
            )
          ];

          return charts.BarChart(
            series,
            animate: true,
          );
        },
      ),
    );
  }
}

class SmokingData {
  final String date;
  final int count;

  SmokingData(this.date, this.count);
}

