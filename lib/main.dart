import "package:flutter/material.dart";

import "package:pull_to_refresh/pull_to_refresh.dart";
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import 'package:path/path.dart';
import "package:sqflite/sqflite.dart";


Future<Database> the_database;

// Define a function that inserts dogs into the database
Future<void> insertCTFEvent(CTFEventTable ctfEventTable) async {
	// Get a reference to the database.
	final Database db = await the_database;
		// Insert the Dog into the correct table. You might also specify the
		// `conflictAlgorithm` to use in case the same dog is inserted twice.
		//
		// In this case, replace any previous data.
		await db.insert(
			'ctfEvents',
			ctfEventTable.toMap(),
			conflictAlgorithm: ConflictAlgorithm.replace,
		);
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
			challengeName: 			maps[i]["challengeName"],
			category: 				maps[i]["category"],
			challengeStartTime: 	maps[i]["challengeStartTime"],
			challengeEndTime: 		maps[i]["challengeEndTime"],
			isStarted: 				maps[i]["isStarted"],
			isPaused: 				maps[i]["isPaused"],
			isSolved: 				maps[i]["isSolved"],
		);
	});
}

Future<void> updateCTFEvent(CTFEventTable ctfEvent) async {
	// Get a reference to the database.
	final db = await the_database;

	// Update the given Dog.
	await db.update(
		'ctfEvents',
		ctfEvent.toMap(),
		// Ensure that the Dog has a matching id.
		where: "id = ?",
		// Pass the Dog's id as a whereArg to prevent SQL injection.
		whereArgs: [ctfEvent.id],
	);
}
Future<void> deleteCTFEvent(int id) async {
	// Get a reference to the database.
	final db = await the_database;

	// Remove the Dog from the Database.
	await db.delete(
		'ctfEvents',
		// Use a `where` clause to delete a specific dog.
		where: "id = ?",
		// Pass the Dog's id as a whereArg to prevent SQL injection.
		whereArgs: [id],
	);
}




void main() async{

	// Avoid errors caused by flutter upgrade.
	// Importing 'package:flutter/widgets.dart' is required.
	WidgetsFlutterBinding.ensureInitialized();
	// Open the database and store the reference.
	final Future<Database> database = openDatabase(
		// Set the path to the database. Note: Using the `join` function from the
		// `path` package is best practice to ensure the path is correctly
		// constructed for each platform.
		join(await getDatabasesPath(), 'ctf_database.db'),

		onCreate: (db,version){
			print("onCreating");
			return db.execute(
				"CREATE TABLE ctfEvents(id INTEGER PRIMARY KEY, eventName TEXT, startTime TEXT, endTime TEXT, challengeName TEXT, category Text, challengeStartTime TEXT, challengeEndTime TEXT, isStarted INTEGER, isPaused INTEGER, isSolved INTEGER)",
			);
		},

		version: 1,
	);
	the_database = database;
	
	
    runApp(Home());
}

class Home extends StatelessWidget {
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

	final _listPadding = EdgeInsets.all(32.0);

	List<CTFEventObject> ctfEvents = [];
	BuildContext myContext;
	Future<List<CTFEventTable>> databaseCTFEvents;

	@override
	Widget build(BuildContext context){
		this.myContext = context;
		return Scaffold(
			appBar: AppBar(
				title: Text("CTF Tracker"),
				actions: [
					IconButton(
						icon: Icon(Icons.add), 
						onPressed: (){
							_createCTFEvent(context);
						}
					)
				],
			),
			body: _buildEvents()
		);
	}


	Widget _buildEvents(){
		// DatabaseController dbController = new DatabaseController();

		// this.databaseCTFEvents = dbController.getCTFEvents();

		databaseCTFEvents = getCTFEvents();
		for(int i = 0; i < 5; i ++){
			print("YO BITHCH");
		}
		print(await databaseCTFEvents);
		// No Ctf Events recorded
		if(ctfEvents.isEmpty){	
			return Center(child: Text("There is no event!"));
		}
		else{
			return _buildRow();
		}

	}

