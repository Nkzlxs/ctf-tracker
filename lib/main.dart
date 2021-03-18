import "package:flutter/material.dart";

import "package:pull_to_refresh/pull_to_refresh.dart";
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import 'package:path/path.dart';
import "package:sqflite/sqflite.dart";


Future<Database> the_database;

void main() async{

	// Avoid errors caused by flutter upgrade.
	// Importing 'package:flutter/widgets.dart' is required.
	WidgetsFlutterBinding.ensureInitialized();

    // deleteDatabase(
    //     join(await getDatabasesPath(),"ctf_database.db")
    // );

	// Open the database and store the reference.
	final Future<Database> database = openDatabase(
		// Set the path to the database. Note: Using the `join` function from the
		// `path` package is best practice to ensure the path is correctly
		// constructed for each platform.
		join(await getDatabasesPath(), 'ctf_database.db'),

		onCreate: (db,version){
			print("onCreating");
			db.execute(
				"CREATE TABLE ctfEvents(id INTEGER PRIMARY KEY AUTOINCREMENT, eventName TEXT, startTime TEXT, endTime TEXT, challengeLength INTEGER)",
			);
            db.execute(
                "CREATE TABLE eventChallenges(id INTEGER PRIMARY KEY AUTOINCREMENT, eventName TEXT, challengeName TEXT, category Text, challengeStartTime TEXT, challengeEndTime TEXT, isStarted INTEGER, isPaused INTEGER, isSolved INTEGER, timeUsedInSeconds INTEGER)",
            );
            return db;
		},

		version: 1,
	);
	the_database = database;
	
    
	
    runApp(MainPage());
}

class MainPage extends StatefulWidget {
    @override
    _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: "CTF Tracker",
            theme: ThemeData(
                primaryColor: Colors.cyan,
            ),

            // home: RandomWords(),
            initialRoute: CTFEvents.routeName,
            routes: {
                // RandomWords.routeName: (context) => RandomWords(),
                CTFEvents.routeName : (context) => CTFEvents(),
                ChallengesList.routeName : (context) => ChallengesList(),
                ChallengeTimer.routeName: (context) => ChallengeTimer()
            }
        );
    }
}

class CTFEventObject{
	String _ctfName;
	DateTime _startTime;
	DateTime _endTime;
	bool _isEnded = false;

	List<ChallengeObject> challenges = [];

	CTFEventObject();

	String get ctfName => this._ctfName;
	set ctfName(String value){
		this._ctfName = value;
	}
	DateTime get startTime => this._startTime;
	DateTime get endTime => this._endTime;

	bool get isEnded => this._isEnded;

	void setStartEndTime(DateTime start, DateTime end){
		this._startTime = start;
		this._endTime = end;
	}

	CTFEventObject eventStatus(){
		CTFEventObject tmp = new CTFEventObject();
		tmp._ctfName = this.ctfName;
		tmp._startTime = this._startTime;
		tmp._endTime = this._endTime;
		tmp._isEnded = DateTime.now().isAfter(this._endTime);
		tmp.challenges = this.challenges;

		return tmp;
	}
}

class CTFEventForm extends StatelessWidget{

	final _listPadding = EdgeInsets.all(32.0);

	final _formKey = GlobalKey<FormState>();

	// https://flutter.dev/docs/cookbook/forms/retrieve-input#1-create-a-texteditingcontroller
	final myController = TextEditingController();
	CTFEventObject event_obj = new CTFEventObject();

