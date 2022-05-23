import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

//final imgUrl = "https://imageslabo.com/wp-content/uploads/2019/07/1114_water_hamon_9514.jpg";
//final imgUrl = "https://cdn.paperm.jp/image/freeillust/xmas_198.png";
final imgUrl = "https://imageslabo.com/wp-content/uploads/2019/05/288_shinryoku_sky_6715.jpg";
//final  REPETITIONTIME = 499;//何回ダウンロードするか
final   T= 120;//何秒ダウンロードするか

var dio = Dio();

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // MaterialAppで画面のテーマ等を設定できる.(GoogleのUIっぽいデザインを返す)
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'スループット計測アプリ'),
    );
  }
}

// StatefulWidgetを継承したクラス
class MyHomePage extends StatefulWidget {
  // コンストラクト
  MyHomePage({Key key, this.title}) : super(key: key);
  // 定数定義
  final String title;

  // アロー関数を用いて、MyHomePageStateを呼ぶ
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

// Widgetから呼ばれるStateクラス
class _MyHomePageState extends State<MyHomePage> { //_MyHomePageメソッド
  //変数定義
  final double fileSize=4.92*8;//(MByteをMbitに変換)
  int _timeMsec = 0; //Requestにかかった時間を格納
  double _timeSec=0;
  double Mbps=0;
  double throughput=0;
  final myController = TextEditingController(); // 入力された内容をこのコントローラを使用して取り出します。
  var formattedDate = "none"; //string型に変更した時間
  var formattedDate1 = "none"; //string型に変更した時間
  var formattedDate2 = "none"; //string型に変更した時間
  Stopwatch s=Stopwatch();//時間の計測を行う
  var dataset={}; //時間(s)と帯域(Mbps)を保存する関数
  int firstTime=0;

  // メソッドの定義
  void getPermission() async {
    print("getPermission");
    Map<PermissionGroup, PermissionStatus> permissions =
    await PermissionHandler().requestPermissions([PermissionGroup.storage]);
  }

  @override
  void initState() {
    getPermission();
    super.initState();
  }

  //DatetimeをStringが変換する関数
  formatTimeGet(time){
    formattedDate = DateFormat('yyyy-MM-dd-kk:mm:ss:SSS').format(time);//String型に変換
    return formattedDate;
  }

  //urlにアクセスしダウンロードを行う関数
  Future download2(Dio dio, String url) async {
    DateTime timeBeforeReq = new DateTime.now();//ダウンロード前の時間取得
    formattedDate1 = formatTimeGet(timeBeforeReq);//String型に変換
    //urlにアクセスしダウンロード開始
    try {
      await dio.get(
        url,
      );
    } catch (e) {
      print(e);
    }
    DateTime timeAfterRes = new DateTime.now();//ダウンロード後の時間取得
    formattedDate2 = formatTimeGet(timeAfterRes);//String型に変換
    int sinceEpochBeforeReq = timeBeforeReq.millisecondsSinceEpoch; //mmsecondに変換
    int sinceEpochAfterRes = timeAfterRes.millisecondsSinceEpoch; //mmsecondに変換
    _timeMsec = sinceEpochAfterRes - sinceEpochBeforeReq; //ダウンロードにかかった時間の代入(ms)
    _timeSec=_timeMsec/1000;//msをsに変換
    Mbps=fileSize/_timeSec;//throughputを求める(Mbps)
    Mbps=((Mbps*1000).floor())/1000;//(小数点3桁まで表示)
    setState(() {  // おそらく画面の更新のため、setStateでフィールドを変更する必要がある
      throughput=Mbps;
    }
    );
  }

  //タイムスタンプを起動する関数
  // ignore: non_constant_identifier_names
  void start_stopwatch(){
    s.start();//計測開始
  }

   // 経過時間を取得する関数
   nowTime(){
           return (s.elapsedMilliseconds);
  }

  //繰り返しダウンロードを行う関数
   repetition() async{
     print('1回目');
     start_stopwatch();
     await download2(dio,imgUrl);
     print('0');
     firstTime=nowTime();
     dataset[0.00]='$throughput';
     for (int i = 0; i < 100000; i++) {
         int j = 0;
         int k = i + 2;
         print('$k回目');
         await download2(dio, imgUrl);
         j = (nowTime() - firstTime);
         double x = j / 1000;
         print(x);
         if(x>T){
           s.stop();//ストップウォッチを停止する
           s.reset();
           break;
         }
         dataset[x] = '$throughput';
       }
   }//ストップウォッチをリセット

  //取得したデータを表示する関数
  void indicateData() {
  dataset.forEach((key, value) {
  print('$key   $value');
   }
  );
}

//収集したデータをダウンロードディレクトリにファイルを生成しデータを書き込み保存する関数(emulator用)
  /*void saveData(txtName) async{
    String path = await ExtStorage.getExternalStoragePublicDirectory(ExtStorage.DIRECTORY_DOCUMENTS);
    String fullPath = "$path/$txtName";
    File file = File(fullPath);
    var raf = file.openSync(mode: FileMode.write);
    dataset.forEach((key, value) {
      raf.writeStringSync("$key   $value\n");
     }
    );
    await raf.close();
  }*/

  Future<void>  makeTxt(myFile) async{
    //ログファイル作成
    final logDirectory = await getApplicationDocumentsDirectory();
    String logPath = '${logDirectory.path}/$myFile';
    File textFilePath = File(logPath);
    print('$logPath');
    //await textFilePath.writeAsString('test');
    var raf = textFilePath.openSync(mode: FileMode.write);
    dataset.forEach((key, value) {
       raf.writeStringSync("$key   $value\n");
     }
    );
  }

  void makeDataset() async{
    for(int i = 1; i <7; i++) {
      await repetition();
      await makeTxt("my_car_4G$i.txt");
      dataset={};
    }
  }

  // デザインWidget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(

          mainAxisAlignment: MainAxisAlignment.center, //Columnの主軸方向にコンテンツを配置する
          children: <Widget>[
            //ダウンロード開始ボタン表示
            RaisedButton.icon(
                onPressed: () async {
                  // 押したら反応するコードを書く
                  dataset={};
                  //repetition();//download2メソッドを繰り返し実行
                  makeDataset();
                },
                icon: Icon(
                  Icons.file_download,
                  color: Colors.white,
                ),
                color: Colors.green,
                textColor: Colors.white,
                label: Text('測定開始')),


            //スループット表示
            Text(
              'throughput is  below.',
            ),
            Text(
              '$throughput(Mbps)',
              style: Theme.of(context).textTheme.display1,
            ),
            TextField(
              controller: myController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "保存するファイル名を入力",
                hintText: "my_home.txt",
              ),
            ),

            RaisedButton(
              child: Text('データを保存'),
              onPressed: () {
                // 押したら反応するコードを書く
                indicateData();//データをターミナルに表示
                //saveData(myController.text);
                makeTxt(myController.text);
              },
            ),
          ],
        ),
      ),
    );
  }
}
