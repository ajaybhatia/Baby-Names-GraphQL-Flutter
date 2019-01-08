import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

// GraphQL Client
ValueNotifier<Client> client = ValueNotifier(
  Client(
    cache: InMemoryCache(),
    endPoint: 'https://bnames.herokuapp.com/graphql'
  ),
);

// GraphQL Queries
String babiesQuery = """
  query Babies {
    babies {
      name
      votes
    }
  }
""".replaceAll('\n', ' ');

// GraphQL Mutations
String upVoteMutation = """
  mutation UpVote(\$name: String!) {
    upVote(name: \$name) {
      name
      votes
    }
  }
""".replaceAll('\n', ' ');

String createBabyMutation = """
  mutation CreateBaby(\$name: String!) {
    createBaby(babyInfo: {
      name: \$name,
      votes: 0
    }) {
      name
      votes
    }
  }
""".replaceAll('\n', ' ');

String removeBabyMutation = """
  mutation RemoveBaby(\$name: String!) {
    remove(name: \$name) {
      name
      votes
    }
  }
""".replaceAll('\n', ' ');

// main method
void main() => runApp(MyApp());

// MyApp
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baby Names',
      debugShowCheckedModeBanner: false,
      home: MyHome(),
    );
  }
}

// MyHome - Scaffold
class MyHome extends StatelessWidget {
  TextEditingController babyNameController = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Baby Names'),
        actions: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                showModalBottomSheet(context: context, builder: (BuildContext context) {
                  return GraphqlProvider(
                    client: client,
                    child: Container(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            TextField(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'New Baby Name',
                              ),
                              controller: babyNameController,
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: Mutation(
                                createBabyMutation,
                                builder: (
                                  runCreateBabyMutation, {
                                    bool loading,
                                    var data,
                                    Exception error,
                                  }) {
                                    return RaisedButton(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          Icon(Icons.add,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8.0,),
                                          Text('Save',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      color: Colors.blue,
                                      onPressed: () {
                                        var babyName = babyNameController.text;
                                        if (babyName != '') {
                                          runCreateBabyMutation({
                                            'name': babyName
                                          });
                                        }
                                        Navigator.pop(context);
                                      },
                                    );
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    ),
                  );
                });
              },
            ),
          ),
        ],
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    return GraphqlProvider(
      client: client,
      child: Query(babiesQuery,
        pollInterval: 1,
        builder: ({
          bool loading,
          var data,
          Exception error,
        }) {
          if (error != null) {
            return Text(error.toString());
          }

          if (loading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          List babies = data['babies'];

          return Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: ListView.builder(
              itemCount: babies.length,
              itemBuilder: (context, index) {
                final baby = Baby.fromMap(babies[index]);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1.0,
                        color: Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Mutation(
                        removeBabyMutation,
                      builder: (
                        runRemoveBabyMutation, { // you can name it whatever you like
                          bool loading,
                          var data,
                          Exception error,
                        }) {
                          return Mutation(
                            upVoteMutation,
                            builder: (
                              runUpVoteMutation, { // you can name it whatever you like
                                bool loading,
                                var data,
                                Exception error,
                              }) {
                              return ListTile(
                                leading: Text(baby.name),
                                trailing: Text(baby.votes.toString()),
                                onTap: () => runUpVoteMutation({
                                  'name': baby.name,
                                }),
                                onLongPress: () => runRemoveBabyMutation({
                                  'name': baby.name
                                }),
                              );
                          });
                    }),
                  ),
                );
              }
            ),
          );
        },
      ),
    );
  }
}

// Baby Model
class Baby {
  final String name;
  final int votes;

  Baby.fromMap(Map<String, dynamic> map)
      : assert(map['name'] != null),
        assert(map['votes'] != null),
        name = map['name'],
        votes = map['votes'];
}