	@override
	Widget build(BuildContext context){

		return Scaffold(
			appBar: AppBar(
				title: Text("Add an event")
			),
			body: Form(
				key: _formKey,
				child: ListView(
					padding: _listPadding,
					children: <Widget>[
						TextFormField(
							decoration: const InputDecoration(
								hintText: 'Event Name',
							),
							validator: (value) {
								if (value.isEmpty) {
									return 'Please enter an event name';
								}
								return null;
							},
							controller: myController,
						),
						_datePicker(),
						Padding(
							padding: const EdgeInsets.symmetric(vertical: 16.0),
							child: ElevatedButton(
								onPressed: () {
									// Validate will return true if the form is valid, or false if
									// the form is invalid.
									
									if (_formKey.currentState.validate()) {

										event_obj.ctfName = myController.text;

										print("SUBBIMGING BUTN");
										print(event_obj.ctfName);
										print(event_obj.startTime);

										Navigator.pop(context,event_obj);
									}
								},
								child: Text('Submit'),
							),
						),
					],
				),
			)
		);
	}

	Widget _datePicker(){
		return SfDateRangePicker(
			view: DateRangePickerView.month,
			onSelectionChanged: _onSelectionChanged,
			selectionMode: DateRangePickerSelectionMode.range,
		);
	}

	void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
		// https://help.syncfusion.com/flutter/daterangepicker/callbacks
		if (args.value is PickerDateRange) {
			final DateTime rangeStartDate = args.value.startDate;
			final DateTime rangeEndDate = args.value.endDate;

			event_obj.setStartEndTime(rangeStartDate, rangeEndDate);
        } else if (args.value is DateTime) {
			final DateTime selectedDate = args.value;
        } else if (args.value is List<DateTime>) {
			final List<DateTime> selectedDates = args.value;
        } else {
			final List<PickerDateRange> selectedRanges = args.value;
        }

	}
}

class CTFEvents extends StatefulWidget{
	static const routeName = "ctfEvents";

    @override
    _CTFEventsState createState() => _CTFEventsState();
}

class _CTFEventsState extends State<CTFEvents>{


	final _listPadding = EdgeInsets.all(16.0);

	BuildContext myContext;

	Future<List<CTFEventTable>> databaseCTFEvents;
    List<CTFEventTable> storedCTFEvents = [];
	List<CTFEventObject> displayCTFEvents = [];


    @override
    void initState() {
        super.initState();
        print("am i called before building?");

        this.readDatabase();
    }

    RefreshController _refreshController = RefreshController(initialRefresh: false);

	void _onRefresh() async{
		// monitor network fetch
		await Future.delayed(Duration(milliseconds: 300));
		// if failed,use refreshFailed()

		setState(() {

		});

		_refreshController.refreshCompleted();
	}

	void _onLoading() async{
		// monitor network fetch
		await Future.delayed(Duration(milliseconds: 300));
		// if failed,use loadFailed(),if no data return,use LoadNodata()
	
		_refreshController.loadComplete();
	}

    Future<void> readDatabase() async{
        databaseCTFEvents = getCTFEvents();
        databaseCTFEvents
        .then(
            (List<CTFEventTable> tmp){
                storedCTFEvents.clear();
                for(var event in tmp){
                    storedCTFEvents.add(event);
                    print("reading database");
                    print(event.eventName);
                }
            }
        )
        // https://stackoverflow.com/questions/22082073/chaining-dart-futures-possible-to-access-intermediate-results
        .then(
            (nothing){
                print("Stored CTF Events length: " + storedCTFEvents.length.toString());
                if(storedCTFEvents.length > 0){
                    this.displayCTFEvents.clear();
                    for(var i in storedCTFEvents){
                        CTFEventObject event_obj = CTFEventObject();
                        event_obj._ctfName = i.eventName;
                        event_obj._startTime = DateTime.parse(i.startTime);
                        event_obj._endTime = DateTime.parse(i.endTime);


                        /*
                            get all challenges by the name of the event
                        */

                        Future<List<CTFChallengeTable>> allEventChallenges = getChallenges(i.eventName);
                        allEventChallenges.then(
                            (List<CTFChallengeTable> allStoredChallenge){
                                for(var storedChallenge in allStoredChallenge){
                                    ChallengeObject chall_obj = ChallengeObject(storedChallenge.category, storedChallenge.challengeName);

                                    chall_obj._isSolved = (storedChallenge.isSolved==1?true:false);
                                    chall_obj._isStarted = (storedChallenge.isStarted==1?true:false);
                                    chall_obj._isPaused = (storedChallenge.isPaused==1?true:false);
                                    chall_obj._timeUsed = Duration(seconds:storedChallenge.timeUsedInSeconds);

                                    if(chall_obj.isSolved){
                                        print("hello");
                                        chall_obj._solveTime = DateTime.parse(storedChallenge.challengeEndTime);
                                        // dddd._timeUsed = DateTime.parse(ddd.challengeEndTime).difference(DateTime.parse(ddd.challengeStartTime));
                                    }
                                    if(chall_obj.isStarted){
                                        chall_obj._startTime = DateTime.parse(storedChallenge.challengeStartTime);
                                    }


                                    event_obj.challenges.add(chall_obj);
                                }
                            }
                        ).then(
                            (nothing) => this.displayCTFEvents.add(event_obj)
                        );
                    }
                }
            }
        );
    }

