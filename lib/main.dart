import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_datastore/amplify_datastore.dart';

import 'amplifyconfiguration.dart';
import 'models/ModelProvider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  Future<void> _configureAmplify() async {
    final datastorePlugin =
    AmplifyDataStore(modelProvider: ModelProvider.instance);
    await Amplify.addPlugin(datastorePlugin);

    try {
      await Amplify.configure(amplifyconfig);
    } on AmplifyAlreadyConfiguredException {
      safePrint(
          'Tried to reconfigure Amplify; this can occur when your app restarts on Android.');
    }

    setState(() {
      _isLoading = false; // important to set the state!
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amplify Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : const DisplayTodoWidget(),
    );
  }
}

class DisplayTodoWidget extends StatefulWidget {
  const DisplayTodoWidget({super.key});

  @override
  State<DisplayTodoWidget> createState() => _DisplayTodoWidgetState();
}

class _DisplayTodoWidgetState extends State<DisplayTodoWidget> {
  List<Todo> _todos = [];

  @override
  void initState() {
    super.initState();
    _fetchTodos();
  }

  _fetchTodos() async {
    try {
      var response = await Amplify.DataStore.query(Todo.classType);
      setState(() {
        _todos = response;
      });
    } catch (e) {
      debugPrint('Error fetching todos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Amplify Example'),
      ),
      body: ListView.builder(
        itemCount: _todos.length,
        itemBuilder: (context, index) {
          final todo = _todos[index];
          return ListTile(
            title: Text(todo.name),
            subtitle: Text(todo.description ?? 'No description'),
            trailing: Checkbox(
              value: todo.completed,
              onChanged: (bool? value) {
                _updateTodoCompletion(todo, value ?? false);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTodoWidget()));
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _updateTodoCompletion(Todo todo, bool completed) async {
    final updateTodo = todo.copyWith(completed: completed);
    await Amplify.DataStore.save(updateTodo);
    _fetchTodos();
  }
}

class AddTodoWidget extends StatefulWidget {
  const AddTodoWidget({super.key});

  @override
  State<AddTodoWidget> createState() => _AddTodoWidgetState();
}

class _AddTodoWidgetState extends State<AddTodoWidget> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _description;

  _addTodo() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState?.save();

      try {
        final item = Todo(
            name: _name,
            description: _description,
            completed: false,
            dueDate: null);
        await Amplify.DataStore.save(item);

        debugPrint('Todo should be created');

        _formKey.currentState?.reset();
      } catch (e) {
        debugPrint('Error creating todo: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Todo"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (value) => _description = value!,
              ),
              ElevatedButton(
                onPressed: _addTodo,
                child: const Text('Add Todo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
