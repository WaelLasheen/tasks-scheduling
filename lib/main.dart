import 'package:flutter/material.dart';

import 'database/dataHelper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Remove the debug banner
        debugShowCheckedModeBanner: false,
        title: 'To Do',
        theme: ThemeData.dark(),
        home: const HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool taskDone = false;
  List<Map<String, dynamic>> tasks = [];

  bool isLoading = true;
  // This function is used to fetch all data from the database
  void refreshTasks() async {
    final data = await SQLHelper.getItems();
    setState(() {
      tasks = data;
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    refreshTasks(); // Loading the diary when the app starts
  }

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item
  void showTaskDetail(int? id) async {
    // id == null -> create new item
    // id != null -> update an existing item
    if (id != null) {
      final existingJournal =
      tasks.firstWhere((element) => element['id'] == id);
      titleController.text = existingJournal['title'];
      descriptionController.text = existingJournal['description'];
    }

    showModalBottomSheet(
        context: context,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) => Container(
          padding: EdgeInsets.only(
            top: 15,
            left: 15,
            right: 15,
            // this will prevent the soft keyboard from covering the text fields
            bottom: MediaQuery.of(context).viewInsets.bottom + 120,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'Title'),
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(hintText: 'Description'),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () async {
                  // Save new journal
                  if (id == null) {
                    await addItem();
                  }

                  if (id != null) {
                    await updateItem(id);
                  }

                  // Clear the text fields
                  titleController.text = '';
                  descriptionController.text = '';

                  // Close the bottom sheet
                  Navigator.of(context).pop();
                },
                child: Text(id == null ? 'Create New' : 'Update'),
              )
            ],
          ),
        ));
  }

// Insert a new journal to the database
  Future<void> addItem() async {
    await SQLHelper.createItem(
        titleController.text, descriptionController.text);
    refreshTasks();
  }

  // Update an existing journal
  Future<void> updateItem(int id) async {
    await SQLHelper.updateItem(
        id, titleController.text, descriptionController.text);
    refreshTasks();
  }

  // Delete an item
  void deleteItem(int id) async {
    await SQLHelper.deleteItem(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Successfully deleted a journal!'),
    ));
    refreshTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TASKS',style: TextStyle(fontSize: 28),),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.all(15),
          child: ListTile(
              title: Text(tasks[index]['title']),
              subtitle: Text(tasks[index]['description']),
              leading: Checkbox(value: taskDone, 
                  shape: const CircleBorder(),
                  fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.orange.withOpacity(.32);
                    }
                    return Colors.orange;
                  }),
                  onChanged: (_)=> deleteItem(tasks[index]['id'])
                ) ,
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => showTaskDetail(tasks[index]['id']),
              )
            ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add,size: 24 , color: Colors.white,),
        onPressed: () => showTaskDetail(null),
      ),
    );
  }
}