	@override
	Widget build(BuildContext context){
        print("yes you're called before building");

		this.myContext = context;

		return Scaffold(
			appBar: AppBar(
				title: Text("CTF Tracker"),
				actions: [
                    IconButton(
                        icon: Icon(Icons.save),
                        onPressed: (){
                            _saveCurrentEvents();
                        }
                    ),
					IconButton(
						icon: Icon(Icons.add), 
						onPressed: (){
							_createCTFEvent(context);
						}
					),
				],
			),
			body: _buildEvents()
		);
	}


	Widget _buildEvents(){
		// No Ctf Events recorded
		if(this.displayCTFEvents.isEmpty){	
            return SmartRefresher(
				controller: _refreshController,
				enablePullDown: true,
				enablePullUp: false,
				header: BezierCircleHeader(),
				onRefresh: _onRefresh,
				onLoading: _onLoading,
				child: Center(child: Text("There is no event!"))
			);
		}
		else{
            // this.parseStoredEvents();
            return SmartRefresher(
				controller: _refreshController,
				enablePullDown: true,
				enablePullUp: false,
				header: BezierCircleHeader(),
				onRefresh: _onRefresh,
				onLoading: _onLoading,
				child: _buildRow()
			);
		}

	}

	/*
		ListTiles magic
		https://flutter.dev/docs/get-started/codelab#step-4-create-an-infinite-scrolling-listview
        + customization
	*/
	Widget _buildRow(){
		final tiles = displayCTFEvents.map(
			(CTFEventObject eventObj){
				CTFEventObject tmp = eventObj.eventStatus();
				if(tmp.isEnded){
					return Card(
                        child: ListTile(
                            title: Text(tmp.ctfName),
                            subtitle: Text("Ended at: "+tmp.endTime.toString()),
                            isThreeLine: false,
                            leading: Icon(Icons.stop_circle_outlined),


                            onTap: (){
                                Navigator.pushNamed(
                                    this.myContext,
                                    ChallengesList.routeName,
                                    arguments: ChallengesListArguments(tmp.ctfName, tmp.challenges)
                                );
                            },
                        ),
                        color: Colors.grey,
                    );
				}else{
					return Card( 
                        child: ListTile(
                            title: Text(tmp.ctfName),
                            subtitle: Text("Start: "+tmp.startTime.toString()+"\n"+"End: "+tmp.endTime.toString()),
                            isThreeLine: true,
                            leading: Icon(Icons.run_circle),


                            onTap: (){
                                Navigator.pushNamed(
                                    this.myContext,
                                    ChallengesList.routeName,
                                    arguments: ChallengesListArguments(tmp.ctfName, tmp.challenges)
                                );
                            },
                        )
                    );
				}
			}
				
		);
		return ListView(
			padding: _listPadding,
			children: tiles.toList(),
		);
	}

	/* 
		Get the form inputs, update the state
		https://flutter.dev/docs/cookbook/navigation/returning-data
	*/
	_createCTFEvent(BuildContext context) async{
		final result = await Navigator.push(
			context,
			MaterialPageRoute(builder: (context) => CTFEventForm()) 
		);
		if (result != null){
			// Update the state of the context?
			setState(() {
				displayCTFEvents.add(result);
			});
		}
	}