	/*
		ListTiles magic
		https://flutter.dev/docs/get-started/codelab#step-4-create-an-infinite-scrolling-listview
	*/
	Widget _buildRow(){
		final tiles = ctfEvents.map(
			(CTFEventObject eventObj){
				CTFEventObject tmp = eventObj.eventStatus();

				if(tmp.isEnded){
					return ListTile(
						title: Text(tmp.ctfName),
						subtitle: Text("Ended at: "+tmp.endTime.toString()),
						onTap: (){
							Navigator.pushNamed(
								this.myContext,
								ChallengesList.routeName,
								arguments: ChallengesListArguments(tmp.ctfName, tmp.challenges)
							);
						},
					);
				}else{
					return ListTile(
						title: Text(tmp.ctfName),
						subtitle: Text("Start: "+tmp.startTime.toString()+"\n"+"End: "+tmp.endTime.toString()),
						onTap: (){
							Navigator.pushNamed(
								this.myContext,
								ChallengesList.routeName,
								arguments: ChallengesListArguments(tmp.ctfName, tmp.challenges)
							);
						},
					);
				}
			}
				
		);
		final divided_tiles = ListTile.divideTiles(
			context: this.myContext,
			tiles: tiles,
			color: Colors.lime
		).toList();

		return ListView(
			padding: _listPadding,
			children: divided_tiles,
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
		// print(result.ctfName);
		if (result != null){
			// Update the state of the context?
			setState(() {
				ctfEvents.add(result);
			});
		}
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
	Duration _timeUsed;

	ChallengeObject(this.category,this.challengeName);

	bool get isStarted => this._isStarted;
	set isStarted(bool value){
		this._isStarted = value;
		this._startTime = DateTime.now();
	}

	bool get isPaused => this._isPaused;
	set isPaused(bool value){
		this._isPaused = value;
	}
	void resume(){
		this._isStarted = true;
		this._isPaused = false;
	}

	bool get isEnded => this._isEnded;
	set isEnded(bool value){
		this._isEnded = value;
	}

	bool get isSolved => this._isSolved;
	void solved(){
		if(this._isStarted && !this._isPaused && !this._isEnded && !this._isSolved){
			this._isSolved = true;
			this._solveTime = DateTime.now();
			this._timeUsed = this._solveTime.difference(this._startTime);
		}
		// print(this.isStarted);
		// print(this._isPaused);
		// print(this.isEnded);
		// print(this.isSolved);
		print("can't change to solved");
	}

	DateTime get startTime => this._startTime;
	Duration get timeUsed => this._timeUsed;

	String challengeStatus(){
		if(!this._isStarted && !this.isPaused)
			return "Not Started";
		if(this.isStarted && this.isPaused)
			return "Challenge Paused";
		if(this.isStarted && !this.isPaused && !this.isSolved)
			return "Ongoing: " + DateTime.now().difference(this._startTime).inMinutes.toString() + " minutes";
		if(this.isSolved)
			return "Time Used: " + this.timeUsed.inMinutes.toString() + " minutes";
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
				return ListTile(
					title: Text(chall_obj.challengeName,style: _challengeNameText,),
					subtitle: Text(
						chall_obj.category+
						"\n"+
						chall_obj.challengeStatus(),
						style: _categoryText,
					),
					onTap: (){
						Navigator.pushNamed(
							this.myContext, 
							ChallengeTimer.routeName,
							arguments: ChallengeTimerArguments(chall_obj)
						);
					},
				);
			}
		);

		var divided = ListTile.divideTiles(
			context: this.myContext,
			tiles: tiles,
			color: Colors.deepPurpleAccent
		).toList();


		return ListView(
			padding: _listPadding,
			children: divided
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

	final _fontHeading = TextStyle(fontSize: 32.0);
	final _fontDescription = TextStyle(fontSize: 24.0);
	final _listPadding = EdgeInsets.all(32.0);

	ChallengeTimerArguments args;
	ChallengeObject chall_obj;

	@override
	Widget build(BuildContext context){

		//  This method returns the current route with the arguments
		args = ModalRoute.of(context).settings.arguments;
		chall_obj = args.challenge;

		return Scaffold(
			appBar: AppBar(title: Text("Challenge Timer")),
			body: _buildChallenge()
		);
	}

	Widget _buildChallenge(){

		ListTile category = ListTile(
			title: Text(chall_obj.category,style: _fontHeading),
		);
		ListTile challengeName = ListTile(
			title: Text(chall_obj.challengeName,style: _fontHeading),
		);

		ListTile timeUsedTile = ListTile(
			title: Text(
				chall_obj.challengeStatus(),
				style: _fontDescription,
			)
		);
		ListTile buttonIcon = ListTile(
			title: Row(
				children:[
					_playPauseBtn(),
					_stopBtn()
				],
			)
		);

		return ListView(
			children: [
				category,challengeName,timeUsedTile,buttonIcon
			],
			padding: _listPadding,
		);
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
		MaterialStateProperty a;
		if(chall_obj.isStarted == false && chall_obj.isPaused == false){
			onPressFunc = _startChallenge;
			buttonIcon = Icon(Icons.play_arrow);
			a = MaterialStateProperty.all<Color>(Colors.redAccent);
		}
		else if(chall_obj.isStarted == true && chall_obj.isPaused == false){
			onPressFunc = _pauseChallenge;
			buttonIcon = Icon(Icons.pause);	
			a = MaterialStateProperty.all<Color>(Colors.cyan);
		}
		else if(chall_obj.isStarted == true && chall_obj.isPaused == true){
			onPressFunc = _resumeChallenge;
			buttonIcon = Icon(Icons.play_arrow,);
			a = MaterialStateProperty.all<Color>(Colors.yellow);
		}
		print(onPressFunc);
		print(chall_obj.isPaused);
		return ElevatedButton(
			onPressed: (){
				setState((){
					onPressFunc();
				});
			},
			child: buttonIcon,
			style: ButtonStyle(backgroundColor: a),
		);
	}

	Widget _stopBtn(){
		return ElevatedButton(
			onPressed: (){
				setState((){
					chall_obj.solved();
				});
			}, 
			child: Icon(Icons.stop),
			style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.red)),
		);
	}
}



class CTFEventTable{
	final int 			id;
	final String 		eventName;
	final String 		startTime;
	final String 		endTime;
	final String 		challengeName;
	final String 		category;
	final String 		challengeStartTime;
	final String 		challengeEndTime;
	final int 			isStarted;
	final int 			isPaused;
	final int 			isSolved;

	CTFEventTable(
		{
			this.id,
			this.eventName,
			this.startTime,
			this.endTime,
			this.challengeName,
			this.category,
			this.challengeStartTime,
			this.challengeEndTime,
			this.isStarted,
			this.isPaused,
			this.isSolved
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
			"challengeName":		challengeName,
			"category":				category,
			"challengeStartTime":	challengeStartTime,
			"challengeEndTime":		challengeEndTime,
			"isStarted":			isStarted,
			"isPaused":				isPaused,
			"isSolved":				isSolved,
		};
	}
}
