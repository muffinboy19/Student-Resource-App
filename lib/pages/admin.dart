import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../components/custom_loader.dart';
import 'package:studentresourceapp/pages/subjects_admin.dart';

class Admin extends StatefulWidget {
  final String uid;

  const Admin({required this.uid});

  @override
  _AdminState createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  bool canManageModerators = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkModeratorManageAccess();
  }

  Future<void> checkModeratorManageAccess() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> result =
      await FirebaseFirestore.instance.collection('admins').get();

      final List<DocumentSnapshot<Map<String, dynamic>>> documents =
          result.docs;

      final adminData = documents.firstWhere(
            (doc) => doc.id == widget.uid,
        orElse: () => null,
      );

      if (adminData != null &&
          adminData.data().containsKey('canManageModerators') &&
          adminData.data()['canManageModerators'] == true) {
        setState(() {
          canManageModerators = true;
        });
      }
    } catch (error) {
      print('Error retrieving admin data: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin'),
      ),
      body: isLoading
          ? CustomLoader() // Assuming CustomLoader is a widget showing a loading indicator
          : StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('admins')
            .doc(widget.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            try {
              List<dynamic> subjectAssigned = snapshot.data!
                  .data()?['subjects_assigned'] ?? [];

              List<Widget> listMaterials = subjectAssigned
                  .map(
                    (element) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(element.toString()),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) =>
                                SubjectsAdmin(
                                  subjectCode: element.toString(),
                                  canManageModerators:
                                  canManageModerators,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              )
                  .toList();

              listMaterials.add(SizedBox(height: 100));
              return ListView(
                children: listMaterials,
              );
            } catch (error) {
              print('Error building subject list: $error');
              return Center(child: Text('Error building subject list'));
            }
          } else if (snapshot.hasError) {
            print('Snapshot error: ${snapshot.error}');
            return Center(child: Text('Snapshot error'));
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
    );
  }
}