    _saveCurrentEvents() async{

        deleteAllCTFEvent()
        .then((wat)=>deleteAllChallenges())
        .then((wat){
            /*
                insert all event
            */
            for(var i in displayCTFEvents){
                CTFEventObject a = i.eventStatus();
                CTFEventTable tmp = CTFEventTable(
                    id:                   null,
                    eventName:            a.ctfName,
                    startTime:            a.startTime.toIso8601String(),
                    endTime:              a.endTime.toIso8601String(),
                    challengeLength:      a.challenges.length,
                  
                );
       
                insertCTFEvent(tmp);

                /*
                    insert all challenges
                */
                for(var chall in i.challenges){
                    CTFChallengeTable tmp_chall = CTFChallengeTable(
                        id:                     null,
                        eventName:              i._ctfName,
                        challengeName:          chall.challengeName,
                        category:               chall.category,
                        challengeStartTime:     (chall.startTime==null?null:chall.startTime.toIso8601String()),
                        challengeEndTime:       (chall._solveTime==null?null:chall._solveTime.toIso8601String()),
                        isStarted:              chall.isStarted==true?1:0,
                        isPaused:               chall.isPaused==true?1:0,
                        isSolved:               chall.isSolved==true?1:0,
                        timeUsedInSeconds:      chall.timeUsed.inSeconds,
                    );
                    insertChallenge(tmp_chall);
                }
            }
        }
        ).then((wat){
            ScaffoldMessenger.of(this.myContext)
                ..removeCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text("Saved successfully")));
            }  
        );
    }
}




class ChallengeObject{
	String category;
	String challengeName;
	bool _isStarted = false;
	bool _isPaused = false;
	bool _isEnded = false;
	bool _isSolved = false;
	DateTime _startTime;
	DateTime _solveTime;
	Duration _timeUsed = Duration();


	ChallengeObject(this.category,this.challengeName);

	bool get isStarted => this._isStarted;
	set isStarted(bool value){
		this._isStarted = value;
		this._startTime = DateTime.now();
	}

	bool get isPaused => this._isPaused;
	set isPaused(bool value){
		this._isPaused = value;
        this._timeUsed += DateTime.now().difference(this._startTime);
	}
	void resume(){
		this._isStarted = true;
		this._isPaused = false;
        this._startTime = DateTime.now();
	}

	bool get isEnded => this._isEnded;
	set isEnded(bool value){
		this._isEnded = value;
	}

	bool get isSolved => this._isSolved;
	bool setSolved(){
		if(this._isStarted && !this._isPaused && !this._isEnded && !this._isSolved){
			this._isSolved = true;
			this._solveTime = DateTime.now();
			this._timeUsed += this._solveTime.difference(this._startTime);
            return true;
		}
		// print(this.isStarted);
		// print(this._isPaused);
		// print(this.isEnded);
		// print(this.isSolved);
		print("can't change to solved");
        return false;
	}

	DateTime get startTime => this._startTime;
	Duration get timeUsed => this._timeUsed;

	String challengeStatusDisplay(){

		if(!this._isStarted && !this.isPaused)
			return "Not Started";
		if(this.isStarted && this.isPaused)
			return "Challenge Paused";
		if(this.isStarted && !this.isPaused && !this.isSolved){

            int tU = DateTime.now().difference(this._startTime).inSeconds + this.timeUsed.inSeconds;
            int tU_hr = tU ~/ 3600;
            int tU_m = (tU % 3600) ~/ 60;
            int tU_s = (tU % 3600) % 60;
			return "Ongoing: " + tU_hr.toString() + " hr " + tU_m.toString() + " m " + tU_s.toString() + " s";
        }
		if(this.isSolved){
            int tU = this.timeUsed.inSeconds;
            int tU_hr = tU ~/ 3600;
            int tU_m = (tU % 3600) ~/ 60;
            int tU_s = (tU % 3600) % 60;
			return "Time Used: " + tU_hr.toString() + " hr " + tU_m.toString() + " m " + tU_s.toString() + " s";
        }
		if(this._isEnded)
			return "Challenge Ended";
		return "Something glitched";
	}
}

class ChallengeForm extends StatelessWidget{

	final _paddingList = EdgeInsets.all(32.0);

	final _formKey = GlobalKey<FormState>();
	final categoryController = TextEditingController();
	final challengeNameController = TextEditingController();

	@override
	Widget build(BuildContext context){
		return Scaffold(
			appBar: AppBar(
				title: Text("Add a challenge")
			),
			body: Form(
				key: _formKey,
				child: ListView(
					padding: _paddingList,
					children: <Widget>[
						TextFormField(
							decoration: const InputDecoration(
								hintText: 'Category',
							),
							validator: (value) {
								if (value.isEmpty) {
									return 'Please choose a category';
								}
								return null;
							},
							controller: categoryController,
						),
						TextFormField(
							decoration: const InputDecoration(
								hintText: 'Challenge Name',
							),
							validator: (value) {
								if (value.isEmpty) {
									return 'Please enter challenge name';
								}
								return null;
							},
							controller: challengeNameController,
						),
						Padding(
							padding: const EdgeInsets.symmetric(vertical: 16.0),
							child: ElevatedButton(
								onPressed: () {
									// Validate will return true if the form is valid, or false if
									// the form is invalid.
									if (_formKey.currentState.validate()) {
										ChallengeObject tmp = new ChallengeObject(categoryController.text,challengeNameController.text);
										Navigator.pop(context,tmp);
									}
								},
								child: Text('Submit'),
							),
						),
					],
				),
			)
		);
	}
}

class ChallengesListArguments{
	String ctfName;
	List<ChallengeObject> attemptedChallenges;
	
	ChallengesListArguments(this.ctfName,this.attemptedChallenges);
}

class ChallengesList extends StatefulWidget {
	static const routeName = "/challengesList";

	@override
	_ChallengesListState createState() => _ChallengesListState();
}

class _ChallengesListState extends State<ChallengesList> {

	final _challengeNameText = TextStyle(fontSize: 24.0);
	final _categoryText = TextStyle(fontSize: 18.0);
	final _listPadding = EdgeInsets.all(32.0);

	ChallengesListArguments args;
	List<ChallengeObject> challenges = [];

	BuildContext myContext;

	@override
	Widget build(BuildContext context) {

		this.myContext = context;

		args = ModalRoute.of(context).settings.arguments;
		challenges = args.attemptedChallenges;

		return Scaffold(
			appBar: AppBar(
				title:Text(args.ctfName),
				actions: [
					IconButton(
						icon: Icon(Icons.add), 
						onPressed: (){
							_addChallenge(context);
						}
					)
				],
			),
			body: _buildChallengesList()
		);
	}

	Widget _buildChallengesList(){
		if(challenges.isEmpty){
			return Center(child:Text("No challenges added"));
		}else{
			return SmartRefresher(
				controller: _refreshController,
				enablePullDown: true,
				enablePullUp: false,
				header: BezierCircleHeader(),
				onRefresh: _onRefresh,
				onLoading: _onLoading,
				child: _buildRow()
			);
			// return _buildRow();
		}
	}

	Widget _buildRow(){
		var tiles = challenges.map(
			(ChallengeObject chall_obj){

                var trailingIcon = (){
                    if(chall_obj.isEnded){
                        return Icon(Icons.stop_circle_outlined);
                    }
                    if(chall_obj.isSolved){
                        return Icon(Icons.done_outline);
                    }
                    if(chall_obj.isPaused){
                        return Icon(Icons.pause_circle_outline);
                    }
                    if(chall_obj.isStarted){
                        return Icon(Icons.run_circle);
                    }else{
                        return Icon(Icons.play_arrow_rounded);
                    }  
                };
                var cardColor = (){
                    if(chall_obj.isEnded){
                        return Colors.grey;
                    }
                    if(chall_obj.isSolved){
                        return Colors.lightGreenAccent.shade100;
                    }
                    if(chall_obj.isPaused){
                        return Colors.amber.shade300;
                    }
                    if(chall_obj.isStarted){
                        return Colors.white;
                    }else{
                        return Colors.red;
                    }  
                };

                return Card(
                    child: ListTile(
                        title: Text(chall_obj.challengeName,style: _challengeNameText,),
                        subtitle: Text(
                            chall_obj.category+
                            "\n"+
                            chall_obj.challengeStatusDisplay(),
                            style: _categoryText,
                        ),
                        isThreeLine: true,
                        trailing: trailingIcon(),

                        onTap: (){
                            Navigator.pushNamed(
                                this.myContext, 
                                ChallengeTimer.routeName,
                                arguments: ChallengeTimerArguments(chall_obj)
                            );
                        },
                    ),
                    color: cardColor(),
                );
			}
		);

		return ListView(
			padding: _listPadding,
			children: tiles.toList()
		);

	}

	_addChallenge(BuildContext context) async{
		var result = await Navigator.push(
			context,
			MaterialPageRoute(builder: (context) => ChallengeForm()) 
		);

		if (result != null){
			// Update the state of the context?
			setState(() {
				challenges.add(result);
			});
		}
	}


	RefreshController _refreshController = RefreshController(initialRefresh: false);

	void _onRefresh() async{
		// monitor network fetch
		await Future.delayed(Duration(milliseconds: 300));
		// if failed,use refreshFailed()

		setState(() {

		});

		_refreshController.refreshCompleted();
	}

	void _onLoading() async{
		// monitor network fetch
		await Future.delayed(Duration(milliseconds: 300));
		// if failed,use loadFailed(),if no data return,use LoadNodata()
	
		_refreshController.loadComplete();
	}

}




class ChallengeTimerArguments{
	ChallengeObject challenge;
	ChallengeTimerArguments(this.challenge);
}

class ChallengeTimer extends StatefulWidget {

	static const routeName = "/challengeTimer";

	@override
	_ChallengeTimerState createState() => _ChallengeTimerState();
}

class _ChallengeTimerState extends State<ChallengeTimer>{

    BuildContext myContext;

	final _fontChallengeName = TextStyle(fontSize: 32.0);
	final _fontCategory = TextStyle(fontSize: 24.0,color: Colors.black45);
    final _fontStatus = TextStyle(fontSize: 24.0, color: Colors.black);
	final _listPadding = EdgeInsets.all(32.0);

	ChallengeTimerArguments args;
	ChallengeObject chall_obj;

	@override
	Widget build(BuildContext context){

        this.myContext = context;

		//  This method returns the current route with the arguments
		args = ModalRoute.of(context).settings.arguments;
		chall_obj = args.challenge;


		return Scaffold(
			appBar: _buildAppBar(),
			body: _buildBody()
		);
	}

    Color getBGColor(){
        if(chall_obj.isSolved){
            return Colors.lightGreenAccent;
        }
        // Not started
        if(chall_obj.isStarted == false && chall_obj.isPaused == false){
            return Colors.red;
        }
        // Running
        else if(chall_obj.isStarted == true && chall_obj.isPaused == false){
            return Colors.cyan;
        }
        // Paused
        else if(chall_obj.isStarted == true && chall_obj.isPaused == true){
            return Colors.amber;
        }
    }

    Widget _buildAppBar(){
        return AppBar(
            title: Text("Challenge Timer"),
            backgroundColor: this.getBGColor()
        );
    }

	Widget _buildBody(){

		Card challengeName = Card(
			child: ListTile(
                title: Center(
                    child: Text(chall_obj.challengeName,style: _fontChallengeName)
                ),
            )
		);
		ListTile category = ListTile(
			title: Text(chall_obj.category,style: _fontCategory),
		);

		ListTile timeUsedTile = ListTile(
			title: Text(
				chall_obj.challengeStatusDisplay(),
				style: _fontStatus,
			)
		);
        ListTile buttonIcon = ListTile(
            title: Row(
                children:[
                    Expanded(child: _playPauseBtn()),
                    Expanded(child: _stopBtn()),
                ],
            )
        );
        List<Widget> d = [];
        if(chall_obj.isSolved)
            d = [challengeName,category,timeUsedTile];
        else
            d = [challengeName,category,timeUsedTile,buttonIcon];

        return SmartRefresher(
            controller: _refreshController,
            enablePullDown: true,
            header: BezierCircleHeader(bezierColor: this.getBGColor(),),
            onRefresh: _onRefresh,
            child: ListView(
                children: d,
                padding: _listPadding,
            )
        );
	}

    RefreshController _refreshController = RefreshController(initialRefresh: false);

	void _onRefresh() async{
		// monitor network fetch
		await Future.delayed(Duration(milliseconds: 300));
		// if failed,use refreshFailed()

		setState(() {

		});

		_refreshController.refreshCompleted();
	}

	void _startChallenge(){
		chall_obj.isStarted = true;
	}

	void _pauseChallenge(){
		chall_obj.isPaused = true;
	}

	void _resumeChallenge(){
		chall_obj.resume();
	}



	Widget _playPauseBtn(){
		// https://stackoverflow.com/questions/43334714/pass-a-typed-function-as-a-parameter-in-dart
		Function() onPressFunc;

		Widget buttonIcon;
		if(chall_obj.isStarted == false && chall_obj.isPaused == false){
			onPressFunc = _startChallenge;
			buttonIcon = Icon(
                Icons.play_arrow_rounded,
                color:Colors.redAccent,
            );
		}
		else if(chall_obj.isStarted == true && chall_obj.isPaused == false){
			onPressFunc = _pauseChallenge;
			buttonIcon = Icon(
                Icons.pause_circle_filled_outlined,
                color: Colors.amber,
            );	
		}
		else if(chall_obj.isStarted == true && chall_obj.isPaused == true){
			onPressFunc = _resumeChallenge;
			buttonIcon = Icon(
                Icons.play_arrow_rounded,
                color:Colors.lightGreenAccent,
            );
		}
		print(onPressFunc);
		print(chall_obj.isPaused);
		return IconButton(
			onPressed: (){
				setState((){
					onPressFunc();
				});
			},
			icon: buttonIcon,
            iconSize: 64.0,
			// style: ButtonStyle(backgroundColor: a),
		);
	}

	Widget _stopBtn(){
		return IconButton(
			onPressed: (){
				setState((){
					bool stat = chall_obj.setSolved();
                    if(!stat){
                         ScaffoldMessenger.of(this.myContext)
                            ..removeCurrentSnackBar()
                            ..showSnackBar(SnackBar(content: Text("Unable to end the challenge!")));
                    }
				});
			}, 
			icon: Icon(
                Icons.stop_circle_outlined,
                color: Colors.red,
            ),
            iconSize: 64.0,
			// style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.red)),
		);
	}
}



class CTFEventTable{

    final String        _tableName = "ctfEvents";

	final int 			id;
	final String 		eventName;
	final String 		startTime;
	final String 		endTime;
    final int           challengeLength;
	CTFEventTable(
		{
			this.id,
			this.eventName,
			this.startTime,
			this.endTime,
            this.challengeLength,
		}
	);

	// Convert a Dog into a Map. The keys must correspond to the names of the
	// columns in the database.
	Map<String, dynamic> toMap() {
		return {
			"id":					id,
			"eventName":			eventName,
			"startTime":			startTime,
			"endTime":				endTime,
            "challengeLength":      challengeLength,
		};
	}



}

// Define a function that inserts dogs into the database
Future<void> insertCTFEvent(CTFEventTable ctfEvent) async {
    // Get a reference to the database.
    final Database db = await the_database;
    // Insert the Dog into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same dog is inserted twice.
    //
    // In this case, replace any previous data.
    await db.insert(
        ctfEvent._tableName,
        ctfEvent.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("inserting 1");
}
// A method that retrieves all the dogs from the dogs table.
Future<List<CTFEventTable>> getCTFEvents() async {
    // Get a reference to the database.
    final Database db = await the_database;
    // Query the table for all The Dogs.
    final List<Map<String, dynamic>> maps = await db.query('ctfEvents');

    // Convert the List<Map<String, dynamic> into a List<Dog>.
    return List.generate(maps.length, (i) {
        return CTFEventTable(
            id: 					maps[i]["id"],
            eventName: 				maps[i]["eventName"],
            startTime: 				maps[i]["startTime"],
            endTime: 				maps[i]["endTime"],
            challengeLength:        maps[i]["challengeLength"],
            
        );
    });
}

Future<void> updateCTFEvent(CTFEventTable ctfEvent) async {
    // Get a reference to the database.
    final db = await the_database;

    // Update the given Dog.
    await db.update(
        ctfEvent._tableName,
        ctfEvent.toMap(),
        // Ensure that the Dog has a matching id.
        where: "id = ?",
        // Pass the Dog's id as a whereArg to prevent SQL injection.
        whereArgs: [ctfEvent.id],
    );
}
Future<void> deleteAllCTFEvent() async {
    // Get a reference to the database.
    final db = await the_database;

    // Remove the Dog from the Database.
    await db.delete(
        "ctfEvents"
    );
}



class CTFChallengeTable{

    final String        _tableName = "eventChallenges";

	final int 			id;
    final String        eventName;
	final String 		challengeName;
	final String 		category;
	final String 		challengeStartTime;
	final String 		challengeEndTime;
	final int 			isStarted;
	final int 			isPaused;
	final int 			isSolved;
    final int           timeUsedInSeconds;


	CTFChallengeTable(
		{
			this.id,
            this.eventName,
			this.challengeName,
			this.category,
			this.challengeStartTime,
			this.challengeEndTime,
			this.isStarted,
			this.isPaused,
			this.isSolved,
            this.timeUsedInSeconds
		}
	);

	// Convert a Dog into a Map. The keys must correspond to the names of the
	// columns in the database.
	Map<String, dynamic> toMap() {
		return {
			"id":					id,
            "eventName":            eventName,
			"challengeName":		challengeName,
			"category":				category,
			"challengeStartTime":	challengeStartTime,
			"challengeEndTime":		challengeEndTime,
			"isStarted":			isStarted,
			"isPaused":				isPaused,
			"isSolved":				isSolved,
            "timeUsedInSeconds":    timeUsedInSeconds,
		};
	}
}

Future<void> insertChallenge(CTFChallengeTable ctfChallenge) async {
    final Database db = await the_database;

    print("insert 2");
    await db.insert(
        ctfChallenge._tableName,
        ctfChallenge.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
    );
}

Future<List<CTFChallengeTable>> getChallenges(String eventName) async {
    final Database db = await the_database;

    final List<Map<String, dynamic>> maps = await db.query(
        "eventChallenges",
        where: "eventName = ?",
        whereArgs: [eventName],
        );

    return List.generate(maps.length, (i){
        return CTFChallengeTable(
            id:                     maps[i]["id"],
            eventName:              maps[i]["eventName"],    
            challengeName: 			maps[i]["challengeName"],
            category: 				maps[i]["category"],
            challengeStartTime: 	maps[i]["challengeStartTime"],
            challengeEndTime: 		maps[i]["challengeEndTime"],
            isStarted: 				maps[i]["isStarted"],
            isPaused: 				maps[i]["isPaused"],
            isSolved: 				maps[i]["isSolved"],
            timeUsedInSeconds:      maps[i]["timeUsedInSeconds"],
        );
    });
}

Future<void> deleteAllChallenges() async{
    final db = await the_database;
    await db.delete(
        "eventChallenges"
    );
}